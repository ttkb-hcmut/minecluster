defmodule Zm
	do
	def mkpath() do
		Utils.secretGen
	end

  def getCentralApi(group) do
    central = NodeGroup.getConfig(group)
    |> Map.get("central", nil)
    case central do
      %{"firebase" => a} -> {CentralInterface,a}
      _ -> {NodeCentral, nil}
    end
  end
  def zip(name) do
    tempPath = "./temp/#{name}-#{mkpath()}"
    fileName = "#{name}.zip"
    File.mkdir_p tempPath
    File.cp_r("./groups/#{name}", tempPath)
    files = File.ls!(tempPath) |> Enum.map(fn f -> String.to_charlist(f) end)
    {:ok,_} = :zip.create(
      "#{tempPath}/#{fileName}"|> String.to_charlist,
      files,
      cwd: "#{tempPath}" |> String.to_charlist
    )
    "#{tempPath}/#{fileName}"
  end

  def unzip(zipped,group) do
    # make sure the folder isn't used somehow
    :zip.unzip(~c"#{zipped}",[cwd: ~c"./groups/#{group}/"])
  end

  def post(group\\Agent.get(:group,& &1)) do
    if(not (group |> is_nil)) do
      file = zip(group)
      {central, centralData} = getCentralApi(group)
      central.post(file,centralData)
      File.rm_rf!(file |> Path.dirname)
      # send from temp folder to recipient
    end
    nil
  end

  def fetch(group\\Agent.get(:group,& &1)) do
    if(not (group |> is_nil)) do
      {central, centralData} = getCentralApi(group)
      case central.fetch(centralData) do
      nil ->
        Cli.warning("Fetching from central failed")
      file ->
        unzip(file,group)
        File.rm_rf!(file |> Path.dirname)
      end

      # download from address to temp
      # make sure nothing is using the destination folder somehow
      # unzip(name)
    end
  end
end

defmodule CentralInterface do
  def post(_,_) do
    Log.warning(nil,"Post api unimplemented")
    nil
  end
  def fetch(_) do
    Log.warning(nil,"Fetch api unimplemented")
    nil
  end
end

defmodule FirebaseCentral do
  def write(chunk,dest) do
    {:ok, file} = File.open(dest, [:append, :binary, :raw])
    IO.binwrite(file, [chunk])
    File.close(file)
  end
  def post(filePath,centralData) do
    case File.read(filePath) do
      {:ok,data} ->
        iv = :crypto.strong_rand_bytes(12)
        key = :crypto.hash(:md5,Agent.get(:group, & &1)) # 16 bytes
        {encrypted,tag} = :crypto.crypto_one_time_aead(
          :aes_128_gcm,key,iv,
          data,
          <<>>, true
        )

        Firebase1.set(iv<>tag<>encrypted,centralData)

      _ -> Log.error(nil, "Firebase Central errored")
    end
    nil
  end
  def fetch(centralData) do
    centralFileName = "archive.zip"
    tempPath = "./temp/#{Agent.get(:group, & &1)}-#{Zm.mkpath}/#{centralFileName}"

    key = :crypto.hash(:md5,Agent.get(:group, & &1)) # 16 bytes
    <<iv::binary-12, tag::binary-16, encrypted::binary>> = Firebase1.get(centralData)
    case :crypto.crypto_one_time_aead(
          :aes_128_gcm,key,iv,
          encrypted,
          tag, <<>>, false
    ) do
      :error ->
        Log.error(nil, "Decrypt file failed")
      data ->
        data
        |> write(tempPath)
    end
    tempPath
  end
end

defmodule NodeCentral do
  def centralStart() do
    case Agent.get(:group, & &1) do
      nil ->
        Cli.error "How the hell did you reach this error message?!?"
        NodeGroup.setRole(:online)
        nil
      g ->
        # NodeGroup.getConfig(g)
        # |> Map.put("central", %{node: (Node.self |> Atom.to_string) })
        # |> NodeGroup.setConfig(g)
        if not File.exists?("./central/#{g}") do
          Zm.post(g)
        end
        nil
    end
  end
  def getCentralNode() do
    self = Node.self()
    list = [self|Node.list()]
    |> Utils.inParallel(fn ele ->
      :erpc.call(ele, fn ->
        { ele,
          Agent.get(:role, & &1) == :central
        } end)
    end)
    |> IO.inspect
    |> Enum.filter(fn {_,v} -> v end)
    if (list |> length == 0) do
      nil
    else
      [{central,true}|_] = list
      central
    end
  end
  def write(chunk,dest) do
    {:ok, file} = File.open(dest, [:append, :binary, :raw])
    IO.binwrite(file, [chunk])
    File.close(file)
  end

  def transmit(sendTo,src,dest) do
    chunk_size = 65_536 # 65 thousand bytes blocks
    :erpc.call(sendTo,File,:mkdir_p!,[dest |> Path.dirname])
    File.stream!(src,chunk_size)
    |> Stream.each(fn chunk ->
      :erpc.call(sendTo, NodeCentral, :write, [chunk,dest])
    end)
    |> Stream.run()
  end
  def post(srcFile,_centralData\\nil) do
    case NodeCentral.getCentralNode() do
    nil -> nil
      Log.warning(nil,"No central node found")
    central ->
      centralFileName = "#{:erpc.call(central, fn -> Agent.get(:group, & &1) end)}.zip"
      filePath = "./central/#{centralFileName}"
      transmit(central,srcFile,filePath)
    end
    nil
  end

  def fetch(_centralData\\nil) do
    case NodeCentral.getCentralNode() do
    nil -> nil
      Log.warning(nil,"No central node found")
      nil
    central ->
      centralFileName = "#{:erpc.call(central, fn -> Agent.get(:group, & &1) end)}.zip"
      filePath = "./central/#{centralFileName}"
      tempPath = "./temp/#{Agent.get(:group, & &1)}-#{Zm.mkpath}/#{centralFileName}"
      :erpc.call(central,NodeCentral,:transmit,[Node.self(),filePath,tempPath])
      tempPath
    end
  end
end

defmodule Zm
	do
	def mkpath() do
		now = DateTime.now!("Etc/UTC") |> DateTime.to_string
		:crypto.hash(:sha256, now) |> Base.encode16
	end

  def getCentralApi(group) do
    central = Naas.getGroupInfo(group)
    |> Map.get("central", %{})
    central
    |> Map.keys
    |> then(fn x ->
      {
        case x do
          ["node"|_] -> NodeCentral
          ["firebase"|_] -> Cli.error("firebase api not implemented")
            CentralInterface
          _ -> CentralInterface
        end,
        central |> Map.get(x)
      }
    end)
  end
  def zip(name) do
    tempPath = "./temp/#{name}-#{mkpath()}"
    fileName = "#{name}.zip"
    File.mkdir_p tempPath
    File.cp_r("./groups/#{name}", tempPath)
    files = File.ls!("./groups/#{name}") |> Enum.map(fn f -> String.to_charlist(f) end)
    {:ok,_} = :zip.create(
      "#{tempPath}/#{fileName}"|> String.to_charlist,
      files,
      cwd: "./groups/#{name}" |> String.to_charlist
    )
    "#{tempPath}/#{fileName}"
  end

  def unzip(zipped,group) do
    # make sure the folder isn't used somehow
    :zip.unzip(zipped |> String.to_charlist, "./groups/#{group}" |> String.to_charlist)
  end

  def post(group\\Agent.get(:group,& &1)) do
    if(not (group |> is_nil)) do
      file = zip(group)
      {central, _} = getCentralApi(group)
      central.post(file)
      File.rm_rf!(file |> Path.dirname)
      # send from temp folder to recipient
    end
    nil
  end

  def fetch(group\\Agent.get(:group,& &1)) do
    if(not (group |> is_nil)) do
      {central, _} = getCentralApi(group)
      case central.fetch() do
      nil ->
        Cli.error("fetching from central failed")
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
  def post(_) do
    Cli.error("post api unimplemented")
    nil
  end
  def fetch() do
    Cli.error("fetch api unimplemented")
    nil
  end
end

defmodule NodeCentral do
  def centralStart() do
    case Agent.get(:group, & &1) do
      nil ->
        Cli.error "how the hell did you reach this error message?!?"
        Naas.setRole(:online)
        nil
      g ->
        Naas.getGroupInfo(g)
        |> Map.put("central", %{node: (Node.self |> Atom.to_string) })
        |> Naas.setGroupInfo(g)
        if not File.exists?("./central/#{g}") do
          Zm.post(g)
        end
        nil
    end
  end
  def getCentralNode() do
    self = Node.self()
    list = [self|Node.list()]
    |> List.foldl([], fn ele, acc ->
      [Task.async(fn ->
        :erpc.call(ele, fn -> {ele, Agent.get(:role, & &1) == :central} end)
      end)|acc]
    end)
    |> Task.yield_many(on_timeout: :kill_task, timeout: 1000)
    |> Enum.map(fn {task, res} -> res || Task.shutdown(task, :brutal_kill) end)
    |> List.foldl([], fn {_,res},acc -> [res|acc]end)
    |> Enum.filter(fn {_,v} -> v end)

    if (list |> length == 0) do
      nil
    else
      [{central,true}|_] = list
      central
    end
  end
  def write(dest,chunk) do
    {:ok, file} = File.open(dest, [:append, :binary, :raw])
    IO.binwrite(file, [chunk])
    File.close(file)
  end

  def transmit(sendTo,src,dest) do
    chunk_size = 65_536 # 65 thousand bytes blocks
    :erpc.call(sendTo,File,:mkdir_p!,[dest |> Path.dirname])
    File.stream!(src,chunk_size)
    |> Stream.each(fn chunk ->
      :erpc.call(sendTo, NodeCentral, :write, [dest, chunk])
    end)
    |> Stream.run()
  end
  def post(srcFile) do
    case getCentralNode() do
    nil ->
      Cli.error("no central node found")
    central ->
      centralFileName = "#{:erpc.call(central, fn -> Agent.get(:group, & &1) end)}.zip"
      filePath = "./central/#{centralFileName}"
      transmit(central,srcFile,filePath)
    end
    nil
  end
  def fetch() do
    case getCentralNode() do
    nil ->
      Cli.error("no central node found")
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

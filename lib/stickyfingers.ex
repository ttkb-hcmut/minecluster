defmodule Zm
	do
	def mkpath() do
		Naas.secretGen
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
      {central, _} = getCentralApi(group)
      central.post(file)
      File.rm_rf!(file |> Path.dirname)
      # send from temp folder to recipient
    end
    nil
  end

  def fetch(group\\Agent.get(:group,& &1)) do
    if(not (group |> is_nil)) do
      {central, api} = getCentralApi(group)
      case central.fetch(api) do
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
  def fetch(_) do
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
    c = Naas.cookieIs
    list = [self|Node.list()]
    |> Naas.inParallel(fn ele ->
      :erpc.call(ele, fn ->
        { ele,
          Agent.get(:role, & &1) == :central
          and Naas.cookieIs c
        } end)
    end)
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
  def fetch(api\\nil) do
    central = case {getCentralNode(),api} do
    {nil,nil} ->
      nil
    {nil,_} ->
      c = Naas.cookieIs
      Naas.connectNode(api,c)
      api |> String.to_atom
    {c,_} ->
      c
    end

    case central do
    nil ->
      Cli.error("no central node found")
    _ ->
      centralFileName = "#{:erpc.call(central, fn -> Agent.get(:group, & &1) end)}.zip"
      filePath = "./central/#{centralFileName}"
      tempPath = "./temp/#{Agent.get(:group, & &1)}-#{Zm.mkpath}/#{centralFileName}"
      :erpc.call(central,NodeCentral,:transmit,[Node.self(),filePath,tempPath])
      tempPath
    end
  end
end

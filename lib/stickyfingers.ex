alias NodeCentral, as: CentralApi

defmodule Zm
	do
  def groupCheck() do
    case (Agent.get(:group, & &1)) do
      nil ->
        Cli.error("not in a group, please make or join a group")
        false
      _ ->
        true
    end
  end
	def mkpath() do
		now = DateTime.now!("Etc/UTC") |> DateTime.to_string
		:crypto.hash(:sha256, now) |> Base.encode16
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

  def unzip(zipped) do
    # make sure the folder isn't used somehow
    group = Agent.get(:group,& &1)
    :zip.unzip(zipped |> String.to_charlist, "./groups/#{group}" |> String.to_charlist)
  end

  def post() do
    if(groupCheck()) do
      file = zip(Agent.get(:group,& &1))
      CentralApi.post(file)
      File.rm(file |> Path.dirname)
      # send from temp folder to recipient
    end
  end

  def fetch() do
    if(groupCheck()) do
      case CentralApi.fetch() do
        nil ->
          Cli.error("fetching from central failed")
        file ->
          unzip(file)
          File.rm(file |> Path.dirname)
      end

      # download from address to temp
      # make sure nothing is using the destination folder somehow
      # unzip(name)
    end
  end
end

defmodule NodeCentral do
  def getCentralNode do
    self = Node.self()
    list = Node.list()
    |> List.foldl([], fn ele, acc ->
      [Task.async(fn ->
        if(self != ele) do
          :erpc.call(ele, fn -> {ele, Agent.get(:role, & &1) == :central} end)
        else
          {ele,false}
      end end)|acc]
    end)
    |> Task.yield_many(on_timeout: :kill_task, timeout: 1000)
    |> Enum.filter(fn {_,v} -> v end)

    if (list |> length == 0) do
      nil
    else
      [central|_] = list
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

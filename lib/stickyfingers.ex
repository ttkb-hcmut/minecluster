alias NodeCentral, as: CentralApi

defmodule Zm
	do

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
    {tempPath,fileName}
  end

  def unzip(zipped) do
    # make sure the folder isn't used somehow
    group = Agent.get(:group,& &1)
    :zip.unzip(zipped |> String.to_charlist, "./groups/#{group}" |> String.to_charlist)
  end

  def post() do
    {tempPath,fileName} = zip(Agent.get(:group,& &1))
    CentralApi.post("#{tempPath}/#{fileName}")
    File.rm(tempPath)
    # send from temp folder to recipient
  end

  def fetch() do
    {tempPath, fileName} = CentralApi.fetch()
    unzip("#{tempPath}/#{fileName}")
    File.rm(tempPath)
    # download from address to temp
    # make sure nothing is using the destination folder somehow
    # unzip(name)
  end

end

defmodule NodeCentral do

  def write_begin(dest) do
    {:ok, file} = File.open(dest, [:append, :binary, :raw])
    file
  end
  def write(file,chunk) do
    IO.binwrite(file, [chunk])
  end

  def write_end(file) do
    File.close(file)
  end

  def transmit(sendTo,src,dest,file) do
    chunk_size = 65_536 # 65 thousand bytes blocks
    :erpc.call(sendTo,File,:mkdir_p!,[dest])
    file = :erpc.call(sendTo, NodeCentral, :write_begin, [dest<>"/"<>file])
    File.stream!(src,chunk_size)
    |> Stream.each(fn chunk ->
        :erpc.call(sendTo, NodeCentral, :write, [file, chunk])
      end)
    |> Stream.run()
    :erpc.call(sendTo, NodeCentral, :write_end,[file])
  end
  def post(srcFile) do
    # dest = "./temp/#{src}-#{:crypto.hash(:sha256, DateTime.now!("Etc/UTC") |> DateTime.to_string) |> Base.encode16}"
    [central|_] = Node.list
    |> Enum.map(fn a -> {a,:erpc.call(a, fn -> Agent.get(:central, & &1) end)} end)
    |> Enum.filter(fn {_,v} -> v end)
    centralFileName = "#{:erpc.call(central, fn -> Agent.get(:group, & &1) end)}.zip"
    filePath = "./central/#{:erpc.call(central, fn -> Agent.get(:group, & &1) end)}"
    transmit(central,srcFile,filePath,centralFileName)
    nil
  end
  def fetch() do
    [central|_] = Node.list
    |> Enum.map(fn a -> {a,:erpc.call(a, fn -> Agent.get(:central, & &1) end)} end)
    |> Enum.filter(fn {_,v} -> v end)
    centralFileName = "#{:erpc.call(central, fn -> Agent.get(:group, & &1) end)}.zip"
    filePath = "./central/#{centralFileName}"
    tempPath = "./temp/#{Agent.get(:group, & &1)}-#{:crypto.hash(:sha256, DateTime.now!("Etc/UTC") |> DateTime.to_string) |> Base.encode16}"
    :erpc.call(central,NodeCentral,:transmit,[Node.self(),filePath,tempPath,".zip"])
    {tempPath,".zip"}
  end
end

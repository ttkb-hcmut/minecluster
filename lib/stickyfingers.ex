alias NodeCentral, as: CentralApi

defmodule Zm
	do

	def mkpath() do
		now = DateTime.now!("Etc/UTC") |> DateTime.to_string
		:crypto.hash(:sha256, now) |> Base.encode16
	end

  def zip(name) do
    tempPath = ".\\temp\\#{name}-#{mkpath()}"
    fileName = "#{name}.zip"
    File.mkdir_p tempPath
    File.cp_r(".\\groups\\#{name}", tempPath)
    files = File.ls!(".\\groups\\#{name}") |> Enum.map(String.to_charlist)
    {:ok,_} = :zip.create(
      "#{tempPath}\\#{fileName}"|> String.to_charlist,
      files,
      cwd: ".\\groups\\#{name}" |> String.to_charlist
    )
    {tempPath,fileName}
  end

  def unzip(zipped) do
    # make sure the folder isn't used somehow
    group = Agent.get(:group,& &1)
    :zip.unzip(zipped |> String.to_charlist, ".\\groups\\#{group}" |> String.to_charlist)
  end

  def post() do
    {tempPath,fileName} = zip(Agent.get(:group,& &1))
    CentralApi.post("#{tempPath}\\#{fileName}")
    File.rm(tempPath)
    # send from temp folder to recipient
  end

  def fetch() do
    {tempPath, fileName} = CentralApi.fetch()
    unzip("#{tempPath}\\#{fileName}")
    File.rm(tempPath)
    # download from address to temp
    # make sure nothing is using the destination folder somehow
    # unzip(name)
  end

  end

defmodule NodeCentral do
  def recieve(dest,source_stream) do
    # Ensure the directory exists on the remote node
    File.mkdir_p!(Path.dirname(dest))

    # Stream data into the remote file
    remote_file_stream = File.stream!(dest,[:write, :binary])
    IO.puts "before file transfer"
    Stream.into(source_stream, remote_file_stream) |> Stream.run
    IO.puts "after file transfer"
    :ok
  end
  def transmit(sendTo,src,dest) do
    # 1. Open the remote file for writing by spawning a process on Node 2
    local_stream = File.stream!(src, [], 64_000)
    IO.puts "before erpc"
    :ok = :erpc.call(sendTo, NodeCentral, :recieve, [dest,local_stream])
    IO.puts "after erpc"
  end
  def post(srcFile) do
    # dest = ".\\temp\\#{src}-#{:crypto.hash(:sha256, DateTime.now!("Etc/UTC") |> DateTime.to_string) |> Base.encode16}"
    [central|_] = Node.list
    |> Enum.map(fn a -> {a,:erpc.call(a, fn -> Agent.get(:central, & &1) end)} end)
    |> Enum.filter(fn {_,v} -> v end)
    filePath = ".\\central\\#{:erpc.call(central, fn -> Agent.get(:group, & &1) end)}"
    transmit(central,srcFile,filePath)
  end
  def fetch() do
    [central|_] = Node.list
    |> Enum.map(fn a -> {a,:erpc.call(a, fn -> Agent.get(:central, & &1) end)} end)
    |> Enum.filter(fn {_,v} -> v end)
    centralFileName = "#{:erpc.call(central, fn -> Agent.get(:group, & &1) end)}.zip"
    filePath = ".\\central\\#{centralFileName}"
    tempPath = ".\\temp\\#{Agent.get(:group, & &1)}-#{:crypto.hash(:sha256, DateTime.now!("Etc/UTC") |> DateTime.to_string) |> Base.encode16}"
    transmit(Node.self(),filePath,tempPath)
    {tempPath,centralFileName}
  end
end

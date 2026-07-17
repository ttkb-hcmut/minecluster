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
  # defp transmit(dest,pathsrc,pathdest) do
  #   # 1. Open the remote file for writing by spawning a process on Node 2
  #   remote_pid = Node.spawn(dest, fn ->
  #     # Ensure the directory exists on the remote node
  #     File.mkdir_p!(Path.dirname(pathdest))

  #     # Stream data into the remote file
  #     remote_file_stream = File.stream!(pathdest,[:write, :binary])

  #     receive do
  #       {:stream, source_stream} ->
  #         Enum.into(source_stream, remote_file_stream)
  #     end
  #     Zm.unzip(pathdest)
  #   end)

  #   # 2. Stream chunks of 64KB from the local file and send the stream reference
  #   local_stream = File.stream!(pathsrc, [], 64_000)
  #   Process.send(remote_pid, {:stream, local_stream},[])
  #   pathdest
  # end
  # def send(zipped, address) do
  #   src = Node.self() |> Atom.to_string
  #   dest = ".\\temp\\#{src}-#{:crypto.hash(:sha256, DateTime.now!("Etc/UTC") |> DateTime.to_string) |> Base.encode16}"
  #   pathdest = transmit(address,zipped,dest)
  #   pathdest
  # end
  # def fetch(address) do
  #   :erpc.call(address, Zm, :send, [Node.self()])
  # end
end

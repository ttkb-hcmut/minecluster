alias NodeCentral, as: CentralApi

defmodule Zm do
  def zip(name) do
    tempPath = ".\\temp\\#{name}-#{:crypto.hash(:sha256, DateTime.now!("Etc/UTC") |> DateTime.to_string) |> Base.encode16}"
    File.mkdir_p tempPath
    File.cp_r(".\\groups\\#{name}", tempPath)

    files = File.ls!(".\\groups\\#{name}") |> Enum.map(fn p -> String.to_charlist(p) end)
    {:ok,zipped} = :zip.create(
      "#{tempPath}\\#{name}.zip"|> String.to_charlist,
      files,
      cwd: ".\\groups\\#{name}" |> String.to_charlist
    )
    {tempPath,zipped |> List.to_string}
  end
  def unzip(zipped) do
    # make sure the folder isn't used somehow
    group = Agent.get(:group,& &1)
    :zip.unzip(zipped |> String.to_charlist, ".\\groups\\#{group}" |> String.to_charlist)
  end
  def send(recipient) do
    {tempPath,zipped} = zip(Agent.get(:group,& &1))
    dest = zipped |> CentralApi.send(recipient)
    File.rm(tempPath)
    dest
    # send from temp folder to recipient
  end
  def fetch(address) do
    CentralApi.fetch(address)
    # download from address to temp
    # make sure nothing is using the destination folder somehow
    # unzip(name)
  end
end

defmodule NodeCentral do
  defp transmit(dest,pathsrc,pathdest) do
    # 1. Open the remote file for writing by spawning a process on Node 2
    remote_pid = Node.spawn(dest, fn ->
      # Ensure the directory exists on the remote node
      File.mkdir_p!(Path.dirname(pathdest))

      # Stream data into the remote file
      remote_file_stream = File.stream!(pathdest,[:write, :binary])

      receive do
        {:stream, source_stream} ->
          Enum.into(source_stream, remote_file_stream)
      end
      Zm.unzip(pathdest)
    end)

    # 2. Stream chunks of 64KB from the local file and send the stream reference
    local_stream = File.stream!(pathsrc, [], 64_000)
    Process.send(remote_pid, {:stream, local_stream},[])
    pathdest
  end
  def send(zipped, address) do
    src = Node.self() |> Atom.to_string
    dest = ".\\temp\\#{src}-#{:crypto.hash(:sha256, DateTime.now!("Etc/UTC") |> DateTime.to_string) |> Base.encode16}"
    transmit(address,zipped,dest)
  end
  def fetch(address) do
    :erpc.call(address, Zm, :send, [Node.self()])
  end
end

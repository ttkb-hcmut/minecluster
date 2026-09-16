defmodule Wit do
  def start(serverPort \\ 4000,guiPort \\ 4001) do
    IO.puts("Elixir server listening on port #{serverPort}...")
    {:ok, gtsSocket} = :gen_tcp.listen(serverPort, [:binary, packet: :line, active: false, reuseaddr: true])
    Task.start_link(fn ->
      System.cmd(System.find_executable("py"),
        [
          "-u","./gui/tkinter/test.py",
          "--sport", "#{serverPort}",
          "--gport", "#{guiPort}",
        ])
      end)
    Process.spawn(fn -> Wit.listenServer(gtsSocket) end, [:link])
    Process.sleep(1000)
    {:ok, stgSocket} = :gen_tcp.connect(:localhost,guiPort, [:binary, packet: :line, active: false, reuseaddr: true])
    Agent.update(:push_server, fn _ -> Process.spawn(fn -> Wit.pushServer(stgSocket) end, [:link]) end)
  end
  def pushToGui (data \\ nil) do
    case Agent.get(:push_server, & &1) do
      nil -> nil
      a ->
        try do
          IO.inspect data
          Process.send(a,{
            :data,
            (data |> JSON.encode!)
          },[])
        rescue
          _ ->
            IO.puts "Push failed"
            nil
        end
    end
    nil
  end
  def pushServer(socket) do
    receive do
      {:data, data} ->
        Log.detail(nil, "sending data:#{data}")
        :ok = :gen_tcp.send(socket,data <> "\n")
        Wit.pushServer(socket)
      _ ->
        "Push failed" |> Cli.warning
        Wit.pushServer(socket)
    end
  end

  def listenServer(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    spawn(fn -> handleRequest(client) end)
    listenServer(socket)
  end
  def handleRequest(client) do
    case :gen_tcp.recv(client, 0) do
      {:ok, data} ->
        Log.detail(nil,data)
        try do
          case String.trim(data) |> JSON.decode! do
            %{"command" => list} ->
              if is_nil(Wit.runCommand(list)) do
                Log.detail(nil,"Executed command: #{list |> Enum.join(" ")}")
              else
                Log.error(nil,"Failed command: #{list |> Enum.join(" ")}")
              end
            %{"api" => request}->
              WitApi.get(request)
            _ ->
              Log.error(nil,"Unknown received from gui")
          end
        rescue
          _ ->
          %{"success" => false} |> JSON.encode!
        end
        handleRequest(client)
      {:error, :closed} ->
        IO.puts("GUI disconnected.")
    end
  end
  def runCommand(commandList \\ []) do
    Cli.tree_traverser({Cli.ctree(),commandList,[]},true,false)
  end
end
defmodule WitApi do
  def get(request) do
    case request do
      # get all configs
      "config/all" ->
        Log.new([Log.Info.new("configAll","",[Naas.getConfig(nil)])])

      # get self address and self cookie
      "self" ->
        Naas.getNodeSelf()

      # get all nodes connected
      "list" ->
        Naas.networkInfo(nil)

      # get all group info
      "group/list" ->
        Log.new |> Log.info("",[Naas.listGroup(:map)],"groupList")

      # get current group's information
      "group/status" ->
        Naas.groupStatus()

      # unknown
      _ ->
        nil

    end |> then(fn res -> case is_nil(res) or not is_struct(res,Log) do
      true->
        1
      false ->
        res |> Log.flush(true) |> Wit.pushToGui
        nil
    end end)
  end
end

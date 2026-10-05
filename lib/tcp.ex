defmodule Wit do
  def getFreePort do
    {:ok, socket} = :gen_tcp.listen(0, [:binary, active: false, reuseaddr: true])
    {:ok, port} = :inet.port(socket)
    :gen_tcp.close(socket)
    port
  end
  def start(serverPort \\ nil,guiPort \\ nil) do
    {serverPort,guiPort} = case {serverPort,guiPort} do
      {nil,nil} -> {getFreePort(),getFreePort()}
      {nil,g} -> {getFreePort(),g}
      {s,nil} -> {s,getFreePort()}
      {s,g} -> {s,g}
    end
    {:ok,gtsSocket} = :gen_tcp.listen(serverPort, [:binary, packet: :line, active: false, reuseaddr: true])
    IO.puts("Elixir server listening on port #{serverPort}")
    Task.start_link(fn ->
      System.cmd(System.find_executable("py"),
        [
          "-u","./gui/tkinter/app.py",
          "--sport", "#{serverPort}",
          "--gport", "#{guiPort}",
        ])
      end)
    Process.spawn(fn -> Wit.listenServer(gtsSocket) end, [:link])
    Process.sleep(1000)
    {:ok, stgSocket} = :gen_tcp.connect(:localhost,guiPort, [:binary, packet: :line, active: false, reuseaddr: true])
    IO.puts("Elixir server sending on port #{guiPort}...")
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
    case :gen_tcp.accept(socket) do
      {:ok, client} ->
        spawn(fn -> handleRequest(client,socket) end)
        listenServer(socket)
      {:error, :closed} ->
        Cli.detail("Closing GUI socket")
    end
  end

  def handleRequest(client,socket) do
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
        handleRequest(client,socket)
      {:error, :closed} ->
        IO.puts("GUI disconnected.")
        :ok = :gen_tcp.close(socket)
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

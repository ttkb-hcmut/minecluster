defmodule Wit do
  def getFreePort do
    {:ok, socket} = :gen_tcp.listen(0, [:binary, active: false, reuseaddr: true])
    {:ok, port}   = :inet.port(socket)
    :gen_tcp.close(socket)
    port
  end
  def getPython do
    case {System.find_executable("python"),System.find_executable("py")} do
      {nil,nil} -> Log.error(nil,"Cannot find Python on your system")
      {nil,e} -> e
      {e,nil} -> e
    end
  end
  def tryConnectToGui(address,port) do
    case :gen_tcp.connect(address,port, [:binary, packet: :line, active: false, reuseaddr: true]) do
      {:ok, stgSocket} -> {:ok, stgSocket}
      _ -> tryConnectToGui(address,port)
    end
  end
  def start1(serverPort \\ nil,guiPort \\ nil) do
    {serverPort,guiPort} = case {serverPort,guiPort} do
      {nil,nil} -> {getFreePort(),getFreePort()}
      {nil,g}   -> {getFreePort(),g}
      {s,nil}   -> {s,getFreePort()}
      {s,g}     -> {s,g}
    end
    {:ok,gtsSocket} = :gen_tcp.listen(serverPort, [:binary, packet: :line, active: false, reuseaddr: true])
    Log.detail(nil,"Elixir server listening on port #{serverPort}")
    Task.start_link(fn ->
      System.cmd(Wit.getPython,
      [
        "-u","./gui/tkinter/app.py",
        "--hkind", "coco",
        "--sport", "#{serverPort}",
        "--gport", "#{guiPort}",
      ])
    end)
    Process.spawn(fn -> Wit.listenServer(gtsSocket) end, [:link])
    # Process.sleep(1000)
    {:ok, stgSocket} = tryConnectToGui(:localhost,guiPort)
    Log.detail(nil,"Elixir server sending on port #{guiPort}...")
    Agent.update(:push_server, fn _ -> Process.spawn(fn -> Wit.pushServer(stgSocket) end, [:link]) end)
  end

  def start2(serverPart \\ ".serv", guiPart \\ ".gui") do
		uuid = UUID.uuid4()
		serverPort = File.cwd! <> "/.tmp/sock" <> uuid <> serverPart
		guiPort = File.cwd! <> "/.tmp/sock" <> uuid <> guiPart
		File.mkdir_p(File.cwd! <> "/.tmp")
    {:ok,gtsSocket} = :gen_tcp.listen(0, [:binary, ifaddr: { :local, serverPort }, packet: :line, active: false, reuseaddr: true])
    Log.detail(nil,"Elixir server listening at #{serverPort}")
    Task.start_link(fn ->
      System.cmd(Wit.getPython,
        [
          "-u","./gui/tkinter/app.py",
					"--hkind", "agott",
          "--sport", "#{serverPort}",
          "--gport", "#{guiPort}",
        ])
      end)
    Process.spawn(fn -> Wit.listenServer(gtsSocket) end, [:link])
    # Process.sleep(1000)
    {:ok, stgSocket} = tryConnectToGui({ :local, guiPort }, 0)
    Log.detail(nil,"Elixir server sending at #{guiPort}...")
    Agent.update(:push_server, fn _ -> Process.spawn(fn -> Wit.pushServer(stgSocket) end, [:link]) end)
  end

  def pushToGui (data \\ nil) do
    case {Agent.get(:push_server, & &1),data} do
      {nil,_} -> nil
      {a,:kill} ->
        try do
          Process.send(a,:kill,[])
        rescue
          _ ->
          Log.error(nil,"Kill Failed")
          nil
        end

      {a,_} ->
        try do
          Process.send(a,{
            :data,
            (data |> JSON.encode!)
            },[])
          rescue
            _ ->
            Log.error(nil, "Push failed")
            nil
        end
    end
    nil
  end

  def pushServer(socket) do
    receive do
      {:data, data} ->
        Log.detail(nil, "sending data ",[data])
        :ok = :gen_tcp.send(socket,data <> "\n")
        Wit.pushServer(socket)
      :kill ->
        Log.detail(nil,"Closing the push server")
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
        Wit.pushToGui(:kill)
        Cli.detail("Closing GUI socket")
    end
  end

  def handleRequest(client,socket) do
    case :gen_tcp.recv(client, 0) do
      {:ok, data} ->
        try do
          case String.trim(data)|> JSON.decode! do
            %{"command" => list} ->
              if is_nil(Wit.runCommand(list)) do
                Log.detail(nil,"Executed command: #{list |> Enum.join(" ")}")
              else
                Log.error(nil,"Failed command: #{list |> Enum.join(" ")}")
              end
            %{"api" => request}->
              Log.detail(nil,"Api request ",[request])
              WitApi.get(request)
            _ ->
              Log.error(nil,"Unknown received from gui")
          end
        rescue
          _ ->
          Log.error(nil,"Failed request handling")
          %{"success" => false} |> JSON.encode!
        end
        handleRequest(client,socket)
      {:error, :closed} ->
        Log.detail(nil,"GUI disconnected.")
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
        Log.new |> Log.info("",[Naas.getConfig(nil)],"configAll")

      # get self address and self cookie
      "self" ->
        Naas.getNodeSelf()

      # get all nodes connected
      "list" ->
        Naas.networkInfo(nil)

      # get group infos
      ["group/info", cookie] ->
        Log.new |> Log.info("",[Naas.getGroupInfo(nil,cookie)|>Map.put("name",Naas.listGroup(:map)|>Map.get(cookie,nil))],"groupInfo")

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

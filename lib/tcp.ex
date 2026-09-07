defmodule Wit do
  def start(server_port \\ 4000, gui_port \\ 4001) do
    {:ok, gts_socket} = :gen_tcp.listen(server_port, [:binary, packet: :line, active: false, reuseaddr: true])
    {:ok, stg_socket} = :gen_tcp.connect(:localhost,gui_port, [:binary, packet: :line, active: false, reuseaddr: true])
    IO.puts("Elixir server listening on port #{server_port}...")
    Task.start_link(fn ->
      System.cmd(System.find_executable("py"),
        [
          "-u","./gui/tkinter/test.py",
          "--sport", "#{server_port}",
          "--gport", "#{gui_port}"
        ])
      end)
    Process.spawn(fn -> Wit.listenServer(gts_socket) end, [:link])
    {:ok, _} = Agent.start_link(fn -> Process.spawn(fn -> Wit.pushServer(stg_socket) end, [:link]) end, name: :push_server)
  end
  def pushToGui (data \\ nil) do
    case Agent.get(:push_server, & &1) do
      nil -> nil
      a ->
        try do
          Process.send(a,{
            :data,
            data |> JSON.encode!
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
        :gen_tcp.send(socket,data <> "\n")
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
        response = try do
          case String.trim(data) |> JSON.decode! do
            %{"command" => list} ->
              if is_nil(Wit.runCommand(list)) do
                %{"success" => true} |> JSON.encode!
              else
                %{"success" => false} |> JSON.encode!
              end
            %{"api" => request} when request in [
              "list",
            ] ->
              WitApi.get(request)|> JSON.encode!
            _ ->
              %{"success" => false} |> JSON.encode!
          end
        rescue
          _ ->
          %{"success" => false} |> JSON.encode!
        end
        response = response <> "\n"
        :gen_tcp.send(client, response)
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
  @spec get(any()) :: nil
  def get(request) do
    case request do
      # get all configs
      "config/all" ->
        Log.new([Log.Info.new("configAll","",[Naas.getConfig(nil)])])

      # get all nodes connected
      "list" ->
        Naas.networkInfo(nil)

      # get all group info
      "group/list" ->
        Log.new([Log.Info.new("groupList","",[Naas.listGroup(:map)])])

      # get current group's information
      "group/status" ->
        Naas.groupStatus()

      # unknown
      _ ->
        nil

    end |> then(fn res -> case is_nil(res) or not is_struct(res,Log) do
      true->
        nil
      false ->
        res |> Log.toGui |> Wit.pushToGui
        nil
    end end)
  end
end

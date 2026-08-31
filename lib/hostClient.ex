defmodule Host do
  def updateCentral() do
    "Updating central..." |> Cli.detail
    Zm.post()
  end
  def stopServer() do
    # stop the mc server
    Process.send(Agent.get(:host_server, & &1),:stop,[])
    Agent.update(:role, fn _ -> :online end)
    Node.list()
    |> List.foldl(nil, fn ele,_ ->
      :erpc.call(ele, fn ->
        case Agent.get(:role, & &1) do
        :online ->
          Naas.connectGroup(Agent.get(:group, & &1))
          nil
        _ ->
          nil
        end
      end)
    end)
    nil
  end
  def runServer() do
    receive do
      :start ->
        # start the mc server
        Mj.runServer()
        Naas.broadcastMessage "Pls join mc server on ip:\n#{Node.self |> Atom.to_string}"
        runServer()
      :stop ->
        updateCentral()
        "Stopping server..." |> Cli.detail
        Naas.broadcastMessage "Server is stopping"
        exit(:normal)
      {:command, msg} ->
        "Ran command:\n#{msg}" |> Cli.detail
        runServer()
      _ ->
        "no message matched" |> Cli.warning
        runServer()
    after 300_000 -> # 5 min
      "trying to update..." |> Cli.detail
      updateCentral()
      runServer()
    end
  end
  def start() do
    # use Process.send(pid,{:message,msg})
    Agent.update(:host_server, fn _ -> Process.spawn(fn -> Host.runServer() end, [:link]) end)
    Process.send(Agent.get(:host_server, & &1),:start,[])
  end
end

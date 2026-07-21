defmodule Host do
  def updateCentral(loop\\true) do
    "Updating central..." |> Cli.toScreen
    Zm.post()
    if loop and Agent.get(:update, & &1) do
      Process.sleep(300_000) # 5 mins
      updateCentral()
    else
      exit(:normal)
    end
  end
  def stopServer() do
    # stop the mc server
    Process.send(Agent.get(:server, & &1),:stop,[])
    Agent.update(:update, fn _ -> false end)
    Process.spawn(fn -> updateCentral(false) end,[])
    Agent.update(:role, fn _ -> :online end)
    Node.list()
    |> List.foldl([], fn ele,acc ->
      [:erpc.call(ele,fn -> Naas.connectGroup(Agent.get(:group, & &1)) end) | acc]
    end)
  end
  def runServer() do
    receive do
      :start ->
        # start the mc server
        "Starting server..." |> Cli.toScreen
        Naas.broadcastMessage "Pls join mc server on ip:\n#{Node.self |> Atom.to_string}"
      :stop ->
        "Stopping server..." |> Cli.toScreen
        Naas.broadcastMessage "Server is stopping"
        Agent.update(:server, fn _ -> nil end)
        exit(:normal)
      {:command, msg} ->
        "Ran command:\n#{msg}" |> Cli.toScreen
      _ ->
        "no message matched" |> Cli.error
    end
  end
  def start() do
    # use Process.send(pid,{:message,msg})
    Agent.update(:update, fn _ -> true end)
    Process.spawn(fn -> Host.updateCentral() end, [])
    Agent.update(:server, fn _ -> Process.spawn(fn -> Host.runServer() end, []) end)
  end
end

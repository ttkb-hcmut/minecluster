defmodule Host do
  def updateCentral(loop\\true) do
    "Updating central..." |> Cli.toScreen
    Zm.post()
    if loop and Agent.get(:update, & &1) do
      Process.sleep(300_000) # 5 mins
      updateCentral()
    end
  end
  def stopServer() do
    # stop the mc server
    Agent.update(:update, fn _ -> false end)
    updateCentral(false)
    Naas.setRole(:online)
    Node.list()
    |> List.foldl([], fn ele,acc ->
      [:erpc.call(ele,fn -> Naas.reconnect() end) | acc]
    end)
  end
  def runServer() do
    receive do
      {:start, _msg} ->
        # start the mc server
        "Starting server..." |> Cli.toScreen
      {:stop, _msg} ->
        "Stopping server..." |> Cli.toScreen
        stopServer()
        exit(:normal)
      {:command, msg} ->
        "Ran command:\n#{msg}" |> Cli.toScreen
      {m, _msg} ->
        "no message matched: #{m |> Atom.to_string}" |> Cli.error
    after
      1_000 -> "Timed out" |> Cli.error
    end
  end
  def start() do
    Naas.setRole(:host)
    # use Process.send(pid,{:message,msg})
    Agent.update(:update, fn _ -> true end)
    Process.spawn(fn -> Host.updateCentral() end, [])
    pid = Process.spawn(fn -> Host.runServer() end, [])
    pid
  end
end

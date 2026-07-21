defmodule Pleb do
  def connectToHost(address) do
    # make minecraft connect to this server somehow
    Node.spawn(address, fn -> Naas.addGroup() end)
    # async connect mc to host
    Cli.toScreen "Connected to Host: " <> (address |> Atom.to_string)
    nil
  end
  def checkForHosts() do
    {hosts,_} = Naas.networkInfo()
    if(hosts |> length > 0) do
      [host|_] = hosts
      host
    else
      nil
    end
  end
  def start() do
    checkForHosts()
    |> then(fn h -> case h do
      host when not (host |> is_nil) ->
        connectToHost(host)
      nil ->
        Naas.setRole(:host)
    end end)
  end
end

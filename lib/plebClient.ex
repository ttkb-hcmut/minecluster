defmodule Pleb do
  def connectToHost(address) do
    # make minecraft connect to this server somehow
    :erpc.cast(address, fn -> Naas.addGroup() end)
    # async connect mc to host
    "Connected to Host: " <> (address |> Atom.to_string)
    |> Cli.toScreen
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

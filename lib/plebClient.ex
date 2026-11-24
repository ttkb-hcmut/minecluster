defmodule Pleb do
  def connectToHost(address) do
    # TODO make minecraft connect to this server somehow

    # :erpc.cast(address, fn -> Naas.addGroup() end) # ??????????????? what was this meant to do? early sync group implementation?
    # async connect mc to host
    # "Connected to Host: " <> (address |> Atom.to_string)
    # |> Cli.detail
    Broadcast.msgSelf("<]-minecluster-[>","A host is currently active: #{address}")
    nil
  end
  def checkForHosts() do
    hosts = NodeCore.networkInfo(:host)
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
        NodeGroup.setRole(:host)
    end end)
  end
end

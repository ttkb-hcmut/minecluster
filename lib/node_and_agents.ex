defmodule Naas do
  def startup() do
    if not File.exists?(".config") do
      File.write(".config", "{}")
    end
    if not File.exists?("group.config") do
      File.write("group.config", "[]")
    end

    File.open(".config", [:read], fn file ->
      data = IO.read(file, :line)
      {:ok, pid} = Agent.start_link(fn ->  data |> JSON.decode! end, name: :config)
      IO.puts "Imported config to Agent:"
      IO.inspect pid
    end)

    File.open("group.config", [:read], fn file ->
      data = IO.read(file, :line)
      {:ok, pid} = Agent.start_link(fn ->  data |> JSON.decode! end, name: :group)
      IO.puts "Imported group to Agent:"
      IO.inspect pid
    end)
  end

  def getConfig(k\\nil) do
    Agent.get(:config, & &1)
    |> then(fn c -> case k do
      nil -> c
      _ -> c |> Map.get(k,nil)
    end end)
  end

  def getAllConfig() do
    IO.puts "All stored configs:"
    map = getConfig()
    for k <- (map |> Map.keys) do
       "\t" <> IO.ANSI.blue() <> k <> IO.ANSI.reset() <> ": " <> (map |> Map.get(k)) |> IO.puts
    end
    nil
  end
  def setConfig(k\\nil,v\\nil) do
    case {k,v} do
      {nil,_} ->
        Agent.update(:config, fn _ -> v end)
      {_,nil} ->
        Agent.update(:config, fn c -> c |> Map.delete(k) end)
      {_,_} ->
        Agent.update(:config, fn c -> c |> Map.put(k,v) end)
    end
    File.write(".config", getConfig() |> JSON.encode!)
    nil
  end

  def startNode(address\\nil,cookie\\nil) do
    case {getConfig("address"),address} do
      {nil,nil} -> IO.puts("#{IO.ANSI.red()}Error:#{IO.ANSI.reset()} no address found in arg or config")
      {a,nil} -> IO.inspect Node.start(a|> String.to_atom, :longnames)
      {_,a} -> IO.inspect Node.start(a|> String.to_atom, :longnames)
    end
    case {getConfig("cookie"),cookie} do
      {nil,nil} -> nil
      {c,nil} -> Node.set_cookie(c|> String.to_atom)
      {_,c} -> Node.set_cookie(c|> String.to_atom)
    end
    nil
  end
  def connectNode(address,cookie\\nil) do
    case {Node.alive?(),getConfig("cookie"),cookie} do
      {false,_,_} -> nil
      {_,nil,nil} -> nil
      {_,c,nil} -> Node.set_cookie(c|> String.to_atom)
      {_,_,c} -> Node.set_cookie(c|> String.to_atom)
    end
    # address = if(address |> String.contains?(".")) do address else address<>".local" end
    case Node.connect(address |> String.to_atom) do
      true -> IO.puts "Successfully connected to nodes: "; IO.inspect Node.list(); true
      false -> IO.puts "#{IO.ANSI.red()}Error:#{IO.ANSI.reset()} Failed to connect to node: " <> address; false
      :ignored -> IO.puts("#{IO.ANSI.red()}Error:#{IO.ANSI.reset()} local node is not alive"); :ignored
    end
  end
  def disconnectNode() do
    # case Node.disconnect(Node.self()) do
    #   true -> IO.puts "Successfully disconnected"
    #   false -> IO.puts "Error: Failed to disconnect"
    #   :ignored -> IO.puts("Error: local node is not alive")
    # end
    Node.stop()
    nil
  end
  def connectGroup(cookie\\nil) do
    case {Node.alive?(),getConfig("cookie"),cookie} do
      {false,_,_} -> nil
      {_,nil,nil} -> nil
      {_,c,nil} -> Node.set_cookie(c|> String.to_atom)
      {_,_,c} -> Node.set_cookie(c|> String.to_atom)
    end
    case Agent.get(:group, & &1) do
      nil -> nil
      [] -> nil
      l ->
        l |> List.foldl(false, fn ele, acc ->
          if acc do true else( if(connectNode(ele) == true) do true else false end) end
        end)
    end
    nil
  end
  def addGroup() do
    case Node.alive?() do
      true ->
        Agent.update(:group, fn l ->
          (l ++ (Node.list() |> Enum.map(fn v -> v |> Atom.to_string end)))
          |> Enum.uniq
        end)
        IO.inspect Agent.get(:group, & &1)
        nil
      false -> IO.puts("#{IO.ANSI.red()}Error:#{IO.ANSI.reset()} local node is not alive")
    end
    File.write("group.config", Agent.get(:group, & &1) |> JSON.encode!)
    nil
  end
  def stopNode() do
    Node.stop()
    IO.puts("Stopped node")
    nil
  end
end

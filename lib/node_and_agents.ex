defmodule Naas do
  def startup() do
    {:ok, _} = Agent.start_link(fn -> true end, name: :interactive_output)
    {:ok, _} = Agent.start_link(fn -> nil end, name: :group)
    {:ok, _} = Agent.start_link(fn -> :online end, name: :role) # :online | :host | :central
    {:ok, _} = Agent.start_link(fn -> false end, name: :update)
    System.cmd("epmd", ["-daemon"])
    if not File.exists?(".config") do
      File.write(".config", "{}")
    end
    # if not File.exists?("group.config") do
    #   File.write("group.config", "[]")
    # end
    File.mkdir_p("./groups")
    File.open(".config", [:read], fn file ->
      data = IO.read(file, :line)
      {:ok, _} = Agent.start_link(fn ->  data |> JSON.decode! end, name: :config)
      Cli.toScreen "Imported config to Agent"
      # IO.inspect pid
    end)
  end
  def setRole(role) do
    if role in [:online,:host,:central] do
      Agent.update(:role, fn _ -> role end)
    end
  end
  def getConfig(k\\nil) do
    Agent.get(:config, & &1)
    |> then(fn c -> case k do
    nil -> c
    _ -> c |> Map.get(k,nil)
    end end)
  end

  def getAllConfig() do
    Cli.toScreen "All stored configs:"
    map = getConfig()
    for k <- (map |> Map.keys) do
       "\t" <> IO.ANSI.blue() <> k <> IO.ANSI.reset() <> ": " <> (map |> Map.get(k)) |> Cli.toScreen
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
    {r, _} = case {getConfig("address"),address} do
      {nil,nil} ->
        Cli.error "no address found in arg or config";
        {:error,nil}
      {a,nil} -> Node.start(a|> String.to_atom)
      {_,a} -> Node.start(a|> String.to_atom)
    end
    case {r, getConfig("cookie"),cookie} do
      {:error,_,_} -> nil
      {_,nil,nil} -> Node.set_cookie(:"")
      {_,c,nil} ->
        Node.set_cookie(c|> String.to_atom)
        Cli.toScreen "Started node with address: #{Node.self() |> Atom.to_string}"
      {_,_,c} ->
        Node.set_cookie(c|> String.to_atom)
        Cli.toScreen "Started node with address: #{Node.self() |> Atom.to_string}"
    end
    nil
  end
  def connectNode(address,cookie\\nil) do
    case {Node.alive?(),getConfig("cookie"),cookie} do
    {false,_,_} -> startNode(nil,cookie)
    {_,nil,nil} -> Node.set_cookie(:"")
    {_,c,nil} -> Node.set_cookie(c|> String.to_atom)
    {_,_,c} -> Node.set_cookie(c|> String.to_atom)
    end
    # address = if(address |> String.contains?(".")) do address else address<>".local" end
    case Node.connect(address |> String.to_atom) do
    true -> Cli.toScreen "Successfully connected to nodes: "; Cli.toScreen Node.list(); true
    false -> Cli.error "failed to connect to node: " <> address; false
    :ignored -> Cli.error("local node is not alive"); :ignored
    end
  end
  def getGroupInfo(group) do
    if(group not in listGroup()) do
      Cli.error("no group found with name \'#{group}\'");
      nil
    else
      {:ok,file} = File.open("./groups/#{group}/.config", [:read])
      data = file
      |> IO.read(:line)
      |> JSON.decode!
      File.close(file)
      data
    end
  end
  def setGroupInfo(data,group) do
    if(group not in listGroup()) do
      Cli.error("no group found with name \'#{group}\'");
      nil
    else
      File.write("./groups/#{group}/.config", data |> JSON.encode!)
    end
  end
  def connectGroup(group) do
    Zm.fetch(group)
    case getGroupInfo(group) do
    nil -> nil
    info ->
      l = info|> Map.get("connections",[])
      c = info|> Map.get("cookie",nil)
      startNode(nil,c)
      self = (Node.self() |> Atom.to_string)
      connected = l
      |> List.foldl([], fn ele, acc -> [Task.async(fn -> if(self != ele) do connectNode(ele,c) else false end end)|acc]
      end)
      |> Task.yield_many(on_timeout: :kill_task, timeout: 1000)
      |> Enum.map(fn {task, res} -> res || Task.shutdown(task, :brutal_kill) end)
      |> List.foldl([], fn {_,res},acc -> [res|acc]end)
      |> List.foldl(false, fn ele, acc -> ele or acc end)
      if connected do
        Agent.update(:group,fn _ -> group end)
      else
        Cli.error "but nobody came. . ."
      end
      Pleb.start()
    end
    nil
  end
  def reconnect() do
    if Agent.get(:role, & &1) == :online do
      group = Agent.get(:group, & &1)
      disconnectNode()
      connectNode(group)
    end
    nil
  end

  def syncGroupConnection() do
    case Agent.get(:group, & &1) do
    nil -> Cli.error("not connected to a group")
    g ->
      case getGroupInfo(g) do
      nil -> nil
      info when not (info |> is_nil) ->
        {_,d} = info
        |> Map.get_and_update("connections", fn l ->
          {l, Node.list
          |> List.foldl([], fn ele,acc ->
            [Task.async( fn -> :erpc.call(ele,fn -> Naas.getGroupInfo(g) |> Map.get("connections",[]) end) end)|acc]
          end)
          |> Task.yield_many(on_timeout: :kill_task, timeout: 1000)
          |> Enum.map(fn {task, res} -> res || Task.shutdown(task, :brutal_kill) end)
          |> List.foldl([], fn {_,res},acc -> [res|acc]end)
          |> List.foldl([Node.self() |> Atom.to_string |l], fn ele,acc ->
            ele ++ acc
          end)
          |> Enum.uniq}
        end)
        File.write("./groups/#{g}/.config", d |> JSON.encode!)
        Cli.toScreen d
      end
    end
    nil
  end
  def addGroup(node\\nil, group\\nil) do
    addition = case {Node.list(), node} do
      { [], nil} -> nil
      { l , nil} -> l
      { _ , n  } -> [n]
    end
    destination = case {Agent.get(:group, & &1), group} do
    {nil, nil} -> nil
    { g , nil} -> g
    { _ , g  } ->
      if(g in listGroup()) do g else
        Cli.error("no group found with name \'#{group}\'");
        nil
      end
    end

    case {addition,destination} do
    {nil,nil} ->
      Cli.error("can't add no node provided/no nodes connected to no group connected to/no group provided")
    {nil,_} ->
      Cli.error("can't add no node provided/no nodes connected to anything")
    {_,nil} ->
      Cli.error("can't add anything to no group connected to/no group provided")
    {a , g} ->
      File.open("./groups/#{group}/.config", [:read], fn file ->
        d = file
        |> IO.read(:line)
        |> JSON.decode!
        |> Map.get_and_update("connections", fn l -> ( a ++ l )|> Enum.uniq end)
        File.write("./groups/#{g}/.config", d |> JSON.encode!)
        Cli.toScreen d
      end)
    end
    nil
  end
  def listGroup() do
    case File.ls("./groups") do
      {:ok, files} ->
        files
      {:error, reason} ->
        Cli.error("failed to read ./groups directory: #{reason}");
        Cli.toScreen("Making ./groups directory");
        File.mkdir_p("./groups");
        []
    end
  end
  def makeGroup(name, cookie\\nil) do
    if(name in listGroup()) do
      Cli.error("group \'#{name}\' already exists");
      nil
    else
      File.mkdir_p("./groups/#{name}");
      File.mkdir_p("./groups/#{name}/data");
      File.write("./groups/#{name}/.config",
        %{
          "central" => %{},
          "connections" => [],
          "cookie" =>
            case {getConfig("cookie"),cookie} do
            {nil,nil} -> nil
            {c,nil} -> c
            {_,c} -> c
            end,
        } |> JSON.encode!
        );
      Cli.toScreen("Made group #{name} at path: \'./groups/#{name}\'");
      nil
    end
  end
  def groupStatus() do
    case Agent.get(:group, & &1) do
    nil -> Cli.toScreen "Not currently in a group"
    a ->
      Cli.toScreen "In group: " <> a;
      Cli.toScreen getGroupInfo(a);
      networkInfo();
    end
    nil
  end
  def networkInfo() do
    {hosts,plebs} = Node.list() |> List.foldl({[],[]}, fn ele,{h,p} ->
      case(:erpc.call(ele, fn -> Agent.get(:role, & &1) end)) do
        :host -> {[ele|h], p}
        _ -> {h, [ele|p]}
      end
    end)
    Cli.toScreen(hosts |> List.foldl("HOST:", fn ele,acc ->
      acc <> "\n" <> (ele|> Atom.to_string)
    end))
    Cli.toScreen(plebs |> List.foldl("CONNECTED:", fn ele,acc ->
      acc <> "\n" <> (ele|> Atom.to_string)
    end))
    {hosts,plebs}
  end
  def disconnectNode() do
    stopNode()
    startNode()
    nil
  end
  def stopNode() do
    Agent.update(:group, fn _ -> nil end)
    Node.stop()
    Cli.toScreen("Stopped node")
    nil
  end
end

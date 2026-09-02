defmodule Naas do
  def startup() do
    {:ok, _} = Agent.start_link(fn -> true end, name: :interactive_output)
    {:ok, _} = Agent.start_link(fn -> nil end, name: :group)
    {:ok, _} = Agent.start_link(fn -> :online end, name: :role) # :online | :host | :central
    {:ok, _} = Agent.start_link(fn -> nil end, name: :host_server)
    {:ok, _} = Agent.start_link(fn -> Process.spawn(fn -> Naas.runMsgServer() end, [:link]) end, name: :message_server)
    Task.start_link(fn -> System.cmd("epmd", []) end)

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
      Cli.detail "Imported config to Agent"
      # IO.inspect pid
    end)
  end

  def monosodiumglutamate(src \\:nonode@nohost, msg \\ "ping") do
    case Agent.get(:message_server, & &1) do
      nil -> nil
      a ->
        Process.send(a,{
          :message,
          src |> Atom.to_string,
          msg
        },[])
    end
    nil
  end
  def runMsgServer() do
    receive do
      {:message, src, msg} ->
        "#{IO.ANSI.green()}#{src}: #{msg}#{IO.ANSI.reset()}" |> Cli.info
        Naas.runMsgServer()
      _ ->
        "no message matched" |> Cli.warning
        Naas.runMsgServer()
    end
  end
  def setRole(role) do

    if not(Agent.get(:group,& &1) |> is_nil) do
      case {Agent.get(:role,& &1),role} do
      {:host,r} when r != :host ->
        Host.stopServer
        nil
      _ ->
        nil
      end

      case {Agent.get(:role,& &1),role} do
      {_,:host} ->
        Agent.update(:role, fn _ -> :host end)
        Host.start()
        nil
      {_,:online}->
        Agent.update(:role, fn _ -> :online end)
        Pleb.start()
        nil
      {_,:central} ->
        Agent.update(:role, fn _ -> :central end)
        NodeCentral.centralStart()
        nil
      {a,b} when a == b ->
        Cli.warning("setRole trying to set your role to the same role: {#{a|>Atom.to_string},#{b|>Atom.to_string}}")
        nil
      {a,b} ->
        Cli.error("No setRole pattern matched for {#{a|>Atom.to_string},#{b|>Atom.to_string}}")
        nil
      end

    else
      Cli.error "Not currently in a group yet"
      nil
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
    Cli.info "All stored configs:"
    map = getConfig()
    for k <- (map |> Map.keys) do
       "\t" <> IO.ANSI.blue() <> k <> IO.ANSI.reset() <> ": " <> (map |> Map.get(k)) |> Cli.info
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
        Cli.error "No address found in arg or config";
        {:error,nil}
      {a,nil} -> Node.start(a|> String.to_atom)
      {_,a} -> Node.start(a|> String.to_atom)
    end
    case {r, getConfig("cookie"),cookie} do
      {:error,_,_} -> nil
      {_,nil,nil} -> Node.set_cookie(:"")
      {_,c,nil} ->
        Node.set_cookie(c|> String.to_atom)
        Cli.detail "Started node with address: #{Node.self() |> Atom.to_string}"
      {_,_,c} ->
        Node.set_cookie(c|> String.to_atom)
        Cli.detail "Started node with address: #{Node.self() |> Atom.to_string}"
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
    true ->
      Cli.info "Successfully connected to nodes:#{
        Node.list() |> Enum.map(fn ele -> "\n  #{ele |> Atom.to_string}" end) |> Enum.join("")
      }";
      true
    false -> Cli.error "Failed to connect to node: " <> address; false
    :ignored -> Cli.error("Local node is not alive"); :ignored
    end
  end
  def getGroupInfo(group, cookie\\nil) do
    name = case cookie do
      nil ->
        group
      _ ->
        listGroup(:map)
        |> Map.get(cookie, nil)
    end
    if(name not in listGroup()) do
      Cli.error("No group found with name");
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
      Cli.error("No group found with name \'#{group}\'");
      nil
    else
      File.write("./groups/#{group}/.config", data |> JSON.encode!)
    end
  end
  def inParallel(list,fun) do
    list
    |> List.foldl([], fn ele, acc -> [Task.async(fn -> fun.(ele) end)|acc]
    end)
    |> Task.yield_many(on_timeout: :kill_task, timeout: 5000)
    |> List.foldl([], fn {_,{_,ele}},acc -> [ele|acc] end)
  end
  def cookieIs(c\\nil) do
    cc = Naas.getGroupInfo(Agent.get(:group, & &1))
    case {cc,c} do
      {nil,nil} -> nil
      {_,nil} -> cc |> Map.get("cookie", nil);
      {nil,_} -> false
      {_,_} -> cc == c
    end
  end
  def connectGroup(group) do
    case getGroupInfo(group) do
    nil -> nil
    info ->
      Agent.update(:group,fn _ -> group end)
      Zm.fetch(group)
      l = info|> Map.get("connections",[])
      c = info|> Map.get("cookie",nil)
      if (not is_nil(c)) do
        self = Node.self |> Atom.to_string
        l |> Naas.inParallel(fn ele ->
          if( self != ele
          and Node.ping(ele|> String.to_atom) == :pong
          and :erpc.call(ele|> String.to_atom, fn -> Naas.cookieIs c end)
          ) do
            connectNode(ele,c)
          else false end
        end)
        |> List.foldl(false, fn ele,acc -> acc or ele end)
        |> then(fn res -> case res do
          true -> nil
          false ->
            Node.set_cookie(Node.self, c |> String.to_atom)
        end end)
        setRole(:online)
      else
        Cli.error "Group's Cookie not found"
      end
    end
    nil
  end
  # def reconnect() do
  #   if Agent.get(:role, & &1) == :online do
  #     group = Agent.get(:group, & &1)
  #     disconnectNode()
  #     connectGroup(group)
  #   end
  #   nil
  # end

  def syncGroupConnection() do
    case Agent.get(:group, & &1) do
    nil -> Cli.error("Not connected to a group")
    g ->
      case getGroupInfo(g) do
      nil -> nil
      info when not (info |> is_nil) ->
        c = info |> Map.get("cookie", nil)
        {_,d} = info
        |> Map.get_and_update("connections", fn l ->
          {l, Node.list
          |> Naas.inParallel(fn ele ->
            :erpc.call(ele,fn -> Naas.getGroupInfo(nil, c) |> Map.get("connections",[]) end)
          end)
          |> List.foldl([Node.self() |> Atom.to_string |l], fn ele,acc ->
            ele ++ acc
          end)
          |> Enum.uniq}
        end)
        File.write("./groups/#{g}/.config", d |> JSON.encode!)
        Cli.detail d
      end
    end
    nil
  end
  def addGroup(node\\nil, group\\nil) do
    addition = case {Node.list(), node} do
      { [], nil} -> nil
      { l , nil} -> l |> Enum.map(fn e -> e |> Atom.to_string end)
      { _ , n  } -> [n]
    end
    destination = case {Agent.get(:group, & &1), group} do
    {nil, nil} -> nil
    { g , nil} -> g
    { _ , g  } ->
      if(g in listGroup()) do g else
        Cli.error("No group found with name \'#{group}\'");
        nil
      end
    end

    case {addition,destination} do
    {nil,nil} ->
      Cli.error("Can't add no node provided/no nodes connected to no group connected to/no group provided")
    {nil,_} ->
      Cli.error("Can't add no node provided/no nodes connected to anything")
    {_,nil} ->
      Cli.error("Can't add anything to no group connected to/no group provided")
    {a , g} ->
      {:ok, file} = File.open("./groups/#{g}/.config", [:read])
      {_,d} = file
      |> IO.read(:line)
      |> JSON.decode!
      |> Map.get_and_update("connections", fn l -> {nil, ( a ++ l )|> Enum.uniq} end)
      File.close(file)
      File.write("./groups/#{g}/.config", d |> JSON.encode!)
      Cli.detail d |> Map.get("connections","none")
    end
    nil
  end
  def listGroup(mode \\ :name) do
    case {File.ls("./groups"),mode} do
    {{:ok, folders},:name} ->
      folders
    {{:ok, folders},:map} ->
      folders
      |> Naas.inParallel(fn ele ->
        File.open("./groups/#{ele}/.config", [:read], fn file ->
          data = IO.read(file, :line) |> JSON.decode! |> Map.get("cookie", nil)
          {ele,data}
        end)
      end)
      |> Enum.filter(fn {_,data} ->
        not is_nil(data)
      end)
      |> List.foldl(%{}, fn {group,cookie},acc ->
        acc |> Map.put_new(cookie,group)
      end)
    {{:error, reason},_} ->
      Cli.warning("failed to read ./groups directory: #{reason}");
      Cli.detail("Making ./groups directory");
      File.mkdir_p("./groups");
      Naas.listGroup(mode)
    end
  end
  def secretGen() do
    DateTime.utc_now(:microsecond, Calendar.ISO)
    |> DateTime.to_string
    |> then(fn t -> :crypto.hash(:sha256, t) end)
    |> Base.encode32
  end
  def makeGroup(name) do
    # blocks reuse of name
    name = case name in listGroup() do
    false ->
      name
    true ->
      Cli.error "The name \'#{name}\' already exists"
      nil
    end
    data = case {name, is_nil(Agent.get(:group,& &1))} do
    {nil,_} ->
      nil
    {_,false} ->
      Cli.error "Already in a group '#{Agent.get(:group,& &1)}'; please leave before creating a new group"
      nil
    {_,true} ->
      # case you "connected" to a group but hasn't registered it as a group for yourself
      case (
        Node.list()
        |> Naas.inParallel(fn ele ->
          { ele,
            :erpc.call(ele, fn ->
            Agent.get(:group, & &1)
            |> Naas.getGroupInfo()
          end)}
        end)
        |> Enum.filter(fn {_,ele} -> not is_nil(ele) end)
      ) do
      [] ->
        cookie = Naas.secretGen
        ;
        %{
          "central" => %{},
          "connections" => [Node.self |> Atom.to_string],
          "cookie" => cookie
        }
      [{_,first}|_] ->
        first
        |> Map.get_and_update!("connections", fn val -> {val, [Node.self |> Atom.to_string|val] |> Enum.uniq} end)
      end
    end
    case {name,data, Node.alive?()} do
    {a,b,_} when is_nil(a) or is_nil(b) ->
      nil
    {_,_, false} ->
      Cli.error("Please start node before making a new group");
      nil
    _->
      File.mkdir_p("./groups/#{name}");
      File.mkdir_p("./groups/#{name}/data");
      File.write("./groups/#{name}/.config",
        data |> JSON.encode!
      );
      Cli.detail("Made group #{name} at path:\n  './groups/#{name}'");
      Naas.connectGroup(name)
      nil
    end
  end
  def groupStatus() do
    case Agent.get(:group, & &1) do
    nil -> Cli.info "Not currently in a group"
    a ->
      case getGroupInfo(a) do
      nil ->
        Cli.error("Currently in an unknown group")
      data ->
        Cli.info "In group: " <> a;
        Cli.info "Connections: \n  #{
          data |> Map.get("connections") |> Enum.join("\n  ")
        }";
        Cli.info "Cookie: \n  #{
          data |> Map.get("cookie")
        }";
      end
    end
    nil
  end
  def broadcastMessage(message) do
    self = Node.self()
    Node.list
    |> Naas.inParallel(fn n ->
      :erpc.cast(n,Naas,:monosodiumglutamate,[self,message])
    end)
    nil
  end
  def networkInfo() do
    networkMembers = [Node.self|Node.list()]
    {hosts,plebs,central} = networkMembers |> List.foldl({[],[],[]}, fn ele,{h,p,c} ->
      res = :erpc.call(ele, fn -> Agent.get(:role, & &1) end )
      case res do
        :host -> {[ele|h], p, c}
        :central -> {h, p,[ele|c]}
        _ -> {h, [ele|p],c}
      end
    end)

    [ "Network Members:#{networkMembers |> Enum.map(fn e ->"\n  #{e |> Atom.to_string}" end)}",
      "Central:#{central |> Enum.map(fn e ->"\n  #{e |> Atom.to_string}" end)}",
      "Host:#{hosts |> Enum.map(fn e ->"\n  #{e |> Atom.to_string}" end)}",
      "Online:#{plebs |> Enum.map(fn e ->"\n  #{e |> Atom.to_string}" end)}" ] |> Enum.join("\n") |> Cli.info

    {hosts,plebs}
  end
  def disconnectNode() do
    self = Node.self() |> Atom.to_string
    stopNode()
    startNode(self)
    nil
  end
  def stopNode() do
    setRole(:online)

    Agent.update(:group, fn _ -> nil end)
    Node.stop()
    Cli.detail("Stopped node")
    nil
  end
end

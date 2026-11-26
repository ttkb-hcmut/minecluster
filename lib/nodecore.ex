defmodule NodeCore do
  def initialize() do
    {:ok, _} = Agent.start_link(fn -> true end, name: :interactive_output)
    {:ok, _} = Agent.start_link(fn -> nil end, name: :group)
    {:ok, _} = Agent.start_link(fn -> :online end, name: :role) # :online | :host | :central
    {:ok, _} = Agent.start_link(fn -> nil end, name: :host_server)
    {:ok, _} = Agent.start_link(fn -> Process.spawn(fn -> Broadcast.runMsgServer() end, [:link]) end, name: :message_server)
    {:ok, _} = Agent.start_link(fn -> nil end, name: :push_server)
    Task.start_link(fn -> System.cmd("epmd", []) end)
    Process.spawn(fn -> NodeGroup.monitorNodes() end, [:link])

    if not File.exists?(".config") do
      File.write(".config", "{}")
    end
    # if not File.exists?("group.config") do
    #   File.write("group.config", "[]")
    # end
    File.mkdir_p("./groups")
    File.open(".config", [:read], fn file ->
      fromFile = IO.read(file, :line)|> JSON.decode!
      conf = fn k,v -> fromFile |> Map.get(k,v) end
      data = %{
        "address"   => conf.("address", "you@127.0.0.1"),
        "cookie"    => conf.("cookie", "balls"),
        "logLevel"  => conf.("logLevel", ["info","detail","warning","error"]),
        "guiSocket" => conf.("guiSocket", "port"),
      }
      {:ok, _} = Agent.start_link(fn ->  data  end, name: :config)
      Cli.detail "Imported config to Agent"
      File.write(".config", SelfConfig.get() |> JSON.encode!)
      # IO.inspect pid
    end)
    case Agent.get(:config,& &1) |> Map.get("guiSocket","port") do
      "port"->
        Wit.start1
      "file"->
        Wit.start2
      "nil" ->
        nil
      "cli" ->
        Cli.start
    end
  end

  def getNodeSelf() do
    Log.new()
    |> Log.info("Self Address:\n  #{Log.dataHold}",Node.self()|>Atom.to_string,"selfAddress")
    |> Log.info("Self Cookie:\n  #{Log.dataHold}",Node.get_cookie()|>Atom.to_string,"selfCookie")
  end

  def start(address\\nil,cookie\\nil) do
    if Node.alive? do
      NodeCore.stop()
    end
    {address,cookie} = if address == "nonode@nohost" do
      {nil,nil}
    else
      {address,cookie}
    end
    {r, _} = case {SelfConfig.get("address"),address} do
      {nil,nil} ->
        Log.error(nil,"No address found in arg or config")
        {:error,nil}
      {a,nil} ->
        Log.detail(nil,"Started default address: "<>Log.dataHold,[a])
        Node.start(a|> String.to_atom)
      {_,a} ->
        Log.detail(nil,"Started arg address: "<>Log.dataHold,[a])
        Node.start(a|> String.to_atom)
    end
    case {r, SelfConfig.get("cookie"),cookie} do
      {:error,_,_} ->
        Log.detail(nil,"No start no cookie")
      {_,nil,nil} ->
        Node.set_cookie(Node.self,:"")
        Log.detail(nil,"Started no cookie")
      {_,c,nil} ->
        Node.set_cookie(Node.self,c|> String.to_atom)
        Log.detail(nil,"Started default cookie: "<>Log.dataHold,[c])
      {_,_,c} ->
        Node.set_cookie(Node.self,c|> String.to_atom)
        Log.detail(nil,"Started arg cookie: "<>Log.dataHold,[c])
    end
    nil
  end

  def connect(address,cookie\\nil) do
    case {Node.alive?(),SelfConfig.get("cookie"),cookie} do
    {false,_,_} -> NodeCore.start(nil,cookie)
    {_,nil,nil} -> Node.set_cookie(:"")
    {_,c,nil} -> Node.set_cookie(c|> String.to_atom)
    {_,_,c} -> Node.set_cookie(c|> String.to_atom)
    end
    Log.detail(nil, "Connecting as #{Log.dataHold} #{Log.dataHold}", [Node.self,Node.get_cookie] )
    # address = if(address |> String.contains?(".")) do address else address<>".local" end
    res = case Node.connect(address |> String.to_atom) do
    true ->
      Cli.info "Successfully connected to nodes:#{
        Node.list() |> Enum.map(fn ele -> "\n  #{ele |> Atom.to_string}" end) |> Enum.join("")
      }";
      true
    false -> Cli.error "Failed to connect to node: " <> address; false
    :ignored -> Cli.error("Local node is not alive"); :ignored
    end
    res
  end

  def networkInfo(check \\ nil) do
    networkMembers = [Node.self|Node.list()]
    {hosts,plebs,central} = networkMembers |> List.foldl({[],[],[]}, fn ele,{h,p,c} ->
      res = :erpc.call(ele, fn -> Agent.get(:role, & &1) end )
      case res do
        :host -> {[ele|h], p, c}
        :central -> {h, p,[ele|c]}
        _ -> {h, [ele|p],c}
      end
    end)
    case check do
      nil ->
        listifier = fn l -> l |> List.foldl({"",[]}, fn ele, {t,d} ->
            { t <> "\n  #{Log.dataHold}",
              [ele |> Atom.to_string | d]
            }
          end)
        end
        {nTemplate,nData} = networkMembers |> listifier.()
        {cTemplate,cData} = central |> listifier.()
        {hTemplate,hData} = hosts |> listifier.()
        {oTemplate,oData} = plebs |> listifier.()
        Log.new
        |> Log.info("Network Members:" <> nTemplate, nData, "nodeList")
        |> Log.info("Central:" <> cTemplate, cData, "central")
        |> Log.info("Host:" <> hTemplate, hData, "host")
        |> Log.info("Online:" <> oTemplate, oData, "online")
      :host -> hosts
      :central -> central
      :online -> plebs
    end
  end

  def disconnect() do
    self = Node.self() |> Atom.to_string
    NodeCore.stop()
    NodeCore.start(self)
    nil
  end

  def stop() do
    NodeGroup.setRole(:online)
    Agent.update(:group, fn _ -> nil end)
    Node.stop()
    Cli.detail("Stopped node")
    nil
  end
end

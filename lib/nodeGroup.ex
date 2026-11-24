
defmodule NodeGroup do
  def monitorNodes() do
    :net_kernel.monitor_nodes(true)
    receive do
      {a,_} ->
      NodeGroup.waitForMoreNodes(a == :nodeup)
    end
  end
  def waitForMoreNodes(withSync \\ false) do
    receive do
      {a,_} ->
        NodeGroup.waitForMoreNodes(withSync or a == :nodeup)
      after 100 ->
        if(withSync) do NodeGroup.syncConfig end
        WitApi.get("list")
        WitApi.get("self")
        NodeGroup.monitorNodes
    end
  end

  def setRole(role) do
    if not(Agent.get(:group,& &1) |> is_nil) do
      case {Agent.get(:role,& &1),role} do
      {:host,r} when r != :host -> Host.stopServer
      _ -> nil
      end

      case role do
      :host ->
        Agent.update(:role, fn _ -> :host end)
        Host.start()
      :online ->
        Agent.update(:role, fn _ -> :online end)
        Pleb.start()
      :central ->
        Agent.update(:role, fn _ -> :central end)
        NodeCentral.centralStart()
      a ->
        Log.error(nil,"No setRole pattern matched for "<> Log.dataHold,[a|>Atom.to_string])
      end
    else
      Log.warning(nil,"Not currently in a group yet")
    end
    nil
  end

  def getConfig(group, cookie\\nil) do
    name = case cookie do
      nil ->
        group
      _ ->
        NodeGroup.list(:map)
        |> Map.get(cookie, nil)
    end
    if(name not in NodeGroup.list()) do
      Log.error(nil,"No group found with name: "<>Log.dataHold, [name]);
      nil
    else
      {:ok,file} = File.open("./groups/#{name}/.config", [:read])
      data = file
      |> IO.read(:line)
      |> JSON.decode!
      File.close(file)
      %{
        "connections" => data |> Map.get("connections"  ,[Node.self |> Atom.to_string]),
        "cookie"      => data |> Map.get("cookie"       ,nil),
        "central"     => case data |> Map.get("central" ,nil) do
          %{"firebase" => a} -> %{"firebase" => a}
          _ -> nil
        end,
        "server"      => case data |> Map.get("server"  ,nil) do
          %{"firebase" => a} -> %{"firebase" => a}
          %{"bedrock"  => a} -> %{"bedrock"  => a}
          _ -> nil
        end
      }
    end
  end
  def setConfig(data,group) do
    if(group not in NodeGroup.list()) do
      Log.error(nil,"No group found with name: "<>Log.dataHold, [group]);
    else
      File.write("./groups/#{group}/.config", data |> JSON.encode!)
    end
    nil
  end
  def cookieIs(c\\nil) do
    cc = NodeGroup.getConfig(Agent.get(:group, & &1))
    case {cc,c} do
      {nil,nil} -> nil
      {_,nil} -> cc |> Map.get("cookie", nil);
      {nil,_} -> false
      {_,_} -> cc == c
    end
  end
  def connect(group,isRecursive\\false) do
    case NodeGroup.getConfig(group) do
    nil -> nil
    info ->
      Agent.update(:group,fn _ -> group end)
      l = info|> Map.get("connections",[])
      c = info|> Map.get("cookie",nil)
      self = Node.self |> Atom.to_string
      Node.set_cookie(Node.self, c |> String.to_atom)
      res = l |> Utils.inParallel(fn ele ->
        if(self != ele) do NodeCore.connect(ele,c) else false end
      end)
      |> List.foldl(false, fn ele,acc -> acc or ele end)

      NodeGroup.syncConfig()
      if not res and not isRecursive do
        Zm.fetch(group)
        NodeGroup.connect(true)
      else
        NodeGroup.setRole(:online)
    end
    end
    nil
  end

  def syncConfig() do
    case NodeGroup.cookieIs do
    nil ->
      Log.error(nil,"Not connected to a group")
    c ->
      ################## CALLING OUT TO ALL MY FELLOW NODES
      l = NodeGroup.getConfig(nil,c) |> Map.get("connections",[])
      {_,d} = l |> Map.put("connections",
        Node.list |> Utils.inParallel(fn ele ->
          :erpc.call(ele,fn ->
            [ Node.self |> Atom.to_string |
            (NodeGroup.getConfig(nil, c) |> Map.get("connections",[]))]
          end)
        end)
        |> List.flatten([Node.self |> Atom.to_string | l])
        |> Enum.uniq
      )
      ################ ALL NODES, LEND ME YOUR GROUP CONFIGS
      ddelta = d
      |> Map.get("connections",[])
      |> Enum.filter(fn v -> (v |> String.to_atom) in Node.list end)
      |> Utils.inParallel(fn ele -> :erpc.call(ele |> String.to_atom,fn ->
        gc = NodeGroup.getConfig(nil,c)
        {
          case gc|> Map.get("central",nil) do
            %{"firebase" => a} -> %{"firebase" => a}
            %{"node"     => a} -> %{"node"     => a}
            _ -> nil
          end,
          case gc|> Map.get("server",nil) do
            %{"java"    => a} -> %{"java"    => a}
            %{"bedrock" => a} -> %{"bedrock" => a}
            _ -> nil
          end,
          ele
        }
      end) end)
      |> List.foldl(%{"central" => nil,"server" => nil}, fn ele,acc ->
      %{
        "central" => case {ele[0],acc[0]} do
          {nil,a} -> a
          {a,nil} -> a
          {a,b} when a == b -> a
          {a,b} -> Log.warning(nil,"Conflicting central data from #{Log.dataHold}",[ele[2],a,b])
            b
        end,
        "server"  => case {ele[0],acc[0]} do
          {nil,a} -> a
          {a,nil} -> a
          {a,b} when a == b -> a
          {a,b} -> Log.warning(nil,"Conflicting server data from #{Log.dataHold}",[ele[2],a,b])
            b
        end,
      }
      end)
      dnew = d |> Map.merge(ddelta)
      ################ ONE FOR ALL SCENE IDK I DONT WATCH MY HERO ACADEMIA
      dnew
      |> Map.get("connections",[])
      |> Enum.filter(fn v -> (v |> String.to_atom) in Node.list end)
      |> Utils.inParallel(fn ele -> :erpc.call(ele |> String.to_atom,fn ->
        dnew |> NodeGroup.setConfig(NodeGroup.list(:map) |> Map.get(c, nil))
      end) end)
      Log.detail(nil,"Synced group config: " <> Log.dataHold,[dnew])
    end
    nil
  end
  def list(mode \\ :name) do
    case {File.ls("./groups"),mode} do
    {{:ok, folders},:name} ->
      folders
    {{:ok, folders},:map} ->
      map = folders
      |> Utils.inParallel(fn ele ->
        File.open("./groups/#{ele}/.config", [:read], fn file ->
          data = IO.read(file, :line) |> JSON.decode! |> Map.get("cookie", nil)
          {ele,data}
        end)
      end)
      |> Enum.filter(fn {_,data} ->
        not is_nil(data)
      end)
      |> List.foldl(%{}, fn {_,{group,cookie}},acc ->
        acc |> Map.put_new(cookie,group)
      end)
      map
    {{:error, reason},_} ->
      Log.warning(nil,"failed to read ./groups directory: "<>Log.dataHold,[reason]);
      Log.detail(nil,"Making ./groups directory");
      File.mkdir_p("./groups");
      NodeGroup.list(mode)
    end
  end
  def delete(name) do
    case File.rm_rf("./groups/#{name}") do
      {:ok,_} -> Log.info(nil,"Deleted group "<>Log.dataHold(),[name])
      _ -> Log.error(nil,"Failed to delete group "<>Log.dataHold(),[name])
    end
  end
  def make(name) do
    # blocks reuse of name
    name = case name in NodeGroup.list() do
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
        |> Utils.inParallel(fn ele ->
          { ele,
            :erpc.call(ele, fn ->
            Agent.get(:group, & &1)
            |> NodeGroup.getConfig()
          end)}
        end)
        |> Enum.filter(fn {_,ele} -> not is_nil(ele) end)
      ) do
      [] ->
        cookie = Utils.secretGen
        ;
        %{
          "central" => nil,
          "connections" => [Node.self |> Atom.to_string],
          "cookie" => cookie,
          "server" => nil
        }
      [{_,first}|_] ->
        {_, newMap} = first
        |> Map.get_and_update!("connections", fn val -> {val, [Node.self |> Atom.to_string|val] |> Enum.uniq} end)
        newMap
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
      NodeGroup.connect(name)
      nil
    end
  end
  def status() do
    case Agent.get(:group, & &1) do
    nil ->
      Log.new
      |> Log.info("Not currently in a group",nil,"groupStatusName")
    a ->
      case NodeGroup.getConfig(a) do
      nil ->
        Log.error(nil,"Currently in an unknown group: ",[], "groupStatusError")
      data ->
        Log.new
        |> Log.info("In group: #{Log.dataHold}", a, "groupStatusName")
        |> Log.info("Connections:"<>
          (data |> Map.get("connections") |> Enum.map(fn _ -> "\n  #{Log.dataHold}" end) |> Enum.join("")),
          data |> Map.get("connections"), "groupStatusConnections"
        )
        |> Log.info(
          "Cookie:\n  #{Log.dataHold}",
          data |> Map.get("cookie"), "groupStatusCookie"
        )
        |> Log.info(
          "Server:\n  #{Log.dataHold} #{Log.dataHold}",
          [
            data |> Map.get("server")
          ], "groupStatusServer"
        )
      end
    end
  end
end

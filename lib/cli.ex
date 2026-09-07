defmodule Command do
  @doc"""
  kinda like real cli argument passing
  """
  def arbitraryArg({ctx,inputs,_}) do
    inputParser = fn argsList ->
      {excess,res} = inputs
      |> Enum.reverse
      |> List.foldl({[],%{}}, fn ele,{hold,ret} ->
        if ele not in argsList do
          {[ele|hold],ret}
        else
          {[],ret |> Map.update(ele,hold,fn e -> hold ++ e end)}
        end
      end)

      res |> Map.update("",excess,fn e -> excess ++ e end)
      |> then(fn r ->
      Cli.detail "Parsed:" <> (
        r |> Map.keys() |> Enum.map(fn e ->
          "\n  #{if e == "" do "<excess>" else e end} => [#{r |> Map.get(e,"")|> Enum.join(",")}]"
        end) |> Enum.join("")
      )
      r
      end)
    end

    callback = ctx |> Map.get(:a, fn _ -> Cli.error "No action found" end)
    ctx
    |> Map.get(:p, %{}) # arg options
    |> Map.keys
    |> inputParser.()
    |> callback.()
  end
  @doc"""
  turns function output to be Json for non interactable mode
  """
  def run(module,function,args) do

    # 2. Execute the function
    IO.puts %{type: "output", data: apply(module, function, args)} |> JSON.encode!
  end
  @doc"""
  Demo printing all possible continuations from an inputed command
  """
  def help(recursive,ctx,h \\ ["..."]) do
    info = ctx |> Map.get(:i, "NO INFORMATION")
    action   = ctx |> Map.get(:a, fn _ -> nil end)
    children = ctx |> Map.get(:c, %{}) |> Map.keys
    params   = ctx |> Map.get(:p, %{})
    [_head|tail] = h
    log = %Log{}
    helpHistoryTemplate = [
      IO.ANSI.blue()<>IO.ANSI.underline()<>Log.dataHold<>IO.ANSI.reset()
      | (tail |> Enum.map(fn _ -> Log.dataHold end))] |> Enum.reverse
    {paramsTemplate,paramsData} = params
    |> Map.keys
    |> List.foldr({[],[]}, fn ele,{pt,pd} ->
      { ["  #{Log.dataHold} => #{Log.dataHold}"|pt],
        [ if is_nil(ele) or ele == "" do "<input>" else ele end,
          params|> Map.get(ele,"No info")
        | pd]}
    end)
    log
    |> Log.info( "?> " <> (helpHistoryTemplate |> Enum.join(" ")), h |> Enum.reverse, "helpHistory" )
    |> then(fn l -> case Command.commandContinuations(is_nil(action) or is_binary(action),children,params) do
      {t,d} when t == "" or d == [] -> l
      {t,d} -> l |> Log.info(t,d,"commandContinuations")
      end
    end)
    |> Log.info( "i: #{Log.dataHold}", [info], "commandInfo")
    |> Log.info(paramsTemplate |> Enum.join("\n"),paramsData)
    |> Log.flush

    if recursive do
      for c <- children do
        command = case c do
          :"" ->  "<input>"
          _ ->  (c |> Atom.to_string)
          end
        help(true,ctx |> Map.get(:c,%{}) |> Map.get(c,%{}),[command|h])
      end
    end
  end
  def commandContinuations(required\\false,children\\[],params\\%{}) do
    {template,data} = children
    |> List.foldr({[],[]},fn ele,{o,f} ->
      { [Log.dataHold|o],
        [if ele == :"" do "<input>" else ele |> Atom.to_string end | f] }
    end)
    {template,data} = params
    |> Map.keys
    |> List.foldr({template,data},fn ele,{o,f} ->
      { ["^"|o],
        [ if is_nil(ele) or ele == "" do "<input>" else ele  end | f ] }
    end)

    resTemplate = IO.ANSI.color(2,2,2)
      <> (template
      |> Enum.join("|")
      |> then(fn c -> case {required,params == %{},c == ""} do
        {_,_,true}     -> ""
        {true,true,_}  -> c
        {false,true,_} -> "\[#{c}\]"
        {_,false,_}    -> "\[#{c} ...\]"
      end end))
      <> IO.ANSI.reset()
    { resTemplate,data }
  end
  @doc"""
  Demo exit point for Cli (implement these with cleanup like node disconnect handling, config saving, etc...)
  """
  def exitCli() do
    Cli.detail "cleaning up before quitting CLI"
    0
  end
  @doc"""
  Demo function ran without capturing input
  """
  def foo() do
    Cli.detail "Ran foo"
    nil
  end
  @doc """
  Demo function for captured input operations
  """
  def captured({_,_,[head|_]}) do
    Cli.detail "Ran captured with: " <> head
    nil
  end
  @doc """
  Prompts the user for more args to match up with current ctx's children
  """
  def prompt({ctx,i,c},extra\\nil,is_start\\false) do
    # Cli.info "\nWhat is your command? (append with arg #{IO.ANSI.blue()}help#{IO.ANSI.reset()} to see options) "
    # for k <- (ctx |> Map.get(:c,%{}) |> Map.keys) do
    #    "\t" <> IO.ANSI.blue() <> (case k do
    #     :"" -> "<input>"
    #     _ -> k |> Atom.to_string
    #   end) <> IO.ANSI.reset() <> " => " <> (ctx |> Map.get(:c) |> Map.get(k) |> Map.get(:i,"No information")) |> Cli.info
    # end
    # extra.()
    # input = IO.gets(
    #   case (Node.self()) do
    #   :nonode@nohost -> ""
    #   s ->
    #     (s |> Atom.to_string()) <> case Agent.get(:group, & &1) do
    #     nil -> ""
    #     g -> " - " <> g
    #     end
    #   end <> "> ")
    action   = ctx |> Map.get(:a, fn _ -> nil end)
    children = ctx |> Map.get(:c, %{}) |> Map.keys
    params   = ctx |> Map.get(:p, %{})
    {pt,pd} = Command.commandContinuations(is_nil(action) or is_binary(action),children,params)
    case {Log.detail(Log.new(), pt, pd, "commandContinuations"), is_struct(extra)} do
      {l,true} -> l |> Log.push(extra)
      {l,_}    -> l
    end |> Log.flush

    prompt = case {Node.self(),is_start} do
      {_, false} -> "..."
      {:nonode@nohost,_} -> ""
      {s,_} ->
        (s |> Atom.to_string()) <> case Agent.get(:group, & &1) do
        nil -> ""
        g -> " - " <> g
        end
      end <> "> "
    input = IO.gets(prompt) |> String.trim
    if is_start and input == "" do
      nil
    else
      {ctx,i ++ (input |> Command.inputSplitter),c}
    end
  end
  def inputSplitter(input) do
    {_,hold,res} = input |> String.split("") |> List.foldr({nil,[],[]}, fn ele,{capture,hold,res} ->
      case ele do
        "" ->
          {capture,hold,res}
        " " ->
          if ! is_nil(capture) do
            {capture,[ele|hold],res}
          else
            {capture,[],[hold |> Enum.join("")] ++ res}
          end
        g when g in ["\"","\'"] ->
          if is_nil(capture) do
            {g,[hold],res}
          else
            if g == capture do
              {nil,[],[[hold]|> Enum.join("")|res]}
            else
              {capture,[ele|hold],res}
            end
          end
        _ ->
          {capture,[ele|hold],res}
      end
    end)
    [hold |> Enum.join("")] ++ res
  end
  @doc """
  Inform the user of the bad arg, expected args, and returns to Cli start
  """
  def badArg(ctx, arg\\"") do
    {template,data} = ctx
    |> Map.get(:c,%{})
    |> Map.keys
    |> List.foldr({"",[]}, fn ele,{t,d} ->
      {
        t <> "\n  #{Log.dataHold} => #{Log.dataHold}",
        [ case ele do
            :"" -> "<input>"
            _ -> ele |> Atom.to_string
          end,
          ctx |> Map.get(:c, %{}) |> Map.get(ele) |> Map.get(:i,"No information")
        | d]
      }
    end
    )
    Log.error(
      nil,
      "Bad argument provided: #{Log.dataHold}\nExpected:" <> template,
      [arg|data],
      "badArg"
    )
  end
end

defmodule Cli do
  @doc "type something"
  @deprecated "Try using Log.Info and the Log modules instead"
  def info(input) do
    Log.flush Log.new [Log.Info.new(nil,input)]
    nil
  end
  @doc ""
  @deprecated "Try using Log.Detail and the Log modules instead"
  def detail(input) do
    Log.flush Log.new [Log.Detail.new(nil,input)]
    nil
  end
  @doc ""
  @deprecated "Try using Log.Warning and the Log modules instead"
  def warning(input) do
    Log.flush Log.new [Log.Warning.new(nil,input)]
    nil
  end
  @doc ""
  @deprecated "Try using Log.Error and the Log modules instead"
  def error(input) do
    Log.flush Log.new [Log.Error.new(nil,input)]
    nil
  end
  # k: %{i: nil, a: nil, c:%{}}
  def ctree() do
  %{
    i: "Cli - append commands with \'help --recursive\' to explore all possible continuations, or \'-\' to cancel currently inputed command ",
    a: nil,
    c: %{
      exit: %{
        i: "Exit the cli",
        a: fn _ -> Command.exitCli() end
      },
      msg: %{
        i: "Broadcast a message to all connected nodes",
        a: fn opts -> Naas.broadcastMessage(opts |> Map.get("",[]) |> Enum.join(" ")) end,
        p: %{
          "" => "Message to be broadcasted"
        }
      },
      config: %{
        i: "Configure stuff",
        a: nil,
        c: %{
          node_address:  %{
            i: "Address of self node used when connecting with other nodes",
            a:  fn _ ->  Naas.setConfig("address",nil) end,
            c:  %{
              "": %{
                i: "String in the form of <name>@<ip address>",
                a: fn {_,_,[v|_]} -> Naas.setConfig("address",v) end
              }
            }
          },
          node_cookie:  %{
            i: "Default secret node cookie used when connecting to nodes with the same cookie",
            a:  fn _ -> Naas.setConfig("cookie",nil) end,
            c:  %{
              "": %{
                i: "String",
                a: fn {_,_,[v|_]} -> Naas.setConfig("cookie",v) end
              }
            }
          },
          all:  %{
            i: "Displays all active configs",
            a:  fn _ -> Naas.getAllConfig() end
          }
        }
      },
      start:  %{
        i: "Starts Node address and cookie defined in config, or with the arg provided",
        a: fn opts -> Naas.startNode(
          opts |> Map.get("-a",[]) |> List.first,
          opts |> Map.get("-c",[]) |> List.first)
        end,
        p: %{
          "-a" => "Address to start as, defaults to config default if not provided '-a exampleAddress@127.0.0.1'",
          "-c" => "Cookie to start with, defaults to config default if not provided '-c superSecretCookie'"
        }
      },
      connect:  %{
        i: "Connect Node to provided address or a saved group with the cookie provided by Config or the arg following",
        a: nil,
        c: %{
          group: %{
            i: "Connect to group with provided group name following",
            a: Naas.listGroup()|> Enum.join("\n"),
            c: %{
              "": %{
                i: "Input a group name from listed",
                a: fn {_,_,[c|_]} -> Naas.connectGroup(c) end
              }
            }
          },
          "": %{
            i: "Destination node address with the cookie provided by Config or the arg following",
            a: fn {_,_,[a|_]} -> Naas.connectNode(a);nil end,
            c: %{
              "": %{
                i: "Cookie override",
                a: fn {_,_,[c,a|_]} -> Naas.connectNode(a,c);nil end
              }
            }
          }
        }
      },
      list: %{
        i: "List all nodes connected to",
        a: fn _ -> Naas.networkInfo() |> Log.flush;nil end
      },
      group: %{
        i: "List all addresses stored in group",
        a: Log.Info.new(
          "availableGroups",
          "Available groups:#{Naas.listGroup() |> Enum.map(fn _ -> "\n  #{Log.dataHold}" end) |> Enum.join}",
          Naas.listGroup()
        ),
        c: %{
          make: %{
            i: "Add or create a new group with a name. Copies data from the group you are in but not added yet",
            a: nil,
            c: %{
              "": %{
                i: "Name of group",
                a: fn {_,_,[n|_]} -> Naas.makeGroup(n) end,
              },
            }
          },
          status: %{
            i: "Shows information about the group you are in",
            a: fn _ -> Naas.groupStatus() |> Log.flush end
          },
          add: %{
            i: "Adds all nodes currently connected or provided address arg to the group currently in or provided arg",
            a: nil,
            c: %{
              "": %{
                i: "Address to be added to group",
                a: fn {_,_,[a|_]} -> Naas.addGroup(a) end,
                c: %{
                  "": %{
                    i: "Group to add to",
                    a: fn {_,_,[g,a|_]} -> Naas.addGroup(a,g) end
                  }
                }
              }
            }
          },
          sync: %{
            i: "Collects all other connections from other nodes in this group",
            a: fn _ -> Naas.syncGroupConnection() end
          },
          role: %{
            i: "Changes your current role in the group",
            a: nil,
            c: %{
              online: %{
                i: "Collects all other connections from other nodes in this group",
                a: fn _ -> Naas.setRole(:online) end
              },
              host: %{
                i: "Collects all other connections from other nodes in this group",
                a: fn _ -> Naas.setRole(:host) end
              },
              central: %{
                i: "Collects all other connections from other nodes in this group",
                a: fn _ -> Naas.setRole(:central) end
              },
            }
          },
          server: %{
            i: "Installs a server to this group",
            a: nil,
            c: %{
              java: %{
                i: "Install a Java server",
                a: Log.Info.new(
                  "availableVersions",
                  "Available versions:#{Mj.availableVersions("java") |> Map.keys() |> Enum.map(fn _ -> "\n  #{Log.dataHold}" end) |> Enum.join}",
                  Mj.availableVersions("java") |> Map.keys()
                ),
                c: %{
                  "": %{
                    i: "Version number",
                    a: fn {_,_,[v|_]} -> Mj.withInstall("java",v);nil end
                  }
                }
              },
              bedrock: %{
                i: "Install a Bedrock server",
                a: Log.Info.new(
                  "availableVersions",
                  "Available versions:#{Mj.availableVersions("bedrock") |> Enum.map(fn _ -> "\n  #{Log.dataHold}" end) |> Enum.join}",
                  Mj.availableVersions("bedrock")
                ),
                c: %{
                  "": %{
                    i: "Version number",
                    a: fn {_,_,[v|_]} ->  Mj.withInstall("bedrock",v);nil end
                  }
                }
              },
            }
          },
        },
      },
      disconnect: %{
        i: "Disconnects fromm current Node network",
        a: fn _ -> Naas.disconnectNode() end
      },
      stop: %{
        i: "Stops node",
        a: fn _ -> Naas.stopNode() end
      }
    }
  }
  end
  def tree_traverser({ctx,input_list,cached},is_start \\ false, from_cli \\ true) do
    cList = ctx |> Map.get(:c, %{}) |> Map.keys |> Enum.map(fn k -> k |> Atom.to_string end)
    pList = ctx |> Map.get(:p, %{})
    action= ctx |> Map.get(:a, fn _ -> nil end)
    case {input_list, pList == %{}, action,from_cli} do
    {_,false,_,_} ->
      Command.arbitraryArg({ctx,input_list,cached})
      nil
    {[],true,a,true} when is_nil(a) or not is_function(a) ->
      Command.prompt({ctx,input_list,cached},a,is_start)
    {[],true,a,false} when is_nil(a) or not is_function(a) ->
      1
    {[],true,a,_} ->
      a.({ctx,input_list,cached})
    {[head | tail],_,_,_} -> (
      case {head == "-", head == "help", head in cList, "" in cList} do
      {true,_,_,_} ->
        nil
      {_,true,_,_} ->
        Command.help((tail |> List.first(nil)) in ["-r","--recursive"],ctx); nil
      {_,_,true, _} ->
        { ctx |> Map.get(:c, %{}) |> Map.get(head |> String.to_existing_atom, %{}),
          tail,
          cached
        }
      {_,_,false, true} ->
        { ctx |> Map.get(:c, %{}) |> Map.get(:"",%{}),
          tail,
          [head|cached]
        }
      {_,_,false, false} ->
        Command.badArg(ctx, head);
        nil
      end
      )
    end
    |> then(fn x -> case {from_cli, x} do
    {true, 0}   -> Cli.info "\n\n\nGoodnight! ==================="; 0
    {true, nil} -> tree_traverser({ctree(),[],[]},true)
    {true, _}   -> tree_traverser(x, false)
    {false, 0}   -> nil
    {false, nil} -> nil
    {false, 1}   -> 1
    {false, _}   -> tree_traverser(x, false, false)
    end end)
  end
  def start() do
    tree_traverser({ctree(),[],[]},true,true)
    nil
  end
end

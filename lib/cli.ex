defmodule ArgPassing do
  defexception message: "bad argument passing"
end
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
    [head|tail] = h
    toScreen = [
      "\n?> #{(tail |> Enum.reverse |> Enum.map(fn e -> "#{e} " end) |> Enum.join(""))<>IO.ANSI.blue()<>IO.ANSI.underline()<>head<>IO.ANSI.reset()
      <> " "
      <> Command.commandContinuations(is_nil(action) or is_binary(action),children,params)
      }",
      "i: #{ info }"
    ] ++ (params |> Map.keys |> List.foldl([], fn ele,acc ->
      acc ++ ["   #{ele} => #{Map.get(params,ele,"")}"]
    end))

    Cli.info toScreen |> Enum.join("\n")

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
    IO.ANSI.color(2,2,2)
    <>( children
    |> Enum.map(fn ele -> if ele == :"" do "<input>" else ele |> Atom.to_string end end)
    |> Enum.join("|")
    |> then(fn c -> if !required and c != "" do "\[#{c}\]" else c end end)
    )
    <> (params
    |> Map.keys
    |> Enum.join("|")
    |> then(fn p -> if p != "" do "\[#{p} ...\]" else p end end))
    <> IO.ANSI.reset()
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
    Cli.info Command.commandContinuations(is_nil(action) or is_binary(action),children,params) <> (if extra != nil do "\n#{extra}" else "" end)
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
    Cli.error(
      "Bad argument provided: #{arg}\n" <>
      (
        ctx
        |> Map.get(:c,%{})
        |> Map.keys
        |> List.foldl( "Expected:", fn ele,acc ->
          acc <> "\n" <> case ele do
          :"" -> "<input>"
          _ -> ele |> Atom.to_string
          end <> " => " <> (ctx |> Map.get(:c, %{}) |> Map.get(ele) |> Map.get(:i,"No information"))
        end
        )
      )
    )
  end
end

defmodule Cli do
  def info(input) do
    logLevel = case Naas.getConfig("logLevel") do
      nil -> ["info"]
      a -> a
    end
    case {Agent.get(:interactive_output, & &1),"info" in logLevel} do
    {true,true} ->
      try do
        IO.puts input
      rescue
        _ -> nil
      end
    {false,true} ->
      try do
      IO.puts %{type: "info", data: input} |> JSON.encode!
      rescue
        _ -> nil
      end
    _ -> nil
    end
  end
  def detail(input) do
    logLevel = case Naas.getConfig("logLevel") do
      nil -> ["detail"]
      a -> a
    end
    case {Agent.get(:interactive_output, & &1),"detail" in logLevel} do
    {true,true} ->
      try do
        IO.puts "#{IO.ANSI.color(2,2,2)}#{input}#{IO.ANSI.reset()}"
      rescue
        _ -> nil
      end
    {false,true} ->
      try do
      IO.puts %{type: "log", data: input} |> JSON.encode!
      rescue
        _ -> nil
      end
    _ -> nil
    end
  end
  def warning(input) do
    logLevel = case Naas.getConfig("logLevel") do
      nil -> ["warning"]
      a -> a
    end
    case {Agent.get(:interactive_output, & &1),"warning" in logLevel} do
    {true,true} ->
      try do
        IO.puts "#{IO.ANSI.yellow()}Warning:#{IO.ANSI.reset()} #{input}"
      rescue
        _ -> nil
      end
    {false,true} ->
      try do
      IO.puts %{type: "warning", data: input} |> JSON.encode!
      rescue
        _ -> nil
      end
    _ -> nil
    end
  end
  def error(input) do
    case Agent.get(:interactive_output, & &1) do
    true ->
      try do
        IO.puts "#{IO.ANSI.red()}Error:#{IO.ANSI.reset()} #{input}"
      rescue
        _ -> nil
      end
    false ->
      try do
        IO.puts %{type: "error", data: input} |> JSON.encode!
      rescue
        _ -> nil
      end
    end
  end
  # k: %{i: nil, a: nil, c:%{}}
  def ctree() do
  %{
    i: "Cli - append commands with \'help --recursive\' to explore all possible continuations",
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
        a: fn _ -> Naas.networkInfo();nil end
      },
      group: %{
        i: "List all addresses stored in group",
        a: fn _ -> Cli.info "\n Available groups:"; Cli.info Naas.listGroup() ;nil end,
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
            a: fn _ -> Naas.groupStatus() end
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
                a: "Available versions:\n#{Mj.availableVersions("java") |> Map.keys() |> Enum.join("\n")}",
                c: %{
                  "": %{
                    i: "Version number",
                    a: fn {_,_,[v|_]} -> Mj.withInstall("java",v);nil end
                  }
                }
              },
              bedrock: %{
                i: "Install a Bedrock server",
                a: "Available versions:\n#{Mj.availableVersions("bedrock") |> Enum.join("\n")}",
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
  def tree_traverser({ctx,input_list,cached},is_start \\ false) do
    cList = ctx |> Map.get(:c, %{}) |> Map.keys |> Enum.map(fn k -> k |> Atom.to_string end)
    pList = ctx |> Map.get(:p, %{})
    action= ctx |> Map.get(:a, fn _ -> nil end)
    case {input_list, pList == %{}, action} do
    {_,false,_} ->
      Command.arbitraryArg({ctx,input_list,cached})
      nil
    {[],true,a} when is_nil(a) or is_binary(a) ->
      Command.prompt({ctx,input_list,cached},a,is_start)
    {[],true,a} ->
      a.({ctx,input_list,cached})
    {[head | tail],_,_} -> (
      case {head == "help", head in cList, "" in cList} do
      {true,_,_} ->
        Command.help((tail |> List.first(nil)) in ["-r","--recursive"],ctx); nil
      {_,true, _} ->
        { ctx |> Map.get(:c, %{}) |> Map.get(head |> String.to_existing_atom, %{}),
          tail,
          cached
        }
      {_,false, true} ->
        { ctx |> Map.get(:c, %{}) |> Map.get(:"",%{}),
          tail,
          [head|cached]
        }
      {_,false, false} ->
        Command.badArg(ctx, head);
        nil
      end
      )
    end
    |> then(fn x -> case x do
    0 -> Cli.info "\n\n\nGoodnight! ==================="; 0
    nil -> tree_traverser({ctree(),[],[]},true)
    _ -> x |> tree_traverser
    end end)
  end
  def start() do
    tree_traverser({ctree(),[],[]},true)
    nil
  end
end

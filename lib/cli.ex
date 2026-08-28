defmodule ArgPassing do
  defexception message: "bad argument passing"
end
defmodule Command do
  @doc"""
  kinda like real cli argument passing
  """
  def arbitraryArg({ctx,inputs,_}) do
    inputParser = fn argsList ->
      {_,res} = inputs
      |> Enum.reverse
      |> List.foldl({[],%{}}, fn ele,{hold,ret} ->
        if ele not in argsList do
          {[ele|hold],ret}
        else
          Cli.toScreen("Parsed: #{ele} => [#{Enum.join(hold,", ")}]")
          {[],ret|> Map.put_new(ele,hold)}
        end
      end)
      res
    end

    callback = ctx |> Map.get(:a, fn _ -> Cli.error "no action found" end)
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
  def help(h,ctx) do
    info = ctx |> Map.get(:i, "NO INFORMATION")
    children = ctx |> Map.get(:c, %{}) |> Map.keys
    params   = ctx |> Map.get(:p, %{})
    Cli.toScreen "i: " <> info
    Cli.toScreen "c: " <> (
      children
      |> Enum.map(fn ele ->
        case ele do
        :"" -> "<input>"
        _ -> ele |> Atom.to_string
        end
      end)
      |> Enum.join(" | ")
    )
    Cli.toScreen "p: " <> (
      params
      |> Map.keys
      |> Enum.join(" | ")
    )
    for c <- children do
      command = case c do
        :"" ->  "<input>"
        _ ->  (c |> Atom.to_string)
      end
      Cli.toScreen "\n?> " <> (h |> List.foldl("",fn ele,acc-> ele <> " " <> acc end)) <> IO.ANSI.blue() <> IO.ANSI.underline() <> command <> IO.ANSI.reset()
      help([command|h],ctx |> Map.get(:c,%{}) |> Map.get(c,%{}))
    end
    for p <- (params |> Map.keys) do
      Cli.toScreen "   " <> IO.ANSI.green() <> IO.ANSI.underline() <> p <> IO.ANSI.reset() <> " " <> Map.get(params,p,"")
    end
  end
  @doc"""
  Demo exit point for Cli (implement these with cleanup like node disconnect handling, config saving, etc...)
  """
  def exitCli() do
    Cli.toScreen "cleaning up before quitting CLI"
    0
  end
  @doc"""
  Demo function ran without capturing input
  """
  def foo() do
    Cli.toScreen "Ran foo"
    nil
  end
  @doc """
  Demo function for captured input operations
  """
  def captured({_,_,[head|_]}) do
    Cli.toScreen "Ran captured with: " <> head
    nil
  end
  @doc """
  Prompts the user for more args to match up with current ctx's children
  """
  def prompt({ctx,i,c},extra\\fn -> nil end) do
    Cli.toScreen "\nWhat is your command? (append with arg #{IO.ANSI.blue()}help#{IO.ANSI.reset()} to see options) "
    for k <- (ctx |> Map.get(:c,%{}) |> Map.keys) do
       "\t" <> IO.ANSI.blue() <> (case k do
        :"" -> "<input>"
        _ -> k |> Atom.to_string
      end) <> IO.ANSI.reset() <> " => " <> (ctx |> Map.get(:c) |> Map.get(k) |> Map.get(:i,"No information")) |> Cli.toScreen
    end
    extra.()
    input = IO.gets(
      case (Node.self()) do
      :nonode@nohost -> ""
      s ->
        (s |> Atom.to_string()) <> case Agent.get(:group, & &1) do
        nil -> ""
        g -> " - " <> g
        end
      end <> "> ")
    {ctx,i ++ ( input |> String.trim |> String.split),c}
  end
  @spec badArg(map(), any()) :: nil | :ok
  @doc """
  Inform the user of the bad arg, expected args, and returns to Cli start
  """
  def badArg(ctx, arg\\"") do
    Cli.error(
      "bad argument provided: #{arg}\n" <>
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
  def toScreen(input) do
    case Agent.get(:interactive_output, & &1) do
    true ->
      try do
        IO.puts input
      rescue
        _ -> nil
      end
    false ->
      try do
      IO.puts %{type: "log", data: input} |> JSON.encode!
      rescue
        _ -> nil
      end
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
    i: "Command info",
    a: fn a -> Command.prompt(a) end,
    c: %{
      exit: %{
        i: "Exit the cli",
        a: fn _ -> Command.exitCli() end
      },
      config: %{
        i: "Configure stuff",
        a: fn a -> Command.prompt(a) end,
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
        a: fn a -> Command.prompt(a) end,
        c: %{
          group: %{
            i: "Connect to group with provided group name following",
            a: fn a -> Command.prompt(a, fn -> Cli.toScreen Naas.listGroup() end) end,
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
        a: fn _ -> Cli.toScreen "\n Available groups:"; Cli.toScreen Naas.listGroup() ;nil end,
        c: %{
          make: %{
            i: "Add or create a new group with a name. Copies data from the group you are in but not added yet",
            a: fn a -> Command.prompt(a) end,
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
            a: fn a -> Command.prompt(a) end,
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
            a: fn a -> Command.prompt(a) end,
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
            a: fn a -> Command.prompt(a) end,
            c: %{
              java: %{
                i: "Install a Java server",
                a: fn a -> Command.prompt(a, fn ->
                  Cli.toScreen "Available versions:"
                  Cli.toScreen Mj.availableVersions("java")|> Map.keys() |> Enum.join("\n")
                end) end,
                c: %{
                  "": %{
                    i: "Version number",
                    a: fn {_,_,[v|_]} -> Mj.withInstall("java",v);nil end
                  }
                }
              },
              bedrock: %{
                i: "Install a Bedrock server",
                a: fn a -> Command.prompt(a, fn ->
                  Cli.toScreen "Available versions:"
                  Cli.toScreen Mj.availableVersions("bedrock") |> Enum.join("\n")
                end) end,
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
  def tree_traverser({ctx,input_list,cached}) do
    cList = ctx |> Map.get(:c, %{}) |> Map.keys |> Enum.map(fn k -> k |> Atom.to_string end)
    pList = ctx |> Map.get(:p, %{})
    case {input_list, pList == %{}} do
    {_,false} ->
      Command.arbitraryArg({ctx,input_list,cached})
      nil
    {[],true} ->
      (ctx |> Map.get(:a)).({ctx,input_list,cached})
    {[head | tail],_} -> (
      case {head == "help", head in cList, "" in cList} do
      {true,_,_} ->
        Command.help([],ctx); nil
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
        Command.badArg(ctx, head)
        start()
      end
      )
    end
    |> then(fn x -> case x do
    0 -> Cli.toScreen "\n\n\nGoodnight! ==================="; 0
    nil -> {ctree(),[],[]} |> tree_traverser
    _ -> x |> tree_traverser
    end end)
  end
  def start() do
    tree_traverser({ctree(),[],[]})
    nil
  end
end

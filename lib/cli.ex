defmodule Command do
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
    children = ctx |> Map.get(:c,%{}) |> Map.keys

    Cli.toScreen "i: " <> info
    Cli.toScreen "c: " <> (
        children
        |> List.foldl("", fn ele, acc ->
          acc <> " | " <> (
            case ele do
              :"" -> "<input>"
              _ -> ele |> Atom.to_string
            end
          )
        end)
      )
    for c <- children do
      command = (case c do
        :"" ->  "<input>"
        _ ->  (c |> Atom.to_string)
      end)
      Cli.toScreen "\n?> " <> (h |> List.foldl("",fn ele,acc-> ele <> " " <> acc end)) <> IO.ANSI.blue() <> IO.ANSI.underline() <> command <> IO.ANSI.reset()
      help([command|h],ctx |> Map.get(:c,%{}) |> Map.get(c,%{}))
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
        s -> s |> Atom.to_string()
      end <> "> ")
    {ctx,i ++ ( input |> String.trim |> String.split),c}
  end
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
      IO.puts input
    false ->
      IO.puts %{type: "log", data: input} |> JSON.encode!
    end
  end
  def error(input) do
    case Agent.get(:interactive_output, & &1) do
    true ->
      IO.puts "#{IO.ANSI.red()}Error:#{IO.ANSI.reset()} #{input}"
    false ->
      IO.puts %{type: "error", data: input} |> JSON.encode!
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
        i: "Starts Node address and cookie defined in config, or with the arg provided after it",
        a: fn _ -> Naas.startNode() end,
        c: %{
          "": %{
            i: "Captured address for Node starting",
            a: fn {_,_,[a|_]} -> Naas.startNode(a) end,
            c: %{
              "": %{
                i: "Captured cookie for Node starting",
                a: fn {_,_,[c,a|_]} -> Naas.startNode(a,c) end
              }
            }
          }
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
            i: "Create a new group with provided name and default cookie or provided arg",
            a: fn a -> Command.prompt(a) end,
            c: %{
              "": %{
                i: "Name of group",
                a: fn {_,_,[n|_]} -> Naas.makeGroup(n) end,
                c: %{
                  "": %{
                    i: "Cookie of group",
                    a: fn {_,_,[c,n|_]} -> Naas.makeGroup(n,c) end
                  },
                }
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
    case input_list do
      [] ->
        (ctx |> Map.get(:a)).({ctx,input_list,cached})
      [head | tail] -> (
        cList = ctx |> Map.get(:c, %{}) |> Map.keys |> Enum.map(fn k -> k |> Atom.to_string end)
        case {head == "help", head in cList, "" in cList} do
          {true,_,_} -> Command.help([],ctx); nil
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
    0 -> Cli.toScreen "\n\n\nGoodnight! ==================="
    nil -> {ctree(),[],[]} |> tree_traverser
    _ -> x |> tree_traverser
    end end)
  end
  def start() do
    tree_traverser({ctree(),[],[]})
    nil
  end
end

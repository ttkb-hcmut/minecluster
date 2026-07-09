defmodule Command do
  @doc"""
  Demo printing all possible continuations from an inputed command
  """
  def help(h,ctx) do
    info = ctx |> Map.get(:i, "NO INFORMATION")
    children = ctx |> Map.get(:c,%{}) |> Map.keys

    IO.puts "i: " <> info
    IO.puts "c: " <> (
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
      IO.puts "\n?> " <> (h |> List.foldl("",fn ele,acc-> ele <> " " <> acc end)) <> IO.ANSI.blue() <> IO.ANSI.underline() <> command <> IO.ANSI.reset()
      help([command|h],ctx |> Map.get(:c,%{}) |> Map.get(c,%{}))
    end
  end
  @doc"""
  Demo exit point for Cli (implement these with cleanup like node disconnect handling, config saving, etc...)
  """
  def exitCli() do
    IO.puts "cleaning up before quitting CLI"
    0
  end
  @doc"""
  Demo function ran without capturing input
  """
  def foo() do
    IO.puts "Ran foo"
    nil
  end
  @doc """
  Demo function for captured input operations
  """
  def captured({_,_,[head|_]}) do
    IO.puts "Ran captured with: " <> head
    nil
  end
  @doc """
  Prompts the user for more args to match up with current ctx's children
  """
  def prompt({ctx,i,c}) do
    IO.puts "\nWhat is your command? (append with arg #{IO.ANSI.blue()}help#{IO.ANSI.reset()} to see options) "
    for k <- (ctx |> Map.get(:c,%{}) |> Map.keys) do
       "\t" <> IO.ANSI.blue() <> (case k do
        :"" -> "<input>"
        _ -> k |> Atom.to_string
      end) <> IO.ANSI.reset() <> " => " <> (ctx |> Map.get(:c) |> Map.get(k) |> Map.get(:i,"No information")) |> IO.puts
    end
    input = IO.gets("> ")
    {ctx,i ++ ( input |> String.trim |> String.split),c}
  end
  @doc """
  Inform the user of the bad arg, expected args, and returns to Cli start
  """
  def badArg(ctx, arg\\"") do
    IO.puts "#{IO.ANSI.red()}Error:#{IO.ANSI.red()} bad argument provided: " <> arg
    IO.puts "Expected:"
    for k <- (ctx |> Map.get(:c,%{}) |> Map.keys) do
       "\t" <> (case k do
        :"" -> "<input>"
        _ -> k |> Atom.to_string
      end) <> " => " <> (ctx |> Map.get(:c, %{}) |> Map.get(k) |> Map.get(:i,"No information")) |> IO.puts
    end
  end
end

defmodule Cli do
  def ctree() do
  %{
    i: "Command info",
    a: fn a -> Command.prompt(a) end,
    c: %{
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
      node:  %{
        i: "Node commands",
        a: fn a -> Command.prompt(a) end,
        c: %{
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
            i: "Connect Node to the saved group or address with the cookie provided by Config or the arg following",
            a: fn a -> Command.prompt(a) end,
            c: %{
              group: %{
                i: "Try all nodes in group with the cookie provided by Config or the arg following",
                a: fn _ -> Naas.connectGroup() end,
                c: %{
                  "": %{
                    i: "Cookie override",
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
          add_group: %{
            i: "Adds all nodes currently connected to the group for when connecting node to group, Node must have already been started",
            a: fn _ -> Naas.addGroup() end
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
      },
      exit: %{
        i: "Exit the cli",
        a: fn _ -> Command.exitCli() end
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
    0 -> IO.puts "\n\n\nGoodnight! ==================="
    nil -> {ctree(),[],[]} |> tree_traverser
    _ -> x |> tree_traverser
    end end)
  end
  def start() do
    tree_traverser({ctree(),[],[]})
    nil
  end
end

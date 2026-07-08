defmodule Command do
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
    IO.puts "\nWhat is your command? "
    for k <- (ctx |> Map.get(:c,%{}) |> Map.keys) do
       "\t" <> (case k do
        :"" -> "<input>"
        _ -> k |> Atom.to_string
      end) <> " => " <> (ctx |> Map.get(:c) |> Map.get(k) |> Map.get(:i,"No information")) |> IO.puts
    end
    input = IO.gets("> ")
    {ctx,i ++ ( input |> String.trim |> String.split),c}
  end
  @doc """
  Inform the user of the bad arg, expected args, and returns to Cli start
  """
  def badArg(ctx, arg\\"") do
    IO.puts "Bad argument provided: " <> arg
    IO.puts "Expected:"
    for k <- (ctx |> Map.get(:c,%{}) |> Map.keys) do
       "\t" <> (case k do
        :"" -> "<input>"
        _ -> k |> Atom.to_string
      end) <> " => " <> (ctx |> Map.get(:c) |> Map.get(k) |> Map.get(:i,"No information")) |> IO.puts
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
          address:  %{
            i: "Address of self",
            a:  fn a -> Command.prompt(a) end,
            c:  %{
              "": %{
                i: "Value",
                a: fn a -> Command.captured(a) end,
                c: %{}
              }
            }
          }
        }
      },
      node:  %{
        i: "Node commands",
        a: fn a -> Command.prompt(a) end,
        c: %{
          start:  %{i: "Starts Node address defined in config",
                    a: fn _ -> Command.foo() end,
                    c: %{}
                  }
        }
      },
      connect_to_group:   %{i: "capturing command arg",
              a:  fn a -> Command.captured(a) end
            },
      exit: %{i: "exit the cli",
              a:  fn _ -> Command.exitCli() end
            }
    }
  }
  end
  def tree_visitor({ctx,input_list,cached}) do
    case input_list do
      [] ->
        (ctx |> Map.get(:a)).({ctx,input_list,cached})
      [head | tail] -> (
        cList = ctx |> Map.get(:c, %{}) |> Map.keys |> Enum.map(fn k -> k |> Atom.to_string end)
        case {head in cList, "" in cList} do
          {true, _} ->
            { ctx |> Map.get(:c, %{}) |> Map.get(head |> String.to_existing_atom, %{}),
              tail,
              cached
            }
          {false, true} ->
            { ctx |> Map.get(:c, %{}) |> Map.get(:"",%{}),
              tail,
              [head|cached]
            }
          {false, false} ->
            Command.badArg(ctx, head)
            start()
        end
        )
    end
    |> then(fn x -> case x do
    0 -> IO.puts "\n\n\nGoodnight! ==================="
    nil -> {ctree(),[],[]} |> tree_visitor
    _ -> x |> tree_visitor
    end end)
  end
  def start() do
    tree_visitor({ctree(),[],[]})
    nil
  end
end

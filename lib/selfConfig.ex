
defmodule SelfConfig do
  def get(k\\nil) do
    Agent.get(:config, & &1)
    |> then(fn c -> case k do
    nil -> c
    _ -> c |> Map.get(k,nil)
    end end)
  end

  def getDisplayConfig() do
    map = SelfConfig.get()
    map |> Map.keys |> List.foldl(Log.new(),fn k,acc ->
      {template,data} = if map[k] |> is_list do
        {
          IO.ANSI.blue() <> Log.dataHold <> IO.ANSI.reset() <> ":" <>
          (map[k] |> List.foldl("",fn _,acc -> acc <> " " <> Log.dataHold end)),
          [k | map[k]]
        }
      else
        {
          IO.ANSI.blue() <> Log.dataHold <> IO.ANSI.reset() <> ": ",
          [k, map[k]]
        }
      end
      acc |> Log.info("All stored configs:\n" <> template,data)
    end) |> Log.flush
    nil
  end

  def set(k\\nil,v\\nil) do
    case {k,v} do
    {nil,_} ->
      Agent.update(:config, fn _ -> v end)
    {_,nil} ->
      Agent.update(:config, fn c -> c |> Map.delete(k) end)
    {_,_} ->
      Agent.update(:config, fn c -> c |> Map.put(k,v) end)
    end
    File.write(".config", SelfConfig.get() |> JSON.encode!)
    nil
  end
end

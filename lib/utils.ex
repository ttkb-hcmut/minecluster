defmodule Utils do
  def inParallel(list,fun) do
    list
    |> List.foldl([], fn ele, acc -> [Task.async(fn -> fun.(ele) end)|acc]
    end)
    |> Task.yield_many(on_timeout: :kill_task, timeout: 5000)
    |> List.foldl([], fn {_,{_,ele}},acc -> [ele|acc] end)
  end

  def secretGen() do
    DateTime.utc_now(:microsecond, Calendar.ISO)
    |> DateTime.to_string
    |> then(fn t -> :crypto.hash(:sha256, t) end)
    |> Base.encode32
  end
end

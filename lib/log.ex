defmodule Log do
  defstruct [list: []]
  def new(list\\[]) do
    %Log{list: list}
  end
  def dataHold() do
    "^"
  end

  defmodule Info do
    defstruct [id: nil, template: "", data: []]
    def new(id \\ nil, template \\  "" , data \\ []) do
      %Info{ id: id, template: template, data: data}
    end
    def toCli(self \\ %Log.Info{}) do
      self |> Log.cliZipper
    end
    def toGui(self \\ %Log.Info{}) do
      self |> Log.guiDataFormat("info")
    end
  end
  defmodule Detail do
    defstruct [id: nil, template: "", data: []]
    def new(id \\ nil, template \\  "" , data \\ []) do
      %Detail{ id: id, template: template, data: data}
    end
    def toCli(self \\ %Log.Detail{}) do
      %{self | template: "#{IO.ANSI.color(2,2,2)}#{self.template}#{IO.ANSI.reset()}"}
      |> Log.cliZipper
    end
    def toGui(self \\ %Log.Detail{}) do
      self |> Log.guiDataFormat("error")
    end
  end
  defmodule Warning do
    defstruct [id: nil, template: "", data: []]
    def new(id \\ nil, template \\  "" , data \\ []) do
      %Warning{ id: id, template: template, data: data}
    end
    def toCli(self \\ %Log.Warning{}) do
      %{self | template: "#{IO.ANSI.yellow()}Warning:#{IO.ANSI.reset()} #{self.template}"}
      |> Log.cliZipper
    end
    def toGui(self \\ %Log.Warning{}) do
      self |> Log.guiDataFormat("error")
    end
  end
  defmodule Error do
    defstruct [id: nil,template: "", data: [] ]
    def new(id \\ nil, template \\  "" , data \\ []) do
      %Error{ id: id, template: template, data: data}
    end
    def toCli(self \\ %Log.Error{}) do
      %{self | template: "#{IO.ANSI.red()}Error:#{IO.ANSI.reset()} #{self.template}"}
      |> Log.cliZipper
    end
    def toGui(self \\ %Log.Error{}) do
      self |> Log.guiDataFormat("error")
    end
  end

  def cliZipper(input \\ %Log.Info{}) do
    {_,res} = input.template
    |> String.split(Log.dataHold())
    |> List.foldl({input.data,[]},fn ele, {data,res} ->
      case data do
        [head|tail] ->
          {tail, [head,ele|res]}
        [] ->
          {[], [ele|res]}
      end
    end)
    res |> Enum.reverse |> Enum.join("")
  end
  def guiDataFormat(input \\ %Log.Info{},type \\ "info") do
    %{input.id => %{type => input.data}}
  end
  def logLevel(check \\ nil) do
    case {Naas.getConfig("logLevel"),check} do
      {_,nil} -> false
      {nil,_} -> check in ["info","detail","warning","error"]
      {a,_}   -> check in a
    end
  end
  def info(loglist \\ nil, template,data \\ [],id\\nil) do
    case is_nil(loglist) do
      true -> Log.new([Log.Info.new(id,template,data)]) |> Log.flush; nil
      _    -> loglist |> Log.push(Log.Info.new(id,template,data))
    end
  end
  def detail(loglist\\ nil, template,data \\ [],id\\nil) do
    case {is_nil(loglist),Log.logLevel("detail")} do
      {true, true} -> Log.new([Log.Detail.new(id,template,data)]) |> Log.flush; nil
      {_, true}    -> loglist |> Log.push(Log.Detail.new(id,template,data))
      _            -> loglist
    end
  end
  def warning(loglist \\ nil, template,data \\ [],id\\nil) do
    case {is_nil(loglist),Log.logLevel("warning")} do
      {true, true} -> Log.new([Log.Warning.new(id,template,data)]) |> Log.flush; nil
      {_, true}    -> loglist |> Log.push(Log.Warning.new(id,template,data))
      _            -> loglist
    end
  end
  def error(loglist \\ nil, template,data \\ [],id\\nil) do
    case is_nil(loglist) do
      true -> Log.new([Log.Error.new(id,template,data)]) |> Log.flush; nil
      _    -> loglist |> Log.push(Log.Error.new(id,template,data))
    end
  end

  def push(self \\ %Log{}, log) do
    %{self | list: [log|self.list]}
  end
  def flush(self \\ %Log{}, toGui \\ false) do
    self.list
    |> List.foldr({%{},%{},%{},%{}}, fn l, {i,d,w,e} ->
      case l do
        %Log.Info{} ->
          l |> Log.Info.toCli |> IO.puts
          l |> Log.Info.toGui
          {_,map} =  i |> Map.get_and_update(l.id, fn v -> if is_nil(v) do {nil,l.data} else {v, v ++ l.data} end end)
          {map,d,w,e}
        %Log.Detail{} ->
          l |> Log.Detail.toCli |> IO.puts
          {_,map} =  d |> Map.get_and_update(l.id, fn v -> if is_nil(v) do {nil,l.data} else {v, v ++ l.data} end end)
          {i,map,w,e}
        %Log.Warning{} ->
          l |> Log.Warning.toCli |> IO.puts
          {_,map} =  w |> Map.get_and_update(l.id, fn v -> if is_nil(v) do {nil,l.data} else {v, v ++ l.data} end end)
          {i,d,map,e}
        %Log.Error{} ->
          l |> Log.Error.toCli |> IO.puts
          {_,map} =  e |> Map.get_and_update(l.id, fn v -> if is_nil(v) do {nil,l.data} else {v, v ++ l.data} end end)
          {i,d,w,map}
        _ ->
          IO.puts "unknown log"
          {i,d,w,e}
      end
    end)
  end
  # def detail(input) do
  #   case {Agent.get(:interactive_output, & &1),Log.logLevel("detail")} do
  #   {true,true} ->
  #     try do
  #       IO.puts "#{IO.ANSI.color(2,2,2)}#{input}#{IO.ANSI.reset()}"
  #     rescue
  #       _ -> nil
  #     end
  #   {false,true} ->
  #     try do
  #     IO.puts %{type: "log", data: input} |> JSON.encode!
  #     rescue
  #       _ -> nil
  #     end
  #   _ -> nil
  #   end
  # end
  # def warning(input) do
  #   case {Agent.get(:interactive_output, & &1),Log.logLevel("warning")} do
  #   {true,true} ->
  #     try do
  #       IO.puts "#{IO.ANSI.yellow()}Warning:#{IO.ANSI.reset()} #{input}"
  #     rescue
  #       _ -> nil
  #     end
  #   {false,true} ->
  #     try do
  #     IO.puts %{type: "warning", data: input} |> JSON.encode!
  #     rescue
  #       _ -> nil
  #     end
  #   _ -> nil
  #   end
  # end
  # def error(input) do
  #   case Agent.get(:interactive_output, & &1) do
  #   true ->
  #     try do
  #       IO.puts "#{IO.ANSI.red()}Error:#{IO.ANSI.reset()} #{input}"
  #     rescue
  #       _ -> nil
  #     end
  #   false ->
  #     try do
  #       IO.puts %{type: "error", data: input} |> JSON.encode!
  #     rescue
  #       _ -> nil
  #     end
  #   end
  # end
end

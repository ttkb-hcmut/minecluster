defmodule Log do
  defstruct [list: []]
  def new(list\\[]) do
    %Log{list: list}
  end
  def dataHold() do
    "^"
  end
  defmodule Info do
    defstruct [
      id: nil, template: "", data: [],
      toCli: &__MODULE__.toCli/1,
      lazy: nil,
      eval: &__MODULE__.eval/1
    ]
    def new(id \\ nil, template \\  "" , data \\ []) do
      %Info{ id: id, template: template, data: data}
    end
    def toCli(self \\ %Log.Info{}) do
      if not is_nil(self.lazy) do
        self
        |> self.eval.()
      else
        self
      end |> Log.cliZipper
    end
    def lazy(func) do
      %Info{lazy: func}
    end

    def eval(lazyLog) do
      Log.eval(__MODULE__,lazyLog.lazy)
    end

  end
  defmodule Detail do
    defstruct [
      id: nil, template: "", data: [],
      toCli: &__MODULE__.toCli/1,
      lazy: nil,
      eval: &__MODULE__.eval/1
    ]
    def new(id \\ nil, template \\  "" , data \\ []) do
      %Detail{ id: id, template: template, data: data}
    end
    def toCli(self \\ %Log.Detail{}) do
      if not is_nil(self.lazy) do
        self
        |> self.eval.()
      else
        %{self | template: "#{IO.ANSI.color(2,2,2)}#{self.template}#{IO.ANSI.reset()}"}
      end
      |> Log.cliZipper
    end
    def eval(func) do
      Log.eval(__MODULE__,func)
    end
  end
  defmodule Warning do
    defstruct [
      id: nil, template: "", data: [],
      toCli: &__MODULE__.toCli/1,
      lazy: nil,
      eval: &__MODULE__.eval/1
    ]
    def new(id \\ nil, template \\  "" , data \\ []) do
      %Warning{ id: id, template: template, data: data}
    end
    def toCli(self \\ %Log.Warning{}) do
      if not is_nil(self.lazy) do
        self
        |> self.eval.()
      else
        %{self | template: "#{IO.ANSI.yellow()}Warning:#{IO.ANSI.reset()} #{self.template}"}
      end
      |> Log.cliZipper
    end
    def eval(func) do
      Log.eval(__MODULE__,func)
    end
  end
  defmodule Error do
    defstruct [
      id: nil, template: "", data: [],
      toCli: &__MODULE__.toCli/1,
      lazy: nil,
      eval: &__MODULE__.eval/1
    ]
    def new(id \\ nil, template \\  "" , data \\ []) do
      %Error{ id: id, template: template, data: data}
    end
    def toCli(self \\ %Log.Error{}) do
      if not is_nil(self.lazy) do
        self
        |> self.eval.()
      else
        %{self | template: "#{IO.ANSI.red()}Error:#{IO.ANSI.reset()} #{self.template}"}
      end
      |> Log.cliZipper
    end
    def eval(func) do
      Log.eval(__MODULE__,func)
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
  def guiInfoDataFormat(input \\ %Log.Info{}) do
    if not is_nil(input.lazy) do
      input
      |> input.eval.()
      |> guiInfoDataFormat
    else
      %{input.id => input.data}
    end
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

  def eval(module \\ Log.Info,func \\ nil) do
    case func do
      nil -> module.new()
      _ ->
        try do
          {id,template,data} = func.()
          module.new(id,template,data)
        rescue
          _ ->
          module.new()
        end
    end
  end

  def push(self \\ %Log{}, log) do
    %{self | list: [log|self.list]}
  end
  def flush(self \\ %Log{}, toGui \\ false) do
    case toGui do
      true ->
        self.list
        |> List.foldl(%{},fn l, acc ->
          case l do
            %Log.Info{} ->
              Map.merge(acc, l |> Log.guiInfoDataFormat, fn _k ,u,v -> u ++ v end)
            _ ->
              acc
          end
        end)
      false ->
        self.list
        |> Enum.map(fn l ->
          l.toCli.(l) |> IO.puts
        end)
    end
  end
end

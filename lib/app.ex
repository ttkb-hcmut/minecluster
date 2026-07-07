defmodule App do
  def entry() do
    
  end


	def start(_type, _arg) do
		{:ok, pid} = App.Supervisor.start_link(:ok)
		# IO.puts ("hello world " <> PID.to_string(pid))
		IO.puts ("hello " <> (pid |> :erlang.pid_to_list |> to_string) <> "!")
		{:ok, pid}
  end
end

defmodule App.Supervisor do
  use Supervisor

  def start_link(args), do: Supervisor.start_link(__MODULE__, args, name: __MODULE__)

  @impl true
  def init(_init_arg) do
    children = [
    ]
    Supervisor.init(children, strategy: :one_for_one)
  end
end

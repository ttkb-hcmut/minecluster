defmodule App do
  def entry() do

  end

  def loop() do
    case IEx.Helpers.recompile() do
      :noop -> nil
      :ok -> IO.puts("Recompile successful!\n")
      :error -> IO.puts("Oops\n")
    end

    Process.sleep(1000)
    loop()
  end

	def start(_type, _arg) do
		{:ok, pid} = App.Supervisor.start_link(:ok)
		# IO.puts ("hello world " <> PID.to_string(pid))
		IO.puts ("hello " <> (pid |> :erlang.pid_to_list |> to_string) <> "!")
    # Cli.start()
    # {:ok, _} = Agent.start_link(fn -> IO.puts("hello from " <> (self() |> :erlang.pid_to_list |> to_string) <> "!"); loop() end)
    IO.puts("child done!")
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

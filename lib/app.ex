# alias Firebase, as: Central

defmodule App do
  def entry() do

  end

  # def loop() do
  #   case IEx.Helpers.recompile() do
  #     :noop -> nil
  #     :ok -> IO.puts("Recompile successful!\n")
  #     :error -> IO.puts("Oops\n")
  #   end

  #   Process.sleep(1000)
  #   loop()
  # end
	def start(_type, _arg) do
		App.Supervisor.start_link(:ok)
	end
end

defmodule App.Supervisor do
	use Supervisor

	def start_link(args), do: Supervisor.start_link(__MODULE__, args, name: __MODULE__)

	@impl true
	def init(_init_arg) do
		children = [
      # {Goth, name: App.Goth, source: {:service_account, System.fetch_env!("GOOGLE_KEY") |> Jason.decode!()}}
		]
		Supervisor.init(children, strategy: :one_for_one)
	end
end

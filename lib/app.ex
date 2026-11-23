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
    key = try do
      System.fetch_env!("GOOGLE_KEY") |> Jason.decode!()
    rescue
      _ -> nil
    end

		children = if not is_nil(key) do
      [{Goth, name: App.Goth, source: {:service_account, key}}]
    else
      Log.error(nil,"Firebase API key not found, please provide as an env variable")
      []
    end
		Supervisor.init(children, strategy: :one_for_one)
	end
end

defmodule Firebase0.S do
	@moduledoc "Development impl"
	@callback check() :: {:ok, [String.t()]} | {:error, String.t()}
end

defmodule Firebase1.S do
  @moduledoc "Restful impl, internals are implemented based on https://firebase.google.com/docs/hosting/api-deploy"
  @callback init() :: {:ok, Mint.HTTP.t()} | {:error}
	@callback check(Mint.HTTP.t(), Firebase1.Goth.t()) :: {:ok, Mint.HTTP.t(), nil, [data: Map.t(), status: Integer.t()]} | {:error, Mint.HTTP.t()}
end


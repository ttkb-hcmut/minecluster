defmodule Firebase0 do
	@moduledoc "Development impl"

	@spec check() :: {:ok, [String.t()]} | {:error, String.t()}
	def check do
		{out, 0} = System.cmd "firebase", ["--version"]
		ver = out |> String.trim |> String.split(".")
		if length(ver) > 0, do: {:ok, ver}, else: {:error, out}
  end

	@spec health() :: {:ok} | {:error, String.t()}
	def health do

  end

	@doc "Send a zipped server data file to a hosting platform"
  def sendZipFile(filepath) do
		result = System.cmd "firebase", ["deploy", filepath]
		case result do
			{out, 0} -> {:ok}
			{errmsg, errnum} ->
				errmsg = errmsg |> String.trim
				Log.error(nil, errmsg)
				{:err, errnum, errmsg}
		end
  end

end

defmodule Firebase1 do
  @moduledoc "Restful impl, internals are implemented based on https://firebase.google.com/docs/hosting/api-deploy"

	alias Mint.{HTTP}

	def init() do
		{:ok, conn} = HTTP.connect(:http, "firebasehosting.googleapis.com", 80)
		{:ok, conn}
  end

	def check(conn, project_id, auth) do
		extract = fn xs -> xs |> List.foldl([], fn elem, acc ->
			case elem do
				{:status, _ref, x} -> [{:status, x} | acc]
				_ -> acc
			end
		end) end
		{:ok, conn, _} = HTTP.request(conn, "POST", "/v1beta1/projects/#{project_id}/sites", [{"Authorization", auth}, {"Content-Type", "application/json"}], "")
		receive do
			message ->
				case HTTP.stream(conn, message) do
					:unknown -> {:unknown, conn, nil}
					{:error, conn, err, _sth} -> {:error, conn, err}
				  {:ok, conn, responses} -> {:ok, conn, extract.(responses)}
				end
		end
  end

end

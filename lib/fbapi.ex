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
			{"", 0} -> {:ok}
      {out, 0} -> {:err_unhandled_out, out}
			{errmsg, errnum} ->
				errmsg = errmsg |> String.trim
				Log.error(nil, errmsg)
				{:err, errnum, errmsg}
		end
  end

end

defmodule Firebase1.Goth do
  @enforce_keys [ :project_id, :site_id, :_ ]
  defstruct [ :project_id, :site_id, :_ ]
end

defmodule Firebase1 do
  @behaviour Firebase1.S

	alias Mint.{HTTP1}

	def init() do
		{:ok, conn} = HTTP1.connect(:https, "firebasehosting.googleapis.com", 443)
		{:ok, conn}
  end

	def init_site(auth) do
		{:ok, conn} = HTTP1.connect(:https, "#{auth.site_id}.web.app", 443)
		{:ok, conn}
  end

	def init_upload() do
		{:ok, conn} = HTTP1.connect(:https, "upload-firebasehosting.googleapis.com", 443)
		{:ok, conn}
  end

	def check(conn, auth) do
		{:ok, conn, _} = HTTP1.request(conn, "GET", "/v1beta1/projects/#{auth.project_id}/sites", [{"Authorization", "Bearer #{auth._.token}"}, {"Content-Type", "application/json"}], nil)
		stm = receive do: (message -> handle(conn, message, fn conn, _data ->
      {:ok, conn, nil}
    end))
    stm
	 end

  def extract2(xs), do: xs |> List.foldl([], &(
    case &1, do: (
    {:status, _ref, x} -> [{:status, x} | &2];
    {:data, _ref, x} -> [{:data, x} | &2];
    _ ->
      # IO.inspect(&1)
      &2
    )
  ))

  def handle2(conn, message, on_ok), do: (
    case HTTP1.stream(conn, message), do: (
    :unknown -> {:unknown, conn, nil};
    {:error, conn, err, _sth} -> {:error, conn, err};
    {:ok, conn, responses} ->
      res = extract2(responses)
      {200, data} = {res[:status], res[:data]}
      {:ok, conn, retval} = on_ok.(conn, data)
      {:ok, conn, retval, res}
    )
    )


  def extract(xs), do: xs |> List.foldl([], &(
    case &1, do: (
    {:status, _ref, x} -> [{:status, x} | &2];
    {:data, _ref, x} -> [{:data, Jason.decode!(x)} | &2];
    _ ->
      # IO.inspect(&1)
      &2
    )
  ))

  def handle(conn, message, on_ok), do: (
    case HTTP1.stream(conn, message), do: (
    :unknown -> {:unknown, conn, nil};
    {:error, conn, err, _sth} -> {:error, conn, err};
    {:ok, conn, responses} ->
      res = extract(responses)
      {200, data} = {res[:status], res[:data]}
      {:ok, conn, retval} = on_ok.(conn, data)
      {:ok, conn, retval, res}
    )
    )

  def make_version(conn, auth) do
    msg = %{ config: %{ headers: %{ glob: "**", headers: %{ "Cache-Control": "max-age=1800" } } } }
		{:ok, conn, _} = HTTP1.request(conn, "POST", "/v1beta1/sites/#{auth.site_id}/versions", [{"Authorization", "Bearer #{auth._.token}"}, {"Content-Type", "application/json"}], Jason.encode!(msg))
		stm = receive do: (message -> handle(conn, message, fn conn, data ->
      {:ok, "CREATED"} = Map.fetch(data, "status")
      {:ok, name} = Map.fetch(data, "name")
      {:ok, conn, name |> Path.basename()}
    end))
    stm
  end

  def set_populatefiles0(conn, auth, version, {:zipped_checksum, zipfiledigest}) do
    msg = %{ files: %{ "/sync": zipfiledigest } }
    {:ok, conn, _} = HTTP1.request(conn, "POST", "/v1beta1/sites/#{auth.site_id}/versions/#{version}:populateFiles", [{"Authorization", "Bearer #{auth._.token}"}, {"Content-Type", "application/json"}], Jason.encode!(msg))
		stm = receive do: (message -> handle(conn, message, fn conn, _data ->
      {:ok, conn, nil}
    end))
    stm
  end

  def file_upload(conn, auth, version, {:zipped_checksum, zipfiledigest}, {:zipped_content, zipfilecontent}) do
    {:ok, conn, _} = HTTP1.request(conn, "POST", "/upload/sites/#{auth.site_id}/versions/#{version}/files/#{zipfiledigest}", [{"Authorization", "Bearer #{auth._.token}"}, {"Content-Type", "application/octet-stream"}], zipfilecontent)
		stm = receive do: (message -> handle(conn, message, fn conn, _data ->
      {:ok, conn, nil}
    end))
    stm
  end

  def version_finalize(conn, auth, version) do
    msg = %{ status: "FINALIZED" }
    {:ok, conn, _} = HTTP1.request(conn, "PATCH", "/v1beta1/sites/#{auth.site_id}/versions/#{version}?update_mask=status", [{"Authorization", "Bearer #{auth._.token}"}, {"Content-Type", "application/json"}], Jason.encode!(msg))
		stm = receive do: (message -> handle(conn, message, fn conn, _data ->
      {:ok, conn, nil}
    end))
    stm
  end

  def release(conn, auth, version) do
    msg = %{}
    {:ok, conn, _} = HTTP1.request(conn, "POST", "/v1beta1/sites/#{auth.site_id}/releases?versionName=sites/#{auth.site_id}/versions/#{version}", [{"Authorization", "Bearer #{auth._.token}"}, {"Content-Type", "application/json"}], Jason.encode!(msg))
		stm = receive do: (message -> handle(conn, message, fn conn, data ->
      {:ok, "DEPLOY"} = Map.fetch(data, "type")
      {:ok, time_str} = Map.fetch(data, "releaseTime")
      {:ok, time, _offset} = DateTime.from_iso8601(time_str)
      {:ok, conn, time}
    end))
    stm
  end

  def push(auth, {:zipped_checksum, zipped_checksum}, {:zipped_content, zipped_content}) do
    {:ok, conn} = Firebase1.init()
    {:ok, conn, nil, _} = Firebase1.check(conn, auth)
    {:ok, conn, version, _} = Firebase1.make_version(conn, auth)
    {:ok, conn, nil, _} = Firebase1.set_populatefiles0(conn, auth, version, {:zipped_checksum, zipped_checksum})
    {:ok, conn2} = Firebase1.init_upload()
    {:ok, _conn2, nil, _} = Firebase1.file_upload(conn2, auth, version, {:zipped_checksum, zipped_checksum}, {:zipped_content, zipped_content})
    {:ok, conn, nil, _} = Firebase1.version_finalize(conn, auth, version)
    {:ok, _conn, time, _} = Firebase1.release(conn, auth, version)
    {:ok, time}
  end

  def pull(auth) do
    {:ok, conn} = Firebase1.init_site(auth)
    {:ok, conn, _} = HTTP1.request(conn, "GET", "/sync", [], nil)
		{:ok, _conn, data, _res} = receive do: (message -> handle2(conn, message, fn conn, data ->
      {:ok, conn, data}
    end))
    {:ok, data}
  end

  def test() do
    auth = %Firebase1.Goth{ project_id: "asimov-54739", site_id: "asimov-54739", _: Goth.fetch!(App.Goth) }
    content = """
      #let doc(body) = { set pa(justify: true) set page( paper: "a4", columns: 2, ) body } #let title(content) = { set document(title: content.body) } #let fn(x) = { footnote(x) } #let vanilla_link = link #let link(l, t) = { set text(blue) underline(vanilla_link(l)[#t]) } #let desmos = "Desmos" #let obsidian = "Obsidian" #let typst = "Typst" #let layer9link(uri, body) = { link("http://idea:4999/" + uri, body) } #import "@preview/simplebnf:0.1.1": * #let lexeme(lex) = { text(weight: "bold")[#lex] } #let category(name) = { text[\<#name\>] } #let ocaml = [O'Caml]
    """
    zipped_content = :zlib.gzip(content)
    zipped_checksum = :crypto.hash(:sha256, zipped_content) |> Base.encode16 |> String.downcase
    {:ok, _release_time} = Firebase1.push(auth, {:zipped_checksum, zipped_checksum}, {:zipped_content, zipped_content})
    {:ok, r_content} = Firebase1.pull(auth)
    true = (r_content == content)
  end

  ############################################
  def set(zipBinary,auth_data) do
    # read project_id and site_id from the central field of group config (maybe api key ??!?)
    auth = %Firebase1.Goth{ project_id: auth_data["project_id"], site_id: auth_data["site_id"], _: Goth.fetch!(App.Goth) }
    zipped_content = :zlib.gzip(zipBinary)
    zipped_checksum = :crypto.hash(:sha256, zipped_content) |> Base.encode16 |> String.downcase
    {:ok, _} = Firebase1.push(auth, {:zipped_checksum, zipped_checksum}, {:zipped_content, zipped_content})
  end

  def get(auth_data) do
    auth = %Firebase1.Goth{ project_id: auth_data["project_id"], site_id: auth_data["site_id"], _: Goth.fetch!(App.Goth) }
    {:ok, r_content} = Firebase1.pull(auth)
    r_content
  end
end

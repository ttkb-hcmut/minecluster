defmodule Pleb do
  def registerAsOnline(conn, self) do
    conn |> Central.setStatus(self,:online)
    conn
  end
  def connectToHost(address) do
    IO.puts "Connected to Host: " <> address
  end
  def checkForHosts(conn, self) do
    {:ok , cl} = conn |> Central.getClientList
    case (cl |> Map.filter(fn {_,v} -> v == :host end)|> Map.keys |> Enum.count) do
      0 ->
        conn |> Host.start(self)
      _ ->
        connectToHost(cl |> Map.keys |> List.first)
    end
    conn
  end
  def start(conn,self) do
    conn
    |> registerAsOnline(self)
    |> checkForHosts(self)
  end
end

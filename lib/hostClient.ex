defmodule Host do
  def registerAsHost(conn,self)do
    {:ok, c} = conn |> Central.setStatus(self,:host)
    c # doing this so you can do  conn |> step1 |> step2 |> step3
  end
  def getLatest(conn) do
    IO.inspect conn |> Central.fetchData # some way somehow save the data
    conn
  end
  def runServer() do
    {:ok, "somePIDidk"}
  end
  def start(conn,self) do
    conn
    |> registerAsHost(self)
    |> getLatest
    runServer()
  end
end

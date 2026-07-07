defmodule Placeholder do
  defstruct clientList: %{}
end

defmodule Central do
  def connect(destination\\nil) do
    case destination do
      nil -> {:ok, %Placeholder{clientList: %{}}}
      _ -> {:ok, nil} # do some connection stuff here
    end
  end
  def setStatus(conn\\nil, self ,status) do
    case conn do
      %Placeholder{clientList: _} ->
        { :ok,
        conn
        |> Map.get_and_update(:clientList,
          fn cl ->
            cl
            |> Map.put(self, status)
        end)}
      nil -> { :no_conn , nil } # case no connection
      _ -> { :ok , nil } # do some connection stuff here
    end
  end

  def getClientList(conn\\nil) do
    case conn do
      %Placeholder{clientList: cl} ->
        cl |> Map.fetch(:clientList)
      nil -> { :no_conn , nil } # case no connection
      _ -> { :ok , nil } # do some connection stuff here
    end
  end
end

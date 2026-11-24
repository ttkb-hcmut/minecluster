defmodule Broadcast do
  def msg(message) do
    self = Node.self()
    Node.list
    |> Utils.inParallel(fn n ->
      :erpc.cast(n,Broadcast,:msgSelf,[self,message])
    end)
    nil
  end

  def msgSelf(src \\:nonode@nohost, msg \\ "ping") do
    case Agent.get(:message_server, & &1) do
      nil -> nil
      a ->
        Process.send(a,{
          :message,
          src |> Atom.to_string,
          msg
        },[])
    end
    nil
  end
  def runMsgServer() do
    receive do
      {:message, src, msg} ->
        group = Agent.get(:group, & &1)
        log = Log.new
        |> then(fn l -> case group do
          nil ->
            l |> Log.info("#{IO.ANSI.green()}#{Log.dataHold}#{Log.dataHold}: #{Log.dataHold}#{IO.ANSI.reset()}",[src,group,msg], "message")
          _ ->
            l |> Log.info("#{IO.ANSI.green()}#{Log.dataHold} - #{Log.dataHold}: #{Log.dataHold}#{IO.ANSI.reset()}",[src,group,msg], "message")
        end end)
        # IO.inspect log
        log |> Log.flush
        log |> Log.flush(true) |> Wit.pushToGui

        case :os.type() do
        {:unix, :linux} ->
          System.cmd("notify-send", ["#{src}#{
            case group do
              nil -> ""
              _ -> " - #{group}"
            end
          }: #{msg}"])
        _ -> nil
        end
        Broadcast.runMsgServer()
      _ ->
        Log.error(nil,"No message matched")
        Broadcast.runMsgServer()
    end
  end
end

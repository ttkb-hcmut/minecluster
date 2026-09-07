# defmodule Comm do
#   def startup(interactive_output \\ false) do
#     {:ok, _} = Agent.start_link(fn -> interactive_output end, name: :interactive_output)
#     {:ok, _} = Agent.start_link(fn -> %{} end, name: :comm_info  )
#     {:ok, _} = Agent.start_link(fn -> %{} end, name: :comm_detail)
#     {:ok, _} = Agent.start_link(fn -> %{} end, name: :comm_warn  )
#     {:ok, _} = Agent.start_link(fn -> %{} end, name: :comm_error )
#     {:ok, _} = Agent.start_link(fn -> %{} end, name: :comm_msg   )
#   end
#   def isGui() do
#     Agent.get(:interactive_output, & &1)
#   end
#   def flush(channel \\ ["info", "detail", "warn", "error"]) do
#     if Comm.isGui do
#       package = %{}

#     end
#   end
#   def info(input) do
#     logLevel = case Naas.getConfig("logLevel") do
#       nil -> ["info"]
#       a -> a
#     end
#     case {Agent.get(:interactive_output, & &1),"info" in logLevel} do
#     {true,true} ->
#       try do
#         IO.puts input
#       rescue
#         _ -> nil
#       end
#     {false,true} ->
#       try do
#       IO.puts %{type: "info", data: input} |> JSON.encode!
#       rescue
#         _ -> nil
#       end
#     _ -> nil
#     end
#   end
#   def detail(input) do
#     logLevel = case Naas.getConfig("logLevel") do
#       nil -> ["detail"]
#       a -> a
#     end
#     case {Agent.get(:interactive_output, & &1),"detail" in logLevel} do
#     {true,true} ->
#       try do
#         IO.puts "#{IO.ANSI.color(2,2,2)}#{input}#{IO.ANSI.reset()}"
#       rescue
#         _ -> nil
#       end
#     {false,true} ->
#       try do
#       IO.puts %{type: "log", data: input} |> JSON.encode!
#       rescue
#         _ -> nil
#       end
#     _ -> nil
#     end
#   end
#   def warn(input) do
#     logLevel = case Naas.getConfig("logLevel") do
#       nil -> ["warn"]
#       a -> a
#     end
#     case {Agent.get(:interactive_output, & &1),"warn" in logLevel} do
#     {true,true} ->
#       try do
#         IO.puts "#{IO.ANSI.yellow()}Warning:#{IO.ANSI.reset()} #{input}"
#       rescue
#         _ -> nil
#       end
#     {false,true} ->
#       try do
#       IO.puts %{type: "warn", data: input} |> JSON.encode!
#       rescue
#         _ -> nil
#       end
#     _ -> nil
#     end
#   end
#   def error(input) do
#     case Agent.get(:interactive_output, & &1) do
#     true ->
#       try do
#         IO.puts "#{IO.ANSI.red()}Error:#{IO.ANSI.reset()} #{input}"
#       rescue
#         _ -> nil
#       end
#     false ->
#       try do
#         IO.puts %{type: "error", data: input} |> JSON.encode!
#       rescue
#         _ -> nil
#       end
#     end
#   end
# end

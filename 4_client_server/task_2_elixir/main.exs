defmodule RLE do
  def compress(<<>>), do: <<>>
  def compress(<<byte, rest::binary>>), do: runs(rest, byte, 1, [])

  defp runs(<<byte, rest::binary>>, byte, count, acc) when count < 255,
    do: runs(rest, byte, count + 1, acc)

  defp runs(<<next, rest::binary>>, byte, count, acc),
    do: runs(rest, next, 1, [<<count, byte>> | acc])

  defp runs(<<>>, byte, count, acc),
    do: IO.iodata_to_binary(Enum.reverse([<<count, byte>> | acc]))

  def decompress(data), do: expand(data, [])
  defp expand(<<>>, acc), do: IO.iodata_to_binary(Enum.reverse(acc))
  defp expand(<<count, byte, rest::binary>>, acc) when count > 0,
    do: expand(rest, [:binary.copy(<<byte>>, count) | acc])
  defp expand(_, _), do: raise(ArgumentError, "invalid RLE pairs")
end

defmodule Main do
  def port(text) do
    value = String.to_integer(text)
    if value < 1 or value > 65535, do: raise(ArgumentError, "invalid port")
    value
  end

  def reply(line) do
    [operation | payload] = String.split(String.trim(line), ~r/\s+/, parts: 2)
    hex = List.first(payload) || ""
    {:ok, data} = Base.decode16(hex, case: :mixed)
    result = case operation do
      "COMPRESS" -> RLE.compress(data)
      "DECOMPRESS" -> RLE.decompress(data)
      _ -> raise ArgumentError, "unknown operation"
    end
    "OK " <> Base.encode16(result)
  rescue
    _ -> "ERR invalid command or data"
  end

  def handle(socket) do
    try do
      case :gen_tcp.recv(socket, 0, 10_000) do
        {:ok, line} -> :gen_tcp.send(socket, reply(line) <> "\n")
        _ -> :ok
      end
    after
      :gen_tcp.close(socket)
    end
  end

  def accept(listener) do
    {:ok, socket} = :gen_tcp.accept(listener)
    worker = spawn(fn -> receive do {:socket, connection} -> handle(connection) end end)
    :ok = :gen_tcp.controlling_process(socket, worker)
    send(worker, {:socket, socket})
    accept(listener)
  end

  def run(["server", port_text]) do
    {:ok, listener} = :gen_tcp.listen(port(port_text),
      [:binary, packet: :line, active: false, reuseaddr: true, packet_size: 65_536, buffer: 65_536])
    IO.puts("Listening on #{port_text}")
    accept(listener)
  end

  def run(["client", port_text, command]) do
    {:ok, socket} = :gen_tcp.connect('127.0.0.1', port(port_text),
      [:binary, packet: :line, active: false, packet_size: 16_777_216, buffer: 16_777_216], 5000)
    try do
      :ok = :gen_tcp.send(socket, command <> "\n")
      {:ok, response} = :gen_tcp.recv(socket, 0, 5000)
      IO.binwrite(response)
    after
      :gen_tcp.close(socket)
    end
  end

  def run(_), do: raise(ArgumentError, "usage: main.exs server <port> | client <port> <command>")
end

try do
  Main.run(System.argv())
rescue
  error -> IO.puts(:stderr, "Error: #{Exception.message(error)}"); System.halt(1)
end

import java.nio.charset.StandardCharsets

int parsePort(String value) {
    int port = Integer.parseInt(value)
    if (port < 1 || port > 65535) throw new IllegalArgumentException('invalid port')
    port
}

String readCommand(Reader reader) {
    StringBuilder text = new StringBuilder()
    int character
    while ((character = reader.read()) != -1 && character != 10) {
        if (text.length() >= 65536) throw new IOException('command too long')
        text.append((char) character)
    }
    text.toString().trim()
}

try {
    if (args.length == 2 && args[0] == 'server') {
        Map<String, String> resources = [camera: null, laptop: null, projector: null]
        def respond = { String command ->
            def parts = command.split('\\s+')
            synchronized (resources) {
                if (parts.length == 1 && parts[0] == 'LIST') {
                    return 'OK ' + resources.collect { key, owner -> "${key}=${owner ?: 'free'}" }.join(';')
                }
                if (parts.length != 3 || !(parts[0] in ['RENT', 'RETURN'])) return 'ERR invalid command'
                String resource = parts[1], client = parts[2]
                if (!(client ==~ /[A-Za-z0-9_-]+/)) return 'ERR invalid client name'
                if (!resources.containsKey(resource)) return 'ERR unknown resource'
                if (parts[0] == 'RENT') {
                    if (resources[resource] != null) return 'ERR busy'
                    resources[resource] = client
                    return 'OK rented'
                }
                if (resources[resource] != client) return 'ERR not owner'
                resources[resource] = null
                return 'OK returned'
            }
        }
        new ServerSocket(parsePort(args[1])).withCloseable { listener ->
            println "Listening on ${args[1]}"
            while (true) {
                Socket connection = listener.accept()
                Thread.start {
                    connection.withCloseable { socket ->
                        socket.soTimeout = 10000
                        try {
                            def reader = new InputStreamReader(socket.inputStream, StandardCharsets.UTF_8)
                            String response = respond(readCommand(reader))
                            socket.outputStream.write((response + '\n').getBytes(StandardCharsets.UTF_8))
                            socket.outputStream.flush()
                        } catch (IOException ignored) {
                            // Closing this connection leaves the shared state available to other clients.
                        }
                    }
                }
            }
        }
    } else if (args.length == 3 && args[0] == 'client') {
        new Socket('127.0.0.1', parsePort(args[1])).withCloseable { socket ->
            socket.soTimeout = 5000
            socket.outputStream.write((args[2] + '\n').getBytes(StandardCharsets.UTF_8))
            socket.outputStream.flush()
            println readCommand(new InputStreamReader(socket.inputStream, StandardCharsets.UTF_8))
        }
    } else {
        throw new IllegalArgumentException('usage: main.groovy server <port> | client <port> <command>')
    }
} catch (Exception error) {
    System.err.println("Error: ${error.message}")
    System.exit(1)
}

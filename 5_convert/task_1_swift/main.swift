import Foundation

struct Node: Decodable { let id: String; let label: String }
struct Edge: Decodable { let from: String; let to: String }
struct Graph: Decodable { let nodes: [Node]; let edges: [Edge] }

enum InputError: Error, CustomStringConvertible {
    case invalid(String)
    var description: String {
        switch self { case .invalid(let message): return message }
    }
}

func quoted(_ value: String) throws -> String {
    var result = "\""
    for scalar in value.unicodeScalars {
        switch scalar.value {
        case 34: result += "\\\""
        case 92: result += "\\\\"
        case 10: result += "\\n"
        case 13: result += "\\r"
        case 9: result += "\t"
        case 0..<32, 127: throw InputError.invalid("unsupported control character")
        default: result += String(scalar)
        }
    }
    return result + "\""
}

func run(_ arguments: [String]) throws {
    guard arguments.count == 2 else { throw InputError.invalid("usage: converter <input.json> <output.dot>") }
    let data = try Data(contentsOf: URL(fileURLWithPath: arguments[0]))
    let graph = try JSONDecoder().decode(Graph.self, from: data)
    var identifiers = Set<String>()
    for node in graph.nodes {
        guard identifiers.insert(node.id).inserted else {
            throw InputError.invalid("duplicate node: \(node.id)")
        }
    }
    for edge in graph.edges {
        guard identifiers.contains(edge.from) && identifiers.contains(edge.to) else {
            throw InputError.invalid("edge refers to an unknown node")
        }
    }
    var lines = ["digraph G {"]
    for node in graph.nodes {
        lines.append("  \(try quoted(node.id)) [label=\(try quoted(node.label))];")
    }
    for edge in graph.edges {
        lines.append("  \(try quoted(edge.from)) -> \(try quoted(edge.to));")
    }
    lines.append("}")
    try (lines.joined(separator: "\n") + "\n").write(
        to: URL(fileURLWithPath: arguments[1]), atomically: true, encoding: .utf8)
}

do {
    try run(Array(CommandLine.arguments.dropFirst()))
} catch {
    FileHandle.standardError.write(Data("Error: \(error)\n".utf8))
    exit(1)
}

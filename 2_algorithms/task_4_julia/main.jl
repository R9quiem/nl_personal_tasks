mutable struct Node
    left::Union{Nothing,Node}
    right::Union{Nothing,Node}
end

function skip_space!(characters, position)
    while position[] <= length(characters) && isspace(characters[position[]])
        position[] += 1
    end
end

function expect!(characters, position, expected)
    skip_space!(characters, position)
    if position[] > length(characters) || characters[position[]] != expected
        throw(ArgumentError("expected '$expected' at position $(position[])"))
    end
    position[] += 1
end

function parse_tree(characters, position)
    skip_space!(characters, position)
    if position[] > length(characters)
        throw(ArgumentError("expected a tree at position $(position[])"))
    end
    token = characters[position[]]
    position[] += 1
    if token == '.'
        return nothing
    elseif token == '('
        left = parse_tree(characters, position)
        expect!(characters, position, ',')
        right = parse_tree(characters, position)
        expect!(characters, position, ')')
        return Node(left, right)
    end
    throw(ArgumentError("unexpected character '$token'"))
end

function isomorphic(first, second)
    if isnothing(first)
        return isnothing(second)
    elseif isnothing(second)
        return false
    end
    return (isomorphic(first.left, second.left) && isomorphic(first.right, second.right)) ||
           (isomorphic(first.left, second.right) && isomorphic(first.right, second.left))
end

function run(arguments)
    length(arguments) == 1 || throw(ArgumentError("usage: julia main.jl <file>"))
    characters = collect(read(arguments[1], String))
    position = Ref(1)
    first = parse_tree(characters, position)
    second = parse_tree(characters, position)
    skip_space!(characters, position)
    position[] > length(characters) || throw(ArgumentError("unexpected data after second tree"))
    println(isomorphic(first, second) ? "Isomorphic" : "Not isomorphic")
end

if abspath(PROGRAM_FILE) == abspath(@__FILE__)
    try
        run(ARGS)
    catch error
        print(stderr, "Error: ")
        showerror(stderr, error)
        println(stderr)
        exit(1)
    end
end

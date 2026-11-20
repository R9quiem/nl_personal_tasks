:- use_module(library(assoc)).
:- use_module(library(error)).
:- initialization(main, main).

vertex(Value) :-
    ( atom(Value) ; integer(Value) ), !.
vertex(Value) :-
    domain_error(vertex_identifier, Value).

valid_edge(Edge) :-
    ( nonvar(Edge), Edge = (From, To) ->
        vertex(From), vertex(To)
    ; domain_error(directed_edge, Edge)
    ).

read_edges(File, Edges) :-
    setup_call_cleanup(
        open(File, read, Stream, [encoding(utf8)]),
        ( read_term(Stream, Edges, [syntax_errors(error)]),
          must_be(list, Edges),
          maplist(valid_edge, Edges),
          read_term(Stream, End, [syntax_errors(error)]),
          ( End == end_of_file -> true ; domain_error(end_of_file, End) )
        ),
        close(Stream)).

change_degree(Vertex, Change, Before, After) :-
    ( get_assoc(Vertex, Before, Old) -> true ; Old = 0 ),
    New is Old + Change,
    put_assoc(Vertex, Before, New, After).

build_graph([], Adj, Adj, Degrees, Degrees).
build_graph([(From, To)|Edges], Adj0, Adj, Degrees0, Degrees) :-
    ( get_assoc(From, Adj0, Neighbors) -> true ; Neighbors = [] ),
    put_assoc(From, Adj0, [To|Neighbors], Adj1),
    change_degree(From, 1, Degrees0, Degrees1),
    change_degree(To, -1, Degrees1, Degrees2),
    build_graph(Edges, Adj1, Adj, Degrees2, Degrees).

start_vertex(Edges, Degrees, Start) :-
    assoc_to_list(Degrees, Pairs),
    forall(member(_-Difference, Pairs), between(-1, 1, Difference)),
    findall(Vertex, member(Vertex-1, Pairs), Starts),
    findall(Vertex, member(Vertex-(-1), Pairs), Ends),
    ( Starts = [], Ends = [] -> Edges = [(Start, _)|_]
    ; Starts = [Start], Ends = [_]
    ).

% Hierholzer's algorithm keeps a stack of vertices and prepends finished vertices.
walk([], Adj, Adj, Path, Path).
walk([Vertex|Stack], Adj0, Adj, Finished, Path) :-
    ( get_assoc(Vertex, Adj0, [Next|Rest]) ->
        put_assoc(Vertex, Adj0, Rest, Adj1),
        walk([Next, Vertex|Stack], Adj1, Adj, Finished, Path)
    ; walk(Stack, Adj0, Adj, [Vertex|Finished], Path)
    ).

euler_path([], []) :- !.
euler_path(Edges, Path) :-
    empty_assoc(Empty),
    build_graph(Edges, Empty, Adj, Empty, Degrees),
    start_vertex(Edges, Degrees, Start),
    walk([Start], Adj, Remaining, [], Path),
    assoc_to_values(Remaining, Lists),
    maplist(=([]), Lists).

run([File]) :- !,
    read_edges(File, Edges),
    ( euler_path(Edges, Path) -> writeln(Path)
    ; writeln('No Eulerian path.')
    ).
run(_) :-
    throw(error(usage('swipl -q -s main.pl -- <file>'), _)).

main(Args) :-
    catch(run(Args), Error, (print_message(error, Error), halt(1))).

#!/usr/bin/env escript
-mode(compile).

main(Args) ->
    try run(Args) catch _:Reason -> io:format(standard_error, "Error: ~p~n", [Reason]), halt(1) end.

run(["server", PortText]) ->
    Port = port(PortText),
    register(booking_store, spawn_link(fun() -> store(1, #{}) end)),
    {ok, Listener} = gen_tcp:listen(Port, [binary, {packet, line}, {active, false},
                                        {reuseaddr, true}, {packet_size, 65536}]),
    io:format("Listening on ~B~n", [Port]),
    accept(Listener);
run(["client", PortText, Command]) ->
    {ok, Socket} = gen_tcp:connect("127.0.0.1", port(PortText),
                                 [binary, {packet, line}, {active, false}], 5000),
    try
        ok = gen_tcp:send(Socket, [Command, "\n"]),
        {ok, Reply} = gen_tcp:recv(Socket, 0, 5000),
        io:put_chars(Reply)
    after gen_tcp:close(Socket) end;
run(_) -> error("usage: main.escript server <port> | client <port> <command>").

port(Text) ->
    Value = list_to_integer(Text),
    true = Value > 0 andalso Value < 65536,
    Value.

accept(Listener) ->
    {ok, Socket} = gen_tcp:accept(Listener),
    Worker = spawn(fun() -> receive {start, S} -> handle(S) end end),
    ok = gen_tcp:controlling_process(Socket, Worker),
    Worker ! {start, Socket},
    accept(Listener).

handle(Socket) ->
    try
        case gen_tcp:recv(Socket, 0, 10000) of
            {ok, Line} ->
                Reply = try
                    Request = parse(string:lexemes(binary_to_list(Line), " \t\r\n")),
                    Ref = make_ref(),
                    booking_store ! {self(), Ref, Request},
                    receive {Ref, Result} -> Result after 5000 -> "ERR timeout" end
                catch _:_ -> "ERR invalid command" end,
                gen_tcp:send(Socket, [Reply, "\n"]);
            _ -> ok
        end
    after gen_tcp:close(Socket) end.

parse(["BOOK", Resource, Start, End]) ->
    From = list_to_integer(Start), To = list_to_integer(End),
    true = From >= 0 andalso From < To,
    {book, Resource, From, To};
parse(["LIST", Resource]) -> {list, Resource};
parse(["CANCEL", Id]) -> {cancel, list_to_integer(Id)};
parse(_) -> error(invalid_command).

store(NextId, Bookings) ->
    receive
        {Client, Ref, {book, Resource, From, To}} ->
            Conflict = lists:any(fun({_Id, {R, A, B}}) ->
                R =:= Resource andalso From < B andalso A < To
            end, maps:to_list(Bookings)),
            case Conflict of
                true -> Client ! {Ref, "ERR overlap"}, store(NextId, Bookings);
                false ->
                    Client ! {Ref, "OK " ++ integer_to_list(NextId)},
                    store(NextId + 1, Bookings#{NextId => {Resource, From, To}})
            end;
        {Client, Ref, {list, Resource}} ->
            Items = [lists:flatten(io_lib:format("~B:~B:~B", [Id, A, B]))
                     || {Id, {R, A, B}} <- lists:sort(maps:to_list(Bookings)), R =:= Resource],
            Client ! {Ref, "OK " ++ string:join(Items, ",")},
            store(NextId, Bookings);
        {Client, Ref, {cancel, Id}} ->
            case maps:is_key(Id, Bookings) of
                true -> Client ! {Ref, "OK cancelled"}, store(NextId, maps:remove(Id, Bookings));
                false -> Client ! {Ref, "ERR unknown booking"}, store(NextId, Bookings)
            end
    end.

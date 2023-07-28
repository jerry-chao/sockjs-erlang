-module(cowboy_echo).
-mode(compile).

-export([main/1]).

%% Cowboy callbacks
-export([init/3, handle/2, terminate/3]).


main(_) ->
    Port = 8081,
    SockjsState = sockjs_handler:init_state(
                    <<"/echo">>, fun service_echo/3, state, [{response_limit, 4096}]),

    VhostRoutes = [{<<"/echo/[...]">>, sockjs_cowboy_handler, SockjsState},
                   {'_', ?MODULE, []}],
    Routes = [{'_',  VhostRoutes}], % any vhost
    Dispatch = cowboy_router:compile(Routes),

    io:format(" [*] Running at http://localhost:~p~n", [Port]),
    cowboy:start_http(cowboy_echo_http_listener, 100,
                      [{port, Port}],
                      [{env, [{dispatch, Dispatch}]}]),
    receive
        _ -> ok
    end.

%% --------------------------------------------------------------------------

init({_Any, http}, Req, []) ->
    {ok, Req, []}.

handle(Req, State) ->
    {ok, Data} = file:read_file("./examples/echo.html"),
    {ok, Req1} = cowboy_req:reply(200, [{<<"Content-Type">>, "text/html"}],
                                       Data, Req),
    {ok, Req1, State}.

terminate(_Reason, _Req, _State) ->
    ok.

%% --------------------------------------------------------------------------

service_echo(_Conn, init, state)          -> {ok, state};
service_echo(Conn, {recv, Data}, state)   -> sockjs:send(Data, Conn);
service_echo(_Conn, {info, _Info}, state) -> {ok, state};
service_echo(_Conn, closed, state)        -> {ok, state}.

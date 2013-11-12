-module(server1).
-export([start/0, init/0]).

% server1.erl
%	Test server for etclface testsuite
%	A simple server that waits for a message. then prints it.
%	if it receives a PID, it will respopnd with its own PID

start() ->
	register(?MODULE, spawn(?MODULE, init, [])).

init() ->
	loop().

loop() ->
	receive
		PID when is_pid(PID) ->
			io:format("~p: Received PID >~p<~n", [?MODULE, PID]),
			PID ! self();
		ANY -> io:format("~p: Received >~p<~n", [?MODULE, ANY])
	end,
	loop().


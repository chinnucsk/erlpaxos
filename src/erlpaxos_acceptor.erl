-module(erlpaxos_acceptor).

-behaviour(gen_server).

%% API
-export([start_link/0]).

%% gen_server callbacks
-export([init/1,
         handle_call/3,
         handle_cast/2,
         handle_info/2,
         terminate/2,
         code_change/3]).

-record(acceptor, {
		ballot = undefined :: integer() | undefined,
		value = undefined :: any() | undefined,
		value_balot = undefined :: integer() | undefind
		}).

-record(state, {
		acceptors = dict:new() :: dict()
		}).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

init([]) ->
    {ok, #state{}}.

handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

handle_cast({prepare, Proposer, Key, Ballot}, State) ->
	{NewState, Result} = prepare(Key, Ballot, State),
	gen_server:cast(Proposer, Result),
	{noreply, NewState};
handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.


prepare(Key, Ballot, State = #state{acceptors = Acpts}) ->
	{NewAcceptor, Response} = case dict:find(Key, Acpts) of
		{ok, Acceptor} ->
			prepare(Ballot, Acceptor);
		false ->
			prepare(Ballot, #acceptor{})
	end,
	{State#state{acceptors = dict:store(Key, NewAcceptor, Acpts)}, Response}.

prepare(Ballot, A = #acceptor{ballot = Stored})
		when Stored =:= undefined; Stored =< Ballot ->
	{A#acceptor{ballot = Ballot}, accept};
prepare(_Ballot, A) ->
	{A, reject}.


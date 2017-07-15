-module(tickerapp_server).

-behaviour(gen_server).

-export([start_link/0, say_hello/0,start_watcher/0,init_watcher/0,generateFormattedPrice/2]).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

init([]) ->
    % timer:apply_interval(200,tickerapp_server,say_hello,[]),
    io:format("Ticker Server Started~n",[]),
    start_watcher(),
    {ok, []}.

say_hello() ->
	gen_server:call(?MODULE, hello).

start_watcher() -> 
    Pid = spawn(tickerapp_server, init_watcher, []),
    register(tickerProcess,Pid).

init_watcher() -> 
    fs:start_link(fs_watcher, "/home/tickeruser"),
    fs:subscribe(fs_watcher),
    watcher_receiver().

watcher_receiver() ->
    receive
        % {<0.980.0>,{fs,file_event},{"/Users/01B731B755/Metadata/.info",[inodemetamod,modified]}}
        {_, {_, _}, {ChangedFile, Type}} -> 
             io:format("~p was ~p ~n",[ChangedFile,Type]),
            case lists:member(modified,Type) of
                true ->
                    case string:rstr(ChangedFile,"/smartech_input.txt")>0 of
                        true ->
                            case (string:len(ChangedFile)-string:len("/smartech_input.txt")+1) == string:rstr(ChangedFile,"/smartech_input.txt") of
                                true  ->
                                    ReadlinesFromFile = fun(FileName) -> {ok, Data} = file:read_file(FileName), binary:split(Data, [<<"\n">>], [global]) end,
                                    AllLine = ReadlinesFromFile(ChangedFile),
                                    L = [E || E <- AllLine, E /= <<>>],
                                    io:format("File's : ~p ~n",[L]),
                                    if
                                        length(L) == 2 ->
                                            [Line1,Line2] = L,
                                            % io:format("File's Line1 : ~p  Line2 : ~p ~n",[Line1,Line2]),
                                            FunToGetCoordinateAsNumber = fun(InputCoordinateValue) -> case string:to_float(binary_to_list(InputCoordinateValue)) of {error,no_float} -> case string:to_integer(binary_to_list(InputCoordinateValue)) of {error,_} -> no_float; {V,_} -> float(V) end; {V,_} -> float(V) end end,
                                            Lat = FunToGetCoordinateAsNumber(Line1),
                                            Lon = FunToGetCoordinateAsNumber(Line2),
                                            % io:format("Lat : ~p Lon : ~p ~n",[Lat,Lon]),
                                            if
                                                Lat =/= no_float, Lon =/= no_float ->
                                                    WriteFile = filename:dirname(ChangedFile) ++ "/" ++ "smartech_output.txt",
                                                    Data = emongo:find(pool1,<<"live_table">>,[{<<"loc">>,[{geoWithin,[{centerSphere,[[Lon, Lat],7.84e-4]}]}]}],[{fields,[<<"name">>,<<"rate_growth">>,<<"or_psf">>,{<<"_id">>,0}]},{limit,100}]),
                                                    % io:format("DB Response : ~p ~n",[Data]),
                                                    case Data of
                                                        [[{<<"$err">>,ErrorMessage},_]] ->
                                                            io:format("ErrorMessage : ~p;~n",[ErrorMessage]);
                                                        _ -> 
                                                            generateLinesForFile(WriteFile,Data), 
                                                            io:format("Ticker_Updated_File: ~p;~n",[ChangedFile]),
                                                            ok
                                                    end;
                                                true ->
                                                    io:format("Ticker_Error: not a float value in ~p file;~n",[ChangedFile]),
                                                    ticker_no_float_in_file
                                            end;
                                        true ->
                                            io:format("Ticker_Error: Requires only 2 lines in ~p file;~n",[ChangedFile]),
                                            ticker_invalid_num_lines_in_file
                                    end;
                                false ->
                                    not_a_read_txt_file
                            end;
                        false -> 
                            not_a_read_txt_file
                    end;
                false -> 
                    not_a_modification_type_operation
        end,
        watcher_receiver()
    end.

generateLinesForFile(File,Data) ->
    RedColor = "L1H2U01",
    GreenColor = "L1H2U02",
    OrangeColor = "L1H2U03",
    InitialString = "~~~s~~~sWelcome to SP-TBI~n~~~s~~~sPresented by OYEOK~n",
    file:write_file(File, io_lib:fwrite(InitialString,[GreenColor,"",OrangeColor,""])),
    AppendStringInFile = fun(DataOfBuilding) ->
        % [{VarName1,VarValue1},{VarName2,VarValue2},{VarName3,VarValue3}] = DataOfBuilding,
        % [{<<"or_psf">>,28335},{<<"name">>,<<"127 upper east">>},{<<"rate_growth">>,<<"-5">>}],
        BuildingPriceInt = proplists:get_value(<<"or_psf">>,DataOfBuilding),
        BuildingNameBin = proplists:get_value(<<"name">>,DataOfBuilding),
        BuildingRateGrowthBin = proplists:get_value(<<"rate_growth">>,DataOfBuilding),
        % io:format(" ~p ~p ~p ~n",[BuildingRateGrowthBin,BuildingPriceInt,BuildingNameBin]),
        BuildingPrice = generateFormattedPrice(BuildingPriceInt,""),
        BuildingName = binary_to_list(BuildingNameBin),
        BuildingRateGrowth = binary_to_list(BuildingRateGrowthBin),
        StringText = "~~~s~~~s Rs.~s psf.~n",
        StringColor = case string:str(BuildingRateGrowth,"+") of
            Zero when Zero == 0 ->
                RedColor;
            Num when Num>0 ->
                GreenColor
        end,
    file:write_file(File, io_lib:fwrite(StringText,[StringColor,BuildingName,BuildingPrice]),[append])
    end,
    lists:map(AppendStringInFile,Data).

generateFormattedPrice(Value,Text) ->
    % io:format("~p",[Value]),
    ValueText = integer_to_list(Value),
    if
        length(ValueText) >= 8 ->
            Str1 = trunc(Value/10000000),
            Rem1 = Value rem 10000000,
            if
                Rem1 == 0 ->
                    T = lists:flatten(io_lib:format("~s~p,00,00,000", [Text,Str1])),
                    T;
                true -> 
                    T = lists:flatten(io_lib:format("~s~p,", [Text,Str1])),
                    generateFormattedPrice(Rem1,T)
            end;
        length(ValueText) >= 6 ->
            Str1 = trunc(Value/100000),
            Rem1 = Value rem 100000,
            if
                Rem1 == 0 ->
                    T = lists:flatten(io_lib:format("~s~p,00,000", [Text,Str1])),
                    T;
                true -> 
                    T = lists:flatten(io_lib:format("~s~p,", [Text,Str1])),
                    generateFormattedPrice(Rem1,T)
            end;
        length(ValueText) >= 4 ->
            Str1 = trunc(Value/1000),
            Rem1 = Value rem 1000,
            if
                Rem1 == 0 ->
                    T = lists:flatten(io_lib:format("~s~p,000", [Text,Str1])),
                    T;
                true -> 
                    T = lists:flatten(io_lib:format("~s~p,~p", [Text,Str1,Rem1])),
                    T
            end;
        true ->
            lists:flatten(io_lib:format("~p", [Value]))
    end.

%% callbacks
handle_call(hello, _From, State) ->
    io:format(" Hello from server ~n", []),
    {reply, ok, State};

handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.
handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.



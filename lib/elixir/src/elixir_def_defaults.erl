% Handle default clauses for function definitions.
-module(elixir_def_defaults).
-export([unpack/4]).
-include("elixir.hrl").

unpack(Kind, Name, Args, S) ->
  unpack_each(Kind, Name, Args, [], [], S).

%% Helpers

%% Unpack default from given args.
%% Returns the given arguments without their default
%% clauses and a list of clauses for the default calls.
unpack_each(Kind, Name, [{'//', Line, [Expr, _]}|T] = List, Acc, Clauses, S) ->
  Base = build_match(Acc, Line, []),
  { Args, Invoke } = extract_defaults(List, Line, length(Base), [], []),

  SM = S#elixir_scope{counter=length(Base)},
  { DefArgs, SA }   = elixir_clauses:assigns(fun elixir_translator:translate/2, Base ++ Args, SM),
  { InvokeArgs, _ } = elixir_translator:translate_args(Base ++ Invoke, SA),

  Call = { call, Line,
    { atom, Line, name_for_kind(Kind, Name) },
    InvokeArgs
  },

  Clause = { clause, Line, DefArgs, [], [Call] },
  unpack_each(Kind, Name, T, [Expr|Acc], [Clause|Clauses], S);

unpack_each(Kind, Name, [H|T], Acc, Clauses, S) ->
  unpack_each(Kind, Name, T, [H|Acc], Clauses, S);

unpack_each(_Kind, _Name, [], Acc, Clauses, _S) ->
  { lists:reverse(Acc), lists:reverse(Clauses) }.

% Extract default values from args following the current default clause.

extract_defaults([{'//', _, [_Expr, Default]}|T], Line, Counter, NewArgs, NewInvoke) ->
  extract_defaults(T, Line, Counter, NewArgs, [Default|NewInvoke]);

extract_defaults([_|T], Line, Counter, NewArgs, NewInvoke) ->
  H = { ?ELIXIR_ATOM_CONCAT(["_@", Counter]), Line, nil },
  extract_defaults(T, Line, Counter + 1, [H|NewArgs], [H|NewInvoke]);

extract_defaults([], _Line, _Counter, NewArgs, NewInvoke) ->
  { lists:reverse(NewArgs), lists:reverse(NewInvoke) }.

% Build matches for all the previous argument until the current default clause.

build_match([], _Line, Acc) -> Acc;

build_match([_|T], Line, Acc) ->
  Var = { ?ELIXIR_ATOM_CONCAT(["_@", length(T)]), Line, nil },
  build_match(T, Line, [Var|Acc]).

% Given the invoked function name based on the kind

name_for_kind(Kind, Name) when Kind == defmacro; Kind == defmacrop -> ?ELIXIR_MACRO(Name);
name_for_kind(_Kind, Name) -> Name.
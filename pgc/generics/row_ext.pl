:- module(
  row_ext,
  [
    categorize_rows/4, % +Labels:list
                       % +Rows:list(compound)
                       % -Rows1:list(compound)
                       % -Rows2:list(compound)
    categorize_rows/5, % +Labels:list
                       % +Rows:list(compound)
                       % -Rows1:list(compound)
                       % -Rows2:list(compound)
                       % -Rows3:list(compound)
    nth0_column/3, % +N:nonneg
                   % +Row:compound
                   % ?Elem
    nth0_column/3, % +N:nonneg
                   % +Rows:list(compound)
                   % ?Elems:list
    nth0_column/4, % +N:nonneg
                   % +Row:compound
                   % ?Elem
                   % ?Rest:compound
    nth0_column/4, % +N:nonneg
                   % +Rows:list(compound)
                   % ?Elems:list
                   % ?Rest:list(compound)
    nth1_column/3, % +N:nonneg
                   % +Row:compound
                   % ?Elem
    nth1_column/3, % +N:nonneg
                   % +Rows:list(compound)
                   % ?Elems:list
    nth1_column/4, % +N:nonneg
                   % +Row:compound
                   % ?Elem
                   % ?Rest:compound
    nth1_column/4, % +N:nonneg
                   % +Rows:list(compound)
                   % ?Elems:list
                   % ?Rest:list(compound)
    rows_to_lists/2, % +Rows:list(compound)
                     % -Lists:list(list)
    rows_to_propositions/3, % +Prefix:list
                            % +Rows:list(compound)
                            % -Propositions:ordset(list)
    rows_to_resources/2 % +Rows:list(compound)
                        % -Resources:ordset([bnode,iri,literal])
  ]
).

/** <module> Row extensions

Support for row compound terms, i.e. terms of the following form:
~~~{.pl}
row(Arg1, ..., ArgN)
~~~

Row terms are used in [library(csv)] and [library(semweb/sparql_client)].

@author Wouter Beek
@version 2013/12-2014/01, 2014/03
*/

:- use_module(library(apply)).
:- use_module(library(lists)).
:- use_module(library(ordsets)).



%! categorize_rows(
%!   +Labels:list,
%!   +Rows:list(compound),
%!   -Rows1:list(compound),
%!   -Rows2:list(compound)
%! ) is det.
%! categorize_rows(
%!   +Labels:list,
%!   +Rows:list(compound),
%!   -Rows1:list(compound),
%!   -Rows2:list(compound),
%!   -Rows3:list(compound)
%! ) is det.
% Categorizes rows based on their first argument which is assumed to be
% some kind of label.
%
% `Labels` is a list of labels that distinguish between
% the various row categories.
% The first match is used, from left to right,
% favoring the first row category, etc.
%
% The number of labels is the same as the number of categorized row lists,
% it is one less, in which case the last categorized row list is a
% catch-all option.

categorize_rows([X], L1, L2, L3):- !,
  categorize_rows([X,_], L1, L2, L3).
categorize_rows([_,_], [], [], []):- !.
categorize_rows([X,Y], [H1|T1], [H2|T2], L3):-
  H1 =.. [row,X|Args], !,
  H2 =.. [row|Args],
  categorize_rows([X,Y], T1, T2, L3).
categorize_rows([X,Y], [H1|T1], L2, [H3|T3]):-
  H1 =.. [row,Y|Args], !,
  H3 =.. [row|Args],
  categorize_rows([X,Y], T1, L2, T3).

categorize_rows([X,Y], L1, L2, L3, L4):- !,
  categorize_rows([X,Y,_], L1, L2, L3, L4).
categorize_rows([_,_,_], [], [], [], []):- !.
categorize_rows([X,Y,Z], [H1|T1], [H2|T2], L3, L4):-
  H1 =.. [row,X|Args], !,
  H2 =.. [row|Args],
  categorize_rows([X,Y,Z], T1, T2, L3, L4).
categorize_rows([X,Y,Z], [H1|T1], L2, [H3|T3], L4):-
  H1 =.. [row,Y|Args], !,
  H3 =.. [row|Args],
  categorize_rows([X,Y,Z], T1, L2, T3, L4).
categorize_rows([X,Y,Z], [H1|T1], L2, L3, [H4|T4]):-
  H1 =.. [row,Z|Args],
  H4 =.. [row|Args],
  categorize_rows([X,Y,Z], T1, L2, L3, T4).


%! nth0_column(+N:nonneg, +Row:compound, ?Elem) .
%! nth0_column(+N:nonneg, +Rows:list(compound), ?Elems:list) .
%! nth0_column(+N:nonneg, +Row:compound, ?Elem, ?Rest:compound) .
%! nth0_column(+N:nonneg, +Rows:list(compound), ?Elems:list, ?Rest:list(compound)) .
%! nth1_column(+N:nonneg, +Row:compound, ?Elem) .
%! nth1_column(+N:nonneg, +Rows:list(compound), ?Elems:list) .
%! nth1_column(+N:nonneg, +Row:compound, ?Elem, ?Rest:compound) .
%! nth1_column(+N:nonneg, +Rows:list(compound), ?Elems:list, ?Rest:list(compound)) .

nth0_column(N, Row, X):-
  nth0_column(N, Row, X, _).

nth0_column(N, Rows1, Xs, Rows2):-
  is_list(Rows1), !,
  maplist(nth0_column(N), Rows1, Xs, Rows2).
nth0_column(N, Row1, X, Row2):-
  Row1 =.. [row|Args1],
  nth0(N, Args1, X, Args2),
  Row2 =.. [row|Args2].

nth1_column(N, Row, X):-
  nth1_column(N, Row, X, _).

nth1_column(N, Rows1, Xs, Rows2):-
  is_list(Rows1), !,
  maplist(nth1_column(N), Rows1, Xs, Rows2).
nth1_column(N, Row1, X, Row2):-
  Row1 =.. [row|Args1],
  nth1(N, Args1, X, Args2),
  Row2 =.. [row|Args2].


%! rows_to_lists(+Rows:list(compound), -Lists:list(list)) is det.

rows_to_lists(Rows, Lists):-
  maplist(row_to_list, Rows, Lists).

row_to_list(Row, List):-
  Row =.. [row|List].


%! rows_to_propositions(
%!   +Prefix:list([bnode,literal,iri]),
%!   +Rows:list(compound),
%!   -Propositions:ordset(list)
%! ) is det.
% Returns the ordered set of propositions that occur in
%  the given SPARQL result set rows.
%
% @arg Prefix This contains the stable prefix list of each proposition.
%      This is usually the singleton list of the subject term.
% @arg Rows
% @arg Propositions An ordered set of lists of length 3 (s-p-o).

rows_to_propositions(Prefix, Rows, Props):-
  rows_to_propositions(Prefix, Rows, [], Props).

rows_to_propositions(_, [], Sol, Sol):- !.
rows_to_propositions(Prefix, [H1|T], L1, Sol):-
  row_to_proposition(Prefix, H1, H2),
  ord_add_element(L1, H2, L2),
  rows_to_propositions(Prefix, T, L2, Sol).

row_to_proposition(Prefix, Row, L):-
  Row =.. [row|Suffix],
  append(Prefix,  Suffix, L).


%! rows_to_resources(
%!   +Rows:list(compound),
%!   -Resources:ordset([bnode,iri,literal])
%! ) is det.
% Returns the ordered set of resources that occur in
%  the given SPARQL result set rows.

rows_to_resources(Rows, Resources):-
  rows_to_resources(Rows, [], Resources).

rows_to_resources([], Resources, Resources).
rows_to_resources([Row|Rows], Resources1, Sol):-
  Row =.. [row|NewResources],
  ord_union(Resources1, NewResources, Resources2),
  rows_to_resources(Rows, Resources2, Sol).


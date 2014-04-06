:- module(
  dgraph_ext,
  [
    dgraph_arcs/2, % +Graph:dgraph
                   % -Arcs:ordset(arc)
    dgraph_empty/1, % ?Graph:dgraph
    dgraph_neighbor/3, % +V:vertex
                       % +G:dgraph
                       % ?W:vertex
    dgraph_neighbors/3, % +V:vertex
                        % +G:dgraph
                        % -VNs:list(vertex)
    dgraph_subgraph/2, % ?G1:dgraph
                       % +G2:dgraph
    dgraph_vertex_induced_subgraph/3, % +G:dgraph
                                      % +VSubG:list(vertex)
                                      % -SubG:dgraph
    dgraph_vertices/2, % +Graph:dgraph
                       % -Vertices:ordset(vertex)
    directed_cycle/2, % +V:vertex
                      % +G:dgraph
    directed_cycle/3, % +V:vertex
                      % +G:dgraph
                      % -Cycle:list(arc_vertice)
    directed_cycle/5, % +V:vertex
                      % +G:dgraph
                      % -Vs:list(vertex)
                      % -As:list(arc)
                      % -Cycle:list(arc_vertice)
    directed_trail/3, % +V:vertex
                      % +G:dgraph
                      % ?W:vertex
    directed_trail/4, % +V:vertex
                      % +G:dgraph
                      % ?W:vertex
                      % -DirTrail:list(arc_vertice)
    directed_trail/6, % +V:vertex
                      % +G:dgraph
                      % ?W:vertex
                      % -Vs:list(vertex)
                      % -As:list(arc)
                      % -DirTrail:list(arc_vertice)
    directed_path/3, % +V:vertex
                     % +G:dgraph
                     % ?W:vertex
    directed_path/4, % +V:vertex
                     % +G:dgraph
                     % ?W:vertex
                     % -DirPath:list(arc_vertice)
    directed_path/6, % +V:vertex
                     % +G:dgraph
                     % ?W:vertex
                     % -Vs:list(vertex)
                     % -As:list(arc)
                     % -DirPath:list(arc_vertice)
    directed_walk/3, % +V:vertex
                     % +G:dgraph
                     % ?W:vertex
    directed_walk/4, % +V:vertex
                     % +G:dgraph
                     % ?W:vertex
                     % ?DirectedWalk:list(arc&edge)
    directed_walk/6, % +V:vertex
                     % +G:dgraph
                     % ?W:vertex
                     % -Vs:list(vertex)
                     % -As:list(arc)
                     % -DirectedWalk:list(arc_vertice)
    export_dgraph/4, % +Options:list(nvpair)
                     % :CoordFunc
                     % +Graph:ugraph
                     % -GraphTerm:compound
    has_directed_cycle/1, % +G:dgraph
    in_degree/3, % +G:dgraph
                 % +V:vertex
                 % -InDegree:integer
    in_neighbor/3, % +V:vertex
                   % +G:dgraph
                   % ?W:vertex
    in_neighbors/3, % +V:vertex
                    % +G:dgraph
                    % -InVNs:list(vertex)
    orientation/2, % +G:ugraph
                   % -O:dgraph
    out_degree/3, % +G:dgraph
                  % +V:vertex
                  % -OutDegree:integer
    out_neighbor/3, % +V:vertex
                    % +G:dgraph
                    % ?W:vertex
    out_neighbors/3, % +V:vertex
                     % +G:dgraph
                     % -OutVNs:list(vertex)
    reachable/3, % +V:vertex
                 % +G:dgraph
                 % +W:vertex
    strict/1, % +G:dgraph
    strongly_connected/1, % +G:dgraph
    underlying/2, % +G:dgraph
                  % -U:ugraph
    vertices_arcs_to_dgraph/3, % +Vs:list(vertex)
                               % +As:list(arc)
                               % -G:dgraph
    weakly_connected/1 % +G:dgraph
  ]
).

/** <module> dgraph

Directed graphs.

*Datatype*: =arc=, a directed =edge=.

*Datatype*: =|dgraph(ugraph, ugraph)|=.

@author Wouter Beek
@version 2012/08, 2013/07
*/

:- use_remote_module(generics(list_ext)).
:- use_remote_module(graph_theory(graph_generic)).
:- use_module(library(apply)).
:- use_module(library(ordsets)).
:- use_remote_module(ugraph(ugraph_ext)).

:- meta_predicate(export_dgraph(+,4,+,-)).



%! dgraph_arcs(+Graph:dgraph, -Arcs:ordset(arc)) is det.
% Returns the arcs of the directed graph.

dgraph_arcs(dgraph(InG, OutG), Arcs):-
  edges(InG, ArcsInG),
  edges(OutG, ArcsOutG),
  ord_union(ArcsInG, ArcsOutG, Arcs).

%! dgraph_empty(+G:dgraph) is semidet.
%! dgraph_empty(-G:dgraph) is det.
% Succeeds on the empty digraph or returns the empty digraph.

dgraph_empty(dgraph([], [])).

%! dgraph_subgraph(+G1:dgraph, +G2:dgraph) is semidet.
% Succeeds if G1 is a subgraph of G2.

dgraph_subgraph(dgraph(InG1, OutG1), dgraph(InG2, OutG2)):-
  maplist(subgraph_, InG1, InG2),
  maplist(subgraph_, OutG1, OutG2).

%! dgraph_neighbor(+V:vertex, +G:dgraph, +W:vertex) is semidet.
%! dgraph_neighbor(+V:vertex, +G:dgraph, -W:vertex) is nondet.

dgraph_neighbor(V, G, W):-
  in_neighbor(V, G, W).
dgraph_neighbor(V, G, W):-
  out_neighbor(V, G, W).

dgraph_neighbors(V, dgraph(InG, OutG), VNs):-
  ugraph_neighbors(V, InG, InVNs),
  ugraph_neighbors(V, OutG, OutVNs),
  ord_union(InVNs, OutVNs, VNs).

%! dgraph_vertex_induced_subgraph(
%!   +G:dgraph,
%!   +VSubG:list(vertex),
%!   -SubG:dgraph
%! ) is det.
% Returns the vertex-induced subgraph.

dgraph_vertex_induced_subgraph(dgraph(InG, OutG), VSubG, dgraph(SubInG, SubOutG)):-
  ugraph_vertex_induced_subgraph(InG, VSubG, SubInG),
  ugraph_vertex_induced_subgraph(OutG, VSubG, SubOutG).

%! dgraph_vertices(+Graph:dgraph, -Vertices:ordset(vertex)) is det.
% Returns the vertices that occur in the given digraph.
%
% @arg Graph A directed graph.
% @arg Vertices An ordered set of vertices.

dgraph_vertices(dgraph(InG, OutG), Vs):-
  ugraph_vertices(InG, InVs),
  ugraph_vertices(OutG, OutVs),
  ord_union(InVs, OutVs, Vs).

%! directed_cycle(+V:vertex, +G:dgraph) is semidet.
% Succeeds if there is a directed cycle at the given vertex, in the given
% graph.
%
% @see directed_cycle/3

directed_cycle(V, G):-
  directed_cycle(V, G, _DirCycle).

%! directed_cycle(
%!   +V:vertex,
%!   +G:dgraph,
%!   -DirCycle:list(edge_vertice)
%! ) is nondet.
% Returns a directed cycle through the given directed graph, starting at the
% given vertex.
%
% @see directed_cycle/5

directed_cycle(V, G, DirCycle):-
  directed_cycle(V, G, _Vs, _Es, DirCycle).

%! directed_cycle(
%!   +V:vertex,
%!   +G:dgraph,
%!   -Vs:list(vertex),
%!   -Es:list(edge),
%!   -DirCycle:list(edge_vertice)
%! ) is nondet.
% Returns directed cycles that start at the given vertex in the given graph.
% Also returns the edges and vertices that form the cycle, in the order in
% which they were visited.
%
% *Definition*: A directed cycle is a directed closed trail where all vertices
%               are unique (as in a directed path) but with V_0 = V_n.
%
% @arg V A vertex.
% @arg G A directed graph.
% @arg Vs A list of vertices.
% @arg Es A list of edges.
% @arg DirCycle A list that consists of interchanging vertices and edges.

directed_cycle(V, G, [V | Vs], [V-W | Es], [V, V-W | DirCycle]):-
  dgraph_neighbor(V, G, W),
  directed_path(W, G, V, [], Vs, [V-W], Es, DirCycle).

directed_trail(V, G, W):-
  directed_trail(V, G, W, _DirTrail).

directed_trail(V, G, W, DirTrail):-
  directed_trail(V, G, W, _Vs, _As, DirTrail).

directed_trail(V, G, W, Vs, As, DirTrail):-
  directed_trail(V, G, W, Vs, [], As, DirTrail).

directed_trail(V, _G, V, _History, [V], [], [V]):-
  !.
directed_trail(V, G, W, [V | Vs], H_As, [V-X | As], [V, V-X | DirTrail]):-
  dgraph_neighbor(V, G, X),
  \+(member(V-X, H_As)),
  directed_trail(X, G, W, Vs, [V-X | H_As], As, DirTrail).

directed_path(V, G, W):-
  directed_path(V, G, W, _DirPath).

directed_path(V, G, W, DirPath):-
  directed_path(V, G, W, _Vs, _As, DirPath).

directed_path(V, G, W, Vs, As, DirPath):-
  directed_path(V, G, W, [], Vs, [], As, DirPath).

directed_path(V, _G, V, _H_Vs, [V], _H_As, [], [V]):-
  !.
directed_path(V, G, W, H_Vs, [V | Vs], H_As, [V-X | As], [V, V-X | DirPath]):-
  dgraph_neighbor(V, G, X),
  \+(member(X, H_Vs)),
  \+(member(V-X, H_As)),
  directed_path(X, G, W, [X | H_Vs], Vs, [V-X | H_As], As, DirPath).

%! directed_walk(+V:vertex, +G:dgraph, ?W:vertex) is semidet.
% @see directed_walk/6

directed_walk(V, G, W):-
  directed_walk(V, G, W, _DirWalk).

%! directed_walk(
%!   +V:vertex,
%!   +G:dgraph,
%!   ?W:vertex,
%!   -DirWalk:list(arc_vertice)
%! ) is nondet.
% @see directed_walk/6

directed_walk(V, G, W, DirWalk):-
  directed_walk(V, G, W, _Vs, _As, DirWalk).

%! directed_walk(
%!   +V:vertex,
%!   +G:dgraph,
%!   ?W:vertex,
%!   -Vs:list(vertex),
%!   -As:list(arc),
%!   -DirWalk:list(arc_vertice)
%! ) is nondet.
% Returns the path along which the given vertices are joined
% in the given graph.

directed_walk(V, _G, V, [], [], []):-
  !.
directed_walk(V, G, W, [V, X | Vs], [V-X | As], [V, V-X, X | DirWalk]):-
  dgraph_neighbor(V, G, X),
  directed_walk(X, G, W, Vs, As, DirWalk).

%! export_dgraph(
%!   +Options:list(nvpair),
%!   :CoordFunc,
%!   +Graph:dgraph,
%!   -GraphTerm:compound
%! ) is det.
% @tbd Implement this. Look at UGRAPH_EXPORT.

export_dgraph(_O, _CoordFunc, _G, _G_Term).

%! has_directed_cycle(+G:dgraph) is semidet.
% Succeeds if the given digraph has a cycle.
%
% @see directed_cycle/2.

has_directed_cycle(G):-
  vertices(G, Vs),
  member(V, Vs),
  directed_cycle(V, G),
  !.

in_degree(G, V, InDegree):-
  in_neighbors(V, G, InNeighbors),
  length(InNeighbors, InDegree).

%! in_neighbor(+V:vertex, +G:dgraph, +W:vertex) is semidet.
%! in_neighbor(+V:vertex, +G:dgraph, -W:vertex) is nondet.
% Succeeds if for an incoming vertex or returns an incoming vertex.

in_neighbor(V, G, InVN):-
  in_neighbors(V, G, InVNs),
  member(InVN, InVNs).

%! in_neighbors(+V:vertex, +G:dgraph, -InVNs:list(vertex)) is det.
% Returns the incoming neighbors of the given vertex.

in_neighbors(V, dgraph(_OutG, InG), InVNs):-
  member(V-InVNs, InG).

orientation(G, O):-
  vertices(G, Vs),
  edges(G, Es),
  orientation_(Es, As),
  vertices_arcs_to_dgraph(Vs, As, O).

orientation_([], []).
orientation_([V-W | Es], [V-W | As]):-
  orientation_(Es, As).
orientation_([V-W | Es], [W-V | As]):-
  orientation_(Es, As).

out_degree(G, V, OutDegree):-
  out_neighbors(V, G, OutNeighbors),
  length(OutNeighbors, OutDegree).

out_neighbor(V, G, OutVN):-
  out_neighbors(V, G, OutVNs),
  member(OutVN, OutVNs).

out_neighbors(V, dgraph(OutG, _InG), OutVNs):-
  member(V-OutVNs, OutG).

%! reachable(V, G, W) is semidet.
% Succeeds if the latter vertex is reachable from the former.
%
% *Definition*: A vertex W is reable from vertex V if there is
%               a directed path from V to W.

reachable(V, G, W):-
  directed_path(V, G, W).

%! strict(+Graph:dgraph) is semidet.
% Succeeds on strict digraphs.
%
% *Definition*: A strict digraph has no loops and no double occurring arcs.

strict(G):-
  \+(has_directed_cycle(G)).

%! strongly_connected(+G:dgraph) is semidet.
% Succeeds if the given graph is strongly connected.
%
% *Definition*: A digraph is strongly connected if all pairs of vertices
%               are connected via a directed path.
%
% @see strongly_connected/3

strongly_connected(G):-
  vertices(G, Vs),
  forall(
    member(V, W, Vs),
    directed_path(V, G, W)
  ).

subgraph_(V-NV1, V-NV2):-
  sublist(NV1, NV2).

%! underlying(+G:dgraph, -U:ugraph) is det.
% Returns the underlying undirected graph for the given directed graph.

underlying(G, U):-
  ugraph_vertices(G, Vs),
  dgraph_arcs(G, As),
  underlying(Vs, As, U).

underlying(Vs, As, U):-
  findall(
    V-Ns,
    (
      member(V, Vs),
      findall(
        W,
        (
          member(V-W, As)
        ;
          member(W-V, As)
        ),
        Ns
      )
    ),
    U
  ).

%! vertices_arcs_to_dgraph(
%!   +Vs:list(vertex),
%!   +As:list(arc),
%!   -G:dgraph
%! ) is det.
% Returns the digraph representation for the given vertices and arcs.

vertices_arcs_to_dgraph(Vs, As, dgraph(InG, OutG)):-
  findall(
    V-InNs,
    (
      member(V, Vs),
      findall(
        W,
        member(W-V, As),
        InNs
      )
    ),
    InG
  ),
  findall(
    V-OutNs,
    (
      member(V, Vs),
      findall(
        W,
        member(V-W, As),
        OutNs
      )
    ),
    OutG
  ).

%! weakly_connected(+G:dgreph) is semidet.
% Succeeds if the given digraph is weakly connected.
%
% *Definition*: A weakly connected digraph has a connected underlying graph.

weakly_connected(G):-
  underlying(G, U),
  connected(dgraph_vertices, dgraph_arcs, U).


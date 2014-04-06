:- module(
  spring_embedding,
  [
    default_spring_embedding/7, % +Graph:graph
                                % :V_P
                                % :E_P
                                % :N_P
                                % +Iteration:integer
                                % -VerticeCoordinates:list(vertex_coordinate)
                                % -History:list
    simple_spring_embedding/5 % +Graph:graph
                              % :V_P
                              % +Iteration:integer
                              % -VerticeCoordinates:list(vertex_coordinate)
                              % -History:list
  ]
).

/** <module> Spring embedding

Spring embedding for undirected graphs.

A graph G can be visualized in 1 through $\card{V(G)}$ dimensions.

# Algorithm

~~~{.txt}
For all vertices V:
  For all dimensions I:
    For all vertices W \neq V:
      Calculate the attraction and repulsion between V and W.
      The differneces of attraction and repulsion are subtracted and the
      resulting numbers are summated.
    Update dimension I for vertex V based on the netto force.
~~~

The attraction between V and W is 2 \log{d(V,W)} for adjacent vertices,
otherwise 0.

The repulsion between V and W is \frac{1}{\sqrt{d(V,W)}} for nonadjacent
vertices, otherwise 0.

The attraction and repulsion between V and W for dimension I is
the attraction between V and W irrespective of dimension (see above)
multiplied with \frac{\abs{V_x,W_x}}{d(V,W)}.

d(V,W) is the Cartesian distance between V and W.

# Example: simple grid

~~~{.pl}
spring_embedding([1-[2,4],2-[1,3,5],3-[2,4,6,8],4-[1,3,7],5-[2,6],6-[2,3,9],7-[4,8],8-[3,7,9],9-[6,8]], 100)
~~~

# Example

~~~{.pl}
spring_embedding([1-[9],2-[9],3-[9],4-[9],5-[10],6-[10],7-[10],8-[10],9-[1,2,3,4,10],10-[5,6,7,8,9]], 100)
~~~

@author Wouter Beek
@version 2012/10, 2013/01, 2013/07, 2014/03
*/

:- use_remote_module(generics(list_ext)).
:- use_remote_module(generics(meta_ext)).
:- use_remote_module(graph_theory(graph_generic)).
:- use_remote_module(graph_theory(graph_traversal)).
:- use_remote_module(graph_theory(random_vertex_coordinates)).
:- use_module(library(debug)).
:- use_module(library(settings)).
:- use_remote_module(math(math_ext)).
:- use_remote_module(pl(pl_mode)).

:- dynamic(tempval0/2).

:- meta_predicate(default_spring_embedding(+,2,2,3,+,-,-)).
:- meta_predicate(distance_force_dimension(+,2,3,+,+,+,-)).
:- meta_predicate(initial_spring_embedding(+,2,-)).
:- meta_predicate(neighbor_attraction(+,3,+,+,-)).
:- meta_predicate(neighbor_attraction_dimension(+,3,+,+,+,-)).
:- meta_predicate(nonneighbor_repulsion(+,3,+,+,-)).
:- meta_predicate(nonneighbor_repulsion_dimension(+,3,+,+,+,-)).
:- meta_predicate(simple_spring_embedding(+,2,+,-,-)).
:- meta_predicate(spring_embedding(+,2,+,+,+,-,-)).

:- setting(
  surface,
  compound,
  size(2,[10.0,10.0]),
  'The size of the surface to draw on.'
).



% GENERIC SPRING EMBEDDING LOOP %

%! initial_spring_embedding(
%!   +Graph:graph,
%!   :V_P,
%!   -RandomVertexCoords:list(vertex_coordinate)
%! ) is det.
% Returns random coordinates for the vertices in the given ugraph.
%
% @arg Graph A graph.
% @arg RandomVertexCoords A list of vertex coordinates in the
%      dimension set by the given size specifier.

initial_spring_embedding(G, V_P, RandomVertexCoords):-
  random_vertex_coordinates([], G, V_P, RandomVertexCoords).

%! inter_v(
%!   +Graph:graph,
%!   +Preds:list,
%!   +VerticeCoordinates:list(vertex_coordinate),
%!   +Vertices:list(vertex),
%!   +Dimension:integer,
%!   +V:vertex,
%!   -Force:float
%! ) is det.
% Calculates inter-vertex forces for vertex =V= in dimension =I=.
% The individual forces are calculated using the predicates =Preds=.

inter_v(Graph, Preds, VerticeCoordinates, Dimension, V, ForceV):-
  % Calculate the forces that are the result of applying the given predicates.
  selectchk(vertex_coordinate(V, CoordinatesV), VerticeCoordinates, OtherVerticeCoordinates),
  findall(
    ForceVW,
    (
      member(vertex_coordinate(W, CoordinatesW), OtherVerticeCoordinates),
      app_list(
        Preds,
        [
          Graph,
          Dimension,
          vertex_coordinate(V, CoordinatesV),
          vertex_coordinate(W, CoordinatesW)
        ],
        ForcesVW_Preds
      ),
      % Summate the results of all predicate applications to vertex W.
      sum_list(ForcesVW_Preds, ForceVW)
    ),
    ForcesV
  ),

  % Average the results of all interactions with V.
  average(ForcesV, ForceV).

%! netto_force(
%!   +Dimension:integer,
%!   +PositionV:float,
%!   +Attraction:float,
%!   +Repulsion:float,
%!   -NewPositionV:float
%! ) is det.
% Returns the netto force on vertex V in the given dimension.

netto_force(Dimension, PositionV, Attraction, Repulsion, NettoForce):-
  DistanceToFloor = PositionV,
  % Correct the calculated force, based on the proximity of vertex V
  % to the limit that is set for the current dimension.
  tempval(limit(Dimension), Limit),
  DistanceToCeiling is Limit - DistanceToFloor,
  % The floor attracts, i.e., sends in the direction of the ceiling,
  % and the ceiling repulses, i.e., sends in the direction of the
  % floor.
  FloorAttraction is DistanceToFloor / Limit,
  CeilingRepulsion is DistanceToCeiling / Limit,
  NettoForce is Attraction - Repulsion + FloorAttraction - CeilingRepulsion.

%! next_spring_embedding(
%!   +Graph:graph,
%!   +Attractors:list,
%!   +Repulsors:list,
%!   +VerticeCoordinates:list(vertex_coordinate),
%!   -NewVerticeCoordinates:list(vertex_coordinate)
%! ) is det.

next_spring_embedding(
  Graph,
  Attractors,
  Repulsors,
  VerticeCoordinates,
  NewVerticeCoordinates
):-
  % Not that this runs seperately from the iteration argument used by multi/4!
  flag(spring_embedding_iterations, Iteration, Iteration + 1),

  % For all vertices...
  findall(
    vertex_coordinate(V, coordinate(Dimensions, NewPositionsV)),
    (
      member(
        vertex_coordinate(V, coordinate(Dimensions, PositionsV)),
        VerticeCoordinates
      ),
      % For all coordinates in a vertex's vertex coordinates, do...
      findall(
        NewPositionV,
        (
          nth0(Dimension, PositionsV, PositionV),
          inter_v(
            Graph, Attractors, VerticeCoordinates, Dimension, V,
            Attraction
          ),
          inter_v(
            Graph, Repulsors, VerticeCoordinates, Dimension, V,
            Repulsion
          ),
          netto_force(
            Dimension, PositionV, Attraction, Repulsion,
            NettoForce
          ),
          update_position(PositionV, Iteration, NettoForce, NewPositionV)
        ),
        NewPositionsV
      )
    ),
    NewVerticeCoordinates
  ).

%! spring_embedding(
%!   +Graph:graph,
%!   :V_P,
%!   +Attractors:list,
%!   +Repulsors:list,
%!   +Iteration:integer,
%!   -FinalVerticeCoordinates:list(vertice_coordinates),
%!   -History:list
%! ) is det.
% Returns the spring embedding of the given graph over the given number of
% iterations. The intermediary results are returned as history.
%
% @arg Graph A graph.
% @arg V_P
% @arg Attractors A list of atomic names of predicates that are used to
%        calculate the attraction forces between vertices.
% @arg Repulsors A list of atomic names of predicates that are used to
%        calculate the repulsion forces between vertices.
% @arg Iteration An integer, representing the number of subsequent function
%        application.
% @arg FinalVerticeCoordinates A list of coordinates for the vertives
%        of the graph.
%        For one spring embedding, every coordinate is represented in the
%        same dimension. This dimension is set by the given size.
% @arg History A list of ???, representing the intermediary results of
%        spring embedding.

spring_embedding(
  G, V_P, Attractors, Repulsors, Iteration, FinalVCoords, History
):-
  initial_spring_embedding(G, V_P, VCoords),
  flag(spring_embedding_iterations, _, 1),
  % Subsequent function application.
  call_multi(
    next_spring_embedding(G, Attractors, Repulsors),
    Iteration,
    VCoords,
    FinalVCoords,
    History
  ).

tempval(Name, Value):-
  tempval0(Name, Value), !.

%! update_position(
%!   +PositionV:float,
%!   +Iteration:integer,
%!   +Force:float,
%!   -NewPositionV:float
%! ) is det.

update_position(PositionV, _Iteration, Force, NewPositionV):-
  %%%%NewPositionV is PositionV + ((1 / (Iteration + 9)) * Force).
  NewPositionV is PositionV + Force.



% PUSH & PULL: EDGE DISTANCE TO NEIGHBOR

degree_force_dimension(
  Graph,
  Dimension,
  vertex_coordinate(V, coordinate(_Dimensions, PositionsV)),
  _VertexCoordinateW,
  DimensionForce
):-
  % This is only calculated for the Y-axis.
  Dimension == 1,
  !,
  degree(Graph, V, DegreeV),
  nth0chk(Dimension, PositionsV, PositionV),
  tempval(maximum_degree, MaximumDegree),
  tempval(limit(Dimension), Limit),
  TargetPositionV is Limit * (DegreeV / MaximumDegree),
  DimensionForce is (TargetPositionV - PositionV) / Limit,
  debug(
    spring,
    '[DEGREE] V=~w\tAct=~2f\tPot=~2f\tF_~w=~2f',
    [V, PositionV, TargetPositionV, Dimension, DimensionForce]
  ).
degree_force_dimension(
  _Graph, _Dimension, _VertexCoordinateV, _VertexCoordinateW,
  0.0
).

%! distance_force_dimension(
%!   +Graph:graph,
%!   :E_P,
%!   :N_P,
%!   +Dimension:integer,
%!   +V:vertex,
%!   +W:vertex,
%!   -DimensionForce:float
%! ) is det.
% Returns the attraction between vertices V and W in the given dimension.
%
% @arg Graph
% @arg E_P
% @arg N_P
% @arg Dimension An integer representing a dimension.
% @arg V A vertex.
% @arg W A vertex.
% @arg DimensionForce A floating point value, representing the
%        attraction between vertices V and W in the given dimension.

distance_force_dimension(
  Graph,
  E_P,
  N_P,
  Dimension,
  vertex_coordinate(V, coordinate(Dimensions, PositionsV)),
  vertex_coordinate(W, coordinate(Dimensions, PositionsW)),
  DimensionForce
):-
  % This is only calculated for the X-axis.
  Dimension == 0, !,
  travel_min([unique_vertex(true)], Graph, E_P, N_P, V, W, MinimumDistance),
  nth0chk(Dimension, PositionsV, PositionV),
  nth0chk(Dimension, PositionsW, PositionW),
  DeltaPos is abs(PositionV - PositionW),
  tempval(maximum_edge_distance, MaximumMinimumDistance),
  tempval(limit(Dimension), Limit),
  TargetDeltaPos is Limit * (MinimumDistance / MaximumMinimumDistance),
  DimensionForce0 is (TargetDeltaPos - DeltaPos) / Limit,
  (
    PositionV > PositionW
  ->
    DimensionForce is DimensionForce0
  ;
    DimensionForce is -DimensionForce0
  ),
  debug(
    spring,
    '[DELTA] V=~w\tAct=~2f\tPot=~2f\tF_~w=~2f',
    [V, DeltaPos, TargetDeltaPos, Dimension, DimensionForce]
  ).
distance_force_dimension(
  _G, _E_P, _N_P, _Dimension, _VertexCoordinateV, _VertexCoordinateW,
  0.0
).

default_spring_embedding(G, V_P, E_P, N_P, Iteration, Final, History):-
  % Assert the maximum distance between two nodes in the graph as a
  % temporary value.
  call(V_P, G, Vs),
  maplist_pairs(
    travel_min([unique_vertex(true)], G, E_P, N_P),
    Vs,
    MinimumDistances
  ),
  max_list(MinimumDistances, MaximumMinimumDistance),
  assert(tempval0(maximum_edge_distance, MaximumMinimumDistance)),

  maplist(degree(G), Vs, Degrees),
  max_list(Degrees, MaximumDegree),
  assert(tempval0(maximum_degree, MaximumDegree)),

  % Assert the minimum limits of the drawing serface as temporary values.
  % Every dimension has its own limit.
  setting(surface, size(_Dimensions,Limits)),
  forall(
    nth0(Dimension, Limits, Limit),
    assert(tempval0(limit(Dimension), Limit))
  ),

  spring_embedding(
    G,
    V_P,
    [
      spring_embedding:distance_force_dimension,
      spring_embedding:degree_force_dimension
    ],
    [],
    Iteration,
    Final,
    History
  ),

  % Clean up temporary values.
  retractall(tempval0(_Name, _Value)).



% PUSH & PULL: GEOMETRIC DISTANCE TO NEIGHBOR

%! neighbor_attraction(
%!   +Graph,
%!   :N_P,
%!   +VerticeCoordinateV:vertex_coordinate,
%!   +VerticeCoordinateW:vertice_coordiante,
%!   -Attraction:float
%! ) is det.
% Returns the attraction between V and W on all coordinates.

% For identical coordinates nothing happens.
neighbor_attraction(
  _Graph,
  _N_P,
  vertex_coordinate(_V, Coordinates),
  vertex_coordinate(_W, Coordinates),
  0.0
):- !.
% Not at the same coordinates and neighbors.
neighbor_attraction(
  G,
  N_P,
  vertex_coordinate(V, CoordinatesV),
  vertex_coordinate(W, CoordinatesW),
  Attraction
):-
  % Single neighbor function.
  call(N_P, V, G, W), !,
  euclidean_distance(CoordinatesV, CoordinatesW, CartesianDistance),
  debug(spring, '    d(~w,~w)=~w', [V, W, CartesianDistance]),
  Attraction is 2 * log10(CartesianDistance),
  debug(spring, '    F_att(~w,~w)=~w', [V, W, Attraction]).
% Not at the same coordinates and not neighbors.
neighbor_attraction(_G, _N_P, _VertexCoordinateV, _VertexCoordinateW, 0.0).

%! neighbor_attraction_dimension(
%!   +Graph,
%!   :N_P,
%!   +Dimension:integer,
%!   +VerticeCoordinateV:vertex_coordinate,
%!   +VerticeCoordinateW:vertice_coordiante,
%!   -DimensionAttraction:float
%! ) is det.
% Returns the attraction between vertices V and W for the given dimension.

neighbor_attraction_dimension(
  Graph,
  N_P,
  Dimension,
  vertex_coordinate(V, coordinate(Dimensions, PositionsV)),
  vertex_coordinate(W, coordinate(Dimensions, PositionsW)),
  DimensionAttraction
):-
  % Neighbor attraction between V and W in all dimensions.
  neighbor_attraction(
    Graph,
    N_P,
    vertex_coordinate(V, coordinate(Dimensions, PositionsV)),
    vertex_coordinate(W, coordinate(Dimensions, PositionsW)),
    Attraction
  ),

  % Neighbor attraction between V and W in the given dimension.
  nth0(Dimension, PositionsV, PositionV),
  nth0(Dimension, PositionsW, PositionW),
  euclidean_distance(
    coordinate(Dimension, PositionsV),
    coordinate(Dimension, PositionsW),
    CartesianDistance
  ),
  DimensionAttraction is
    Attraction * (abs(PositionW - PositionV) / CartesianDistance),

  debug(spring, '  d(~w,~w)=~w', [V, W, CartesianDistance]),
  debug(
    spring,
    '  F_att,~w(~w,~w)=~w',
    [Dimension, V, W, DimensionAttraction]
  ).

%! nonneighbor_repulsion(
%!   +Graph,
%!   :N_P,
%!   +VerticeCoordinateV:vertex_coordinate,
%!   +VerticeCoordinateW:vertex_coordinate,
%!   -Repulsion:float
%! ) is det.
% Returns the repulsion between V and W on in dimensions.

nonneighbor_repulsion(
  _G,
  _N_P,
  vertex_coordinate(_V, Coordinates),
  vertex_coordinate(_W, Coordinates),
  0.0
):- !.
nonneighbor_repulsion(
  G,
  N_P,
  vertex_coordinate(V, _CoordinatesV),
  vertex_coordinate(W, _CoordinatesW),
  0.0
):-
  % Single neighbor function.
  call(N_P, V, G, W), !.
nonneighbor_repulsion(
  _G,
  _N_P,
  vertex_coordinate(V, CoordinatesV),
  vertex_coordinate(W, CoordinatesW),
  Repulsion
):-
  euclidean_distance(CoordinatesV, CoordinatesW, CartesianDistance),
  debug(spring, '    d(~w,~w)=~w', [V, W, CartesianDistance]),
  Repulsion is 1 / sqrt(CartesianDistance),
  debug(spring, '    F_rep(~w,~w)=~w', [V, W, Repulsion]).

%! nonneighbor_repulsion_dimension(
%!   +Graph,
%!   :N_P,
%!   +Dimension:integer,
%!   +VerticeCoordinateV:vertex_coordinate,
%!   +VerticeCoordinateW:vertex_coordinate,
%!   -DimensionRepulsion:float
%! ) is det.
% Returns the repulsion between vertices V and W in the given dimension.

nonneighbor_repulsion_dimension(
  Graph,
  N_P,
  Dimension,
  vertex_coordinate(V, coordinate(Dimensions, PositionsV)),
  vertex_coordinate(W, coordinate(Dimensions, PositionsW)),
  DimensionRepulsion
):-
  % The repulsion between V and W in all dimensions.
  nonneighbor_repulsion(
    Graph,
    N_P,
    vertex_coordinate(V, coordinate(Dimensions, PositionsV)),
    vertex_coordinate(W, coordinate(Dimensions, PositionsW)),
    Repulsion
  ),

  % The repulsion between V and W in the given dimension.
  nth0(Dimension, PositionsV, PositionV),
  nth0(Dimension, PositionsW, PositionW),
  euclidean_distance(
    coordinate(Dimensions, PositionsV),
    coordinate(Dimensions, PositionsW),
    CartesianDistance
  ),
  DimensionRepulsion is
    Repulsion * (abs(PositionW - PositionV) / CartesianDistance),

  debug(spring, '  d(~w,~w)=~w', [V, W, CartesianDistance]),
  debug(spring, '  F_rep,~w(~w,~w)=~w', [Dimension, V, W, DimensionRepulsion]).

simple_spring_embedding(
  Graph, V_P, Iteration,
  FinalVerticeCoordinates, History
):-
  spring_embedding(
    Graph,
    V_P,
    [spring_embedding:neighbor_attraction_dimension],
    [spring_embedding:nonneighbor_repulsion_dimension],
    Iteration,
    FinalVerticeCoordinates,
    History
  ).


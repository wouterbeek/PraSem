:- module(
  rdf_script,
  [
    assert_visum/0
  ]
).

/** <module> RDF script

Scripts for asserting RDF graphs that can be used for debugging.

[[rdfs.png]]

@author Wouter Beek
@version 2012/12-2013/02, 2013/07
*/

:- use_remote_module(owl(owl_build)).
:- use_remote_module(rdf(rdf_build)).
:- use_remote_module(rdfs(rdfs_build)).
:- use_remote_module(xml(xml_namespace)).

:- xml_register_namespace(ch,  'http://www.wouterbeek.com/ch.owl#' ).
:- xml_register_namespace(dbp, 'http://www.wouterbeek.com/dbp.owl#').
:- xml_register_namespace(nl,  'http://www.wouterbeek.com/nl.owl#' ).



assert_visum:-
  G = visum,
  
  % Chinese namespace
  rdfs_assert_class(    ch:cityWithAirport,                     G),
  rdfs_assert_subclass( ch:capital,         ch:cityWithAirport, G),
  rdf_assert_individual(ch:'Amsterdam',     ch:capital,         G),
  rdfs_assert_class(    ch:visumNeeded,                         G),
  rdfs_assert_subclass( ch:europeanCity,    ch:visumNeeded,     G),
  rdf_assert_individual(ch:'Amsterdam',     ch:europeanCity,    G),
  
  % Dutch namespace
  rdfs_assert_class(    nl:europeanCity,                   G),
  rdfs_assert_subclass( nl:visumFree,    nl:europeanCity,  G),
  rdf_assert_individual(nl:'Amsterdam',  nl:europeanCity,  G),
  rdfs_assert_class(    nl:capital,                        G),
  rdf_assert_individual(nl:'Amsterdam',  nl:capital,       G),
  
  % Interrelations
  owl_assert_class_equivalence(ch:capital,      nl:capital,     G),
  owl_assert_resource_identity(dbp:'Amsterdam', ch:'Amsterdam', G),
  owl_assert_resource_identity(dbp:'Amsterdam', nl:'Amsterdam', G).

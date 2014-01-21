:- module(
  semuri_script,
  [
    semuri_script/0
  ]
).

/** <module> Semantic URIs script

Automated script that run the experiments for the project on Semantic URIs.

@author Wouter Beek
@version 2014/01
*/

:- use_module(ckan(data_gov_uk)). % Meta-call.
:- use_module(ckan(datahub_io)). % Meta-call.
:- use_module(ckan(rdf_tabular_ckan)). % Load Web interface.
:- use_module(generics(db_ext)).
:- use_module(generics(meta_ext)).
:- use_module(library(apply)).
:- use_module(os(dir_ext)).
:- use_module(rdf(rdf_lit_read)).
:- use_module(semuri(semuri_ap)).

:- debug(ckan).
:- debug(ckan_to_rdf).
:- debug(http).
:- debug(rdf_image).
:- debug(semuri).



ckan_site(datahub_io).
%ckan_site(data_gov_uk).

run_semuri_script:-
  create_nested_directory(data('CKAN')),
  db_add_novel(user:file_search_path(ckan_data, data('CKAN'))),
  forall(
    ckan_site(Site),
    semuri_site(Site)
  ).

semuri_site(Site):-
  create_nested_directory(ckan_data(Site)),
  db_add_novel(user:file_search_path(Site, ckan_data(Site))),
  scrape_ckan_site(Site, Resources),
  maplist(semuri_ap(Site), Resources).

semuri_script:-
  thread_create(run_semuri_script, _, []).

scrape_ckan_site(Site, Resources):-
  (
    absolute_file_name(
      ckan_data(Site),
      File1,
      [access(read),file_errors(fail),file_type(turtle)]
    )
  ->
    rdf_load2(File1, [format(turtle),graph(Site)])
  ;
    atomic_list_concat([Site,ckan_to_rdf], '_', Pred),
    call(Pred, [graph(Site)]),
    absolute_file_name(
      ckan_data(Site),
      File2,
      [access(write),file_type(turtle)]
    ),
    rdf_save2(File2, [format(turtle),graph(Site)])
  ),

  % Collect datasets.
  setoff(
    Resource,
    (
      rdfs_individual_of(Resource, ckan:'Resource'),
      (
        rdf_literal(Resource, ckan:format, Format, _),
        rdf_format(Format)
      ;
        rdf_literal(Resource, ckan:mimetype, Mimetype, _),
        rdf_mimetype(Mimetype)
      )
    ),
    Resources
  ),
  length(Resources, NumberOfResources),
  debug(
    semuri,
    'Now about to run experiments for ~d data resources.',
    [NumberOfResources]
  ).

rdf_format('RDF').
rdf_format('XML').
rdf_format('application/n-triples').
rdf_format('application/rdf+xml').
rdf_format('application/x-nquads').
rdf_format('application/x-ntriples').
rdf_format('example/n3').
rdf_format('example/ntriples').
rdf_format('example/rdf xml').
rdf_format('example/rdf+json').
rdf_format('example/rdf+json').
rdf_format('example/rdf+ttl').
rdf_format('example/rdf+xml').
rdf_format('example/rdfa').
rdf_format('example/turtle').
rdf_format('example/x-turtle').
rdf_format('html+rdfa').
rdf_format('linked data').
rdf_format('mapping/owl').
rdf_format('meta/owl').
rdf_format('meta/rdf-schema').
rdf_format('meta/void').
rdf_format(owl).
rdf_format('rdf-n3').
rdf_format('rdf-turtle').
rdf_format('rdf-xml').
rdf_format('rdf/n3').
rdf_format('rdf/turtle').
rdf_format('rdf/xml, html, json').
rdf_format('text/n3').
rdf_format('text/turtle').

rdf_mimetype('application/rdf+n3').
rdf_mimetype('application/rdf+xml').
rdf_mimetype('application/turtle').
rdf_mimetype('text/n3').
rdf_mimetype('text/json').
rdf_mimetype('text/rdf+n3').
rdf_mimetype('text/turtle').
rdf_mimetype('text/xml').


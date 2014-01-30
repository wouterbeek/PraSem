:- module(
  semuri_ap,
  [
    semuri_ap/2 % +Site:atom
                % +PackageURL:pair(atom,url)
  ]
).

/** <module> Semantic URIs Automated Processes

Automated processes for semantic URIs.

@author Wouter Beek
@tbd Load canonical XSD
@tbd OWL materialize (Jena JAR)
@tbd Steven (JAR)
@tbd Table output HTML
@version 2014/01
*/

:- use_module(ap(ap)).
:- use_module(generics(archive_ext)).
:- use_module(generics(meta_ext)).
:- use_module(generics(uri_ext)).
:- use_module(library(apply)).
:- use_module(library(filesex)).
:- use_module(library(http/json)).
:- use_module(library(lists)).
:- use_module(library(semweb/rdf_db)).
:- use_module(os(dir_ext)).
:- use_module(os(file_ext)).
:- use_module(os(file_mime)).
:- use_module(os(run_ext)).
:- use_module(rdf(rdf_datatype)).
:- use_module(rdf(rdf_graph_name)).
:- use_module(rdf(rdf_lit_build)).
:- use_module(rdf(rdf_lit_read)).
:- use_module(rdf(rdf_meta)).
:- use_module(rdf(rdf_serial)).
:- use_module(rdf(rdf_stat)).
:- use_module(xml(xml_namespace)).

:- xml_register_namespace(su, 'http://www.wouterbeek.com/semuri.owl#').
:- xml_register_namespace(void, 'http://rdfs.org/ns/void#').
:- xml_register_namespace(xsd, 'http://www.w3.org/2001/XMLSchema#').



semuri_ap(Site, Resource):-
  once(rdf_literal(Resource, ckan:url, URL, Site)),
  once(rdf_literal(Resource, ckan:id, ResourceId, Site)),
  once(rdf_literal(Resource, ckan:format, ResourceFormat, Site)),
  (
    once(rdf_literal(Resource, ckan:resource_type, ResourceType, Site))
  ->
    atomic_list_concat([ResourceId,ResourceFormat,ResourceType,URL], '\n', X1)
  ;
    atomic_list_concat([ResourceId,ResourceFormat,URL], '\n', X1)
  ),
  debug(semuri, 'Starting:\n~w', [X1]),

  once(rdf(Package, ckan:resources, Resource, Site)),
  once(rdf_literal(Package, ckan:name, PackageName, Site)),
  once(rdf_literal(Package, ckan:title, PackageTitle, Site)),
  atomic_list_concat([PackageName,PackageTitle], '\n', X2),

  once(rdf(Package, ckan:organization, Organization, Site)),
  once(rdf_literal(Organization, ckan:display_name, OrganizationName, Site)),

  setoff(
    UserName,
    (
      rdf(Organization, ckan:users, User, Site),
      rdf_literal(User, ckan:fullname, UserName, Site)
    ),
    UserNames
  ),
  atomic_list_concat(UserNames, '\n', UserName),

  setoff(
    TagName,
    (
      rdf(Package, ckan:tags, Tag, Site),
      rdf_literal(Tag, ckan:name, TagName, Site)
    ),
    TagNames
  ),
  atomic_list_concat(TagNames, '\n', TagName),

  % DEB
  flag(datasets, Id, Id + 1),
  format(user_output, '~w\n', [Id]),

  atomic_list_concat([Id,PackageName,ResourceId], '-', Name),
  Spec =.. [Site,Name],
  create_nested_directory(ckan_data(Spec)),
  db_add_novel(user:file_search_path(Name, Spec)),

  ap(
    Name,
    [
      ap_stage([], download_to_directory(URL)),
      ap_stage([], extract_archives),
      ap_stage([], mime_dir),
      ap_stage([], rdf_convert_directory),
      ap_stage([args([Resource,Site])], void_statistics),
      ap_stage([], preprocess),
      ap_stage([args([Resource,Site])], compress)
      %ap_stage([], compress_random_iris)
    ],
    T
  ),

  assert(semuri:row([X1,X2,OrganizationName,UserName,TagName|T])).


%compress_random_iris(FromDir, ToDir, ap(status(succeed),randomize_iris)):-
%  directory_files([file_types([turtle])], FromDir, FromFiles),
%  maplist(compress_random_iris, FromFiles),


void_statistics(
  FromDir,
  ToDir,
  ap(status(succeed),properties(OfFiles)),
  Resource,
  Site
):-
  directory_files([file_types([turtle])], FromDir, FromFiles),
  findall(
    of_file(ToFile,NVPairs),
    (
      member(FromFile, FromFiles),
      file_alternative(FromFile, ToDir, _, _, ToFile),
      rdf_setup_call_cleanup(
        [mime('application/x-turtle')],
        FromFile,
        void_stats(NVPairs, Resource, Site),
        [mime('application/x-turtle')],
        ToFile
      )
    ),
    OfFiles
  ).

void_stats(NVPairs, Resource, Site, Graph):-
  NVPairs = [
    nvpair(classes,NC),
    nvpair(subjects,NS),
    nvpair(properties,NP),
    nvpair(objects,NO),
    nvpair(triples,NT)
  ],
  count_classes(Graph, NC),
  rdf_assert_datatype(Resource, void:classes, xsd:integer, NC, Site),
  count_objects(_, _, Graph, NO),
  rdf_assert_datatype(Resource, void:distinctObjects, xsd:integer, NO, Site),
  count_subjects(_, _, Graph, NS),
  rdf_assert_datatype(Resource, void:distinctSubject, xsd:integer, NS, Site),
  count_properties(_, _, Graph, NP),
  rdf_assert_datatype(Resource, void:properties, xsd:integer, NP, Site),
  rdf_statistics(triples_by_graph(Graph, NT)),
  rdf_assert_datatype(Resource, void:triples, xsd:integer, NT, Site).


preprocess(FromDir, ToDir, ap(status(succeed),preprocess)):-
  absolute_file_name(semuri('RDFmodel'), JAR, [access(read),file_type(jar)]),
  run_jar(JAR, [preprocess,file(FromDir),file(ToDir)]).


compress(
  FromDir,
  _,
  ap(status(succeed),properties([of_file(File,NVPairs)])),
  Resource,
  Site
):-
  absolute_file_name(
    triples,
    File,
    [access(read),extensions([dat]),relative_to(FromDir)]
  ),
  absolute_file_name(semuri('RDFmodel'), JAR, [access(read),file_type(jar)]),
  run_jar(JAR, [compress,file(FromDir)]),
  
  maplist(
    file_to_nvpairs(FromDir, Resource, Site),
    [stats,compression],
    [NVPairs1,NVPairs2]
  ),
  append(NVPairs1, NVPairs2, NVPairs).

file_to_nvpairs(FromDir, Resource, Site, Base, NVPairs):-
  absolute_file_name(
    Base,
    StatisticsFile,
    [extensions([json]),relative_to(FromDir)]
  ),
  setup_call_cleanup(
    open(StatisticsFile, read, Stream),
    json_read_dict(Stream, Dict),
    close(Stream)
  ),
  findall(
    nvpair(Key,Value),
    (
      get_dict(Key, Dict, Value),
      rdf_global_id(su:Key, P),
      rdf_assert_literal(Resource, P, Value, Site)
    ),
    NVPairs
  ).


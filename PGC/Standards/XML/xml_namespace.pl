:- module(
  xml_namespace,
  [
    xml_current_namespace/1, % ?Prefix:atom
    xml_current_namespace/2, % ?Prefix:atom
                             % ?URI:uri
    xml_current_namespaces/1, % -Namespaces:ordset(atom)
    xml_register_namespace/1, % +Prefix:atom
    xml_register_namespace/2 % +Prefix:atom
                             % +URI:uri
  ]
).

/** <module> XML Namespace

The purpose of Namespaces for XML is to avoid name clashes between XML
vocabularies.

# XML Namespace

Identified by a URI reference [RFC 3986].

Attribute and element names may be placed in an XML namespace.

# Expanded name

A pair consisting of a namespace name and a local name.

## Namespace name

For a name N in a namespace identified by URI I, the namespace name is I.

Exception: The empty string, though a legal URI reference, cannot be used as
a namespace name.

Deprecated: The use of relative URI references in namespace declarations.

### Identity

Two URI references identify the same namespace iff their strings are
identical, without %-escaping and case-sentive.

Note: URI references that differ only in case or in %-escaping do not
identify identical namespace, but do resolve to the same resource.

### Declaration

~~~{.txt}
[1] NSAttName       ::= PrefixedAttName | DefaultAttName
[2] PrefixedAttName ::= 'xmlns:' NCName  [NSC: Reserved Prefixes and Namespace Names]
[3] DefaultAttName  ::= 'xmlns'
[4] NCName          ::= Name - (Char* ':' Char*)  [An XML Name, minus the ":"]
~~~

## Local name

For a name N in a namespace identified by URI I, the local name is N.

# Qualified name

A name subject to namespace interpretation.

URI references can contain characters that are not allowed in names.

@author Wouter Beek
@compat Namespaces in XML 1.0 (Third Edition)
@see http://www.w3.org/TR/xml-names/
@version 2013/05, 2013/07, 2014/01-2014/02
*/

:- use_module(generics(atom_ext)).
:- use_module(generics(db_ext)).
:- use_module(generics(typecheck)).
:- use_module(library(aggregate)).
:- use_module(library(semweb/rdf_db)).
:- use_module(library(www_browser)).

:- db_add_novel(user:prolog_file_type(xml, 'text/xml')).

% The prefix =xml= is by definition bound to the namespace name
% =http://www.w3.org/XML/1998/namespace=. It MAY, but need not, be declared,
% and MUST NOT be bound to any other namespace name. Other prefixes MUST NOT
% be bound to this namespace name, and it MUST NOT be declared as the
% default namespace.
:- rdf_register_prefix(xml, 'http://www.w3.org/XML/1998/namespace').
% The prefix =xmlns= is used only to declare namespace bindings and is by
% definition bound to the namespace name =http://www.w3.org/2000/xmlns/=.
% It MUST NOT be declared. Other prefixes MUST NOT be bound to this namespace
% name, and it MUST NOT be declared as the default namespace. Element names
% MUST NOT have the prefix =xmlns=.
:- rdf_register_prefix(xmlns, 'http://www.w3.org/2000/xmlns/').



% XML NAMESPACE REGISTRATION %

xml_current_namespace(Namespace):-
  xml_current_namespace(Namespace, _).

xml_current_namespace(Namespace, URI):-
  rdf_current_prefix(Namespace, URI).

%! xml_current_namespaces(-Namespaces:ordset(atom)) is det.
% Returns all current namespace aliases.
%
% @arg Namespaces A list of atomic alias names.

xml_current_namespaces(Namespaces):-
  aggregate_all(
    set(Namespace),
    rdf_current_prefix(Namespace, _URI),
    Namespaces
  ).

xml_register_namespace(Namespace):-
  Spec =.. [Namespace, '.'],
  expand_url_path(Spec, URI1),
  (
    sub_atom(URI1, _, 1, 0, '/')
  ;
    atomic_concat(URI1, '/', URI2)
  ),
  xml_register_namespace(Namespace, URI2).

%! xml_register_namespace(+Namespace:atom, +URI:uri) is det.
% Registers the given URI references are identifying the XML namespace
% with the given name.
%
% If the XML namespace is already registered with the given URI,
% then do nothing.
%
% @see http://www.w3.org/TR/xml-names/#xmlReserved
% @throws domain_error Reserved names cannot be registered.
%         These are =xml=, =xmlns=, and any name starting with =xml=
%         in any case-variant.
%
% @throws existence_error If the XML namespace is already registered with
%         another URI.

% Reserved XML namespaces cannot be registered.
% @see http://www.w3.org/TR/xml-names/#xmlReserved
xml_register_namespace(Namespace, _):-
  (
    memberchk(Namespace, [xml,xmlns])
  ;
    sub_atom(Namespace, 0, 3, _After, Prefix),
    downcase_atom(Prefix, xml)
  ), !,
  throw(
    error(
      domain_error(reserved_xml_namespace_value, Namespace),
      context(
        'xml_register_namespace/2',
        'Reserved XML namespace names cannot be registered.'
      )
    )
  ).
xml_register_namespace(Namespace, URI1):-
  must_be(iri, URI1),
  (
    % The XML namespace is already registered, so do nothing.
    rdf_current_prefix(Namespace, URI1)
  ->
    true
  ;
    % The XML namespace has already been registered to a different URI reference.
    rdf_current_prefix(Namespace, URI2),
    URI1 \== URI2
  ->
    throw(
      error(
        existence_error(xml_namespace_already_exists, Namespace),
        context(
          'xml_register_namespace/2',
          'The given namespace has already been registered to a different URI'
        )
      )
    )
  ;
    rdf_register_prefix(Namespace, URI1, [])
  ).


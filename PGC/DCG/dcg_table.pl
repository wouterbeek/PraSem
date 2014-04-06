:- module(
  dcg_table,
  [
    dcg_table//3, % +Options:list(nvpair),
                  % :Caption,
                  % +Rows:list(list(ground))
    dcg_table//4 % +Options:list(nvpair),
                 % :Caption,
                 % :Cell,
                 % +Rows:list(list(ground))
  ]
).

/** <module> DCG table

Generates tables for text-based display.

@author Wouter Beek
@version 2014/02
*/

:- use_remote_module(dcg(dcg_ascii)).
:- use_remote_module(dcg(dcg_content)).
:- use_remote_module(dcg(dcg_generic)).
:- use_remote_module(dcg(dcg_meta)).
:- use_module(library(option)).



%! dcg_table(
%!   +Options:list(nvpair),
%!   :Caption,
%!   +Rows:list(list(ground))
%! )// is det.
%! dcg_table(
%!   +Options:list(nvpair),
%!   :Caption,
%!   :Cell,
%!   +Rows:list(list(ground))
%! )// is det.
% Generates the HTML markup for a table.
%
% The following options are supported:
%   1. =|header_column(boolean)|=
%      Uses `th` tags for cells in the first column.
%      Default: `false`.
%   2. =|header_row(boolean)|=
%      Whether or not the first row should be
%      displayed as the table header row.
%      Default is `false`.
%   3. =|highlighted_row(:HighlightedRow)|=
%      A semidet predicate term that is missing its last parameter.
%      Default: `false` for no row highlighted.
%   4. =|indexed(+Indexed:boolean)|=
%      Whether or not each row should begin with a row index.
%      Counts starts at 0. The header row, if included, is not counted.
%      Default is `false`.

:- meta_predicate(dcg_table(:,//,+,?,?)).
dcg_table(O1, Caption, Rows) -->
  dcg_table(O1, Caption, atom, Rows).

:- meta_predicate(dcg_table(:,//,3,+,?,?)).
is_meta(highlighted_row).
dcg_table(O1, Caption, Cell, Rows) -->
  {
    flag(table_row, _, 0),
    meta_options(is_meta, O1, O2),
    option(header_column(HasHeaderColumn), O2, false),
    option(header_row(HasHeaderRow), O2, false),
    option(highlighted_row(HighlightedRow), O2, fail),
    option(indexed(IsIndexed), O2, false)
  },
  dcg_table_caption(Caption),
  horizontal_line(60), nl,
  dcg_table_header(HasHeaderRow, IsIndexed, Cell, Rows, DataRows),
  dcg_table_data_rows(
    HasHeaderColumn,
    IsIndexed,
    HighlightedRow,
    Cell,
    DataRows
  ),
  horizontal_line(60), nl.
fail(_):-
  fail.



% CAPTION %

%! dcg_table_caption(:Caption)// is det.
% Generates the table caption,
%  where the content of the caption element is set by a DCG rule.
%
% @arg Caption A DCG rule generating the content of the caption element,
%      or uninstantiated, in which case no caption is generated at all.

:- meta_predicate(dcg_table_caption(//,?,?)).
dcg_table_caption(VAR) -->
  {var(VAR)}, !,
  [].
dcg_table_caption(Caption) -->
  dcg_call(Caption),
  nl.



% CELL %

dcg_cell_border -->
  ` | `.

%! dcg_table_cells(
%!   +Type:oneof([data,header]),
%!   :Cell,
%!   +Elements:list(ground)
%! )// is det.

:- meta_predicate(dcg_table_cells(+,3,+,?,?)).
dcg_table_cells(Type, Cell, [H|T]) -->
  dcg_table_cell(Type, Cell, H),
  dcg_cell_border,
  dcg_table_cells(Type, Cell, T).
dcg_table_cells(_, _, []) --> [].


%! dcg_table_cell(
%!   +Type:oneof([data,header]),
%!   :Cell,
%!   +Element:ground
%! )// is det.
% Generated an the content for a table cell (both header and data).

:- meta_predicate(dcg_table_cell(+,3,+,?,?)).
dcg_table_cell(data, Cell, Element) -->
  dcg_call(Cell, Element),
  horizontal_tab.
dcg_table_cell(header, Cell, Element) -->
  dcg_between(`*`, dcg_call(Cell, Element)),
  horizontal_tab.



% DATA %

%! dcg_table_data_rows(
%!   +HasHeaderColumn:boolean,
%!   +IsIndexed:boolean,
%!   :Highlighted,
%!   :Cell,
%!   +DataRows
%! )// is det.

:- meta_predicate(dcg_table_data_rows(+,+,1,3,+,?,?)).
dcg_table_data_rows(HasHeaderColumn, IsIndexed, Highlighted, Cell, [H|T]) -->
  dcg_table_data_row(HasHeaderColumn, IsIndexed, Highlighted, Cell, H),
  dcg_table_data_rows(HasHeaderColumn, IsIndexed, Highlighted, Cell, T).
dcg_table_data_rows(_, _, _, _, []) -->
  [].


%! dcg_table_data_row(
%!   +HasHeaderColumn:boolean,
%!   +IsIndexed:boolean,
%!   :Highlighted,
%!   :Cell,
%!   +DataRows:list(list(ground))
%! )// is det.
% @tbd Set whether the row is highlighted or not.

:- meta_predicate(dcg_table_data_row(+,+,1,3,+,?,?)).
dcg_table_data_row(
  HasHeaderColumn,
  IsIndexed,
  Highlighted,
  Cell,
  DataRow
) -->
  {flag(table_row, RowNumber, RowNumber + 1)},
  (
    {call(Highlighted, RowNumber)}
  ->
    `` % @tbd
  ;
    `` % @tbd
  ),

  ({
    HasHeaderColumn == true,
    IsIndexed == false,
    DataRow = [HeaderCell|DataRow0]
  }->
    dcg_table_cell(header, Cell, HeaderCell),
    dcg_cell_border,
    dcg_table_cells(data, Cell, DataRow0)
  ;
    dcg_table_index_cell(HasHeaderColumn, IsIndexed, Cell, RowNumber),
    dcg_cell_border,
    dcg_table_cells(data, Cell, DataRow)
  ),
  nl.



% HEADER %

%! dcg_table_header(
%!   +HasHeaderRow:boolean,
%!   +IsIndexed:boolean,
%!   :Cell,
%!   +Rows:list(list(ground)),
%!   -DataRows:list(list(ground))
%! )// is det.

:- meta_predicate(dcg_table_header(+,+,3,+,-,?,?)).
% Options state a header row should be included.
% We take the first row, and return the other rows for later processing.
% Only add a header if the corresponding option says so.
dcg_table_header(true, IsIndexed, Cell, [HeaderRow1|DataRows], DataRows) --> !,
  % If the indexed option is set, then include a first header cell
  % indicating the index number column.
  {(
    IsIndexed == true
  ->
    HeaderRow2 = ['#'|HeaderRow1]
  ;
    HeaderRow2 = HeaderRow1
  )},
  dcg_table_header_row(Cell, HeaderRow2).
% In case the header option is not set, simply return the given rows.
dcg_table_header(false, _, _, DataRows, DataRows) --> [].


%! dcg_table_header_row(:Cell, +HeaderRow:list(ground))// is det.
% Generates the HTML table header row with given contents.

:- meta_predicate(dcg_table_header_row(3,+,?,?)).
dcg_table_header_row(Cell, HeaderRow) -->
  dcg_cell_border,
  dcg_table_cells(header, Cell, HeaderRow),
  nl,
  horizontal_line(60),
  nl.



% INDEX %

%! dcg_table_index_cell(
%!   +HasHeaderColumn:boolean,
%!   +IsIndexed:boolean,
%!   :Cell,
%!   +Index:ground
%! )// is det.

:- meta_predicate(dcg_table_index_cell(+,+,3,+,?,?)).
dcg_table_index_cell(HasHeaderColumn, true, Cell, Index) -->
  {(
    HasHeaderColumn == true
  ->
    Type = header
  ;
    Type = data
  )},
  dcg_table_cell(Type, Cell, Index).
dcg_table_index_cell(_, false, _, _) --> [].


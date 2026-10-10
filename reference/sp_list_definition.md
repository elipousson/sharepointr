# Read, write, and create SharePoint list definitions

**\[experimental\]**

A SharePoint list definition describes a list and its columns using
Microsoft Graph list and columnDefinition property names. Definitions
can be stored as YAML files, used to create a list with
`create_sp_list(definition = )`, and compared or synced with an existing
list using
[`compare_sp_list()`](https://elipousson.github.io/sharepointr/reference/compare_sp_list.md)
and
[`sync_sp_list()`](https://elipousson.github.io/sharepointr/reference/compare_sp_list.md).

- `read_sp_list_yaml()` reads and validates a YAML file.

- `write_sp_list_yaml()` writes a definition or an existing list to a
  YAML file.

- `get_sp_list_definition()` creates a definition from an existing list.

- `as_sp_list_definition()` validates a list with the same structure as
  a YAML file.

## Usage

``` r
read_sp_list_yaml(path, call = caller_env())

as_sp_list_definition(x, ..., display_name = NULL, call = caller_env())

get_sp_list_definition(
  sp_list = NULL,
  ...,
  keep_defaults = FALSE,
  read_only = "stable",
  include_views = FALSE,
  call = caller_env()
)

write_sp_list_yaml(
  x,
  path,
  ...,
  merge = TRUE,
  keep_defaults = FALSE,
  read_only = "stable",
  include_views = FALSE,
  doc_start = NULL,
  call = caller_env()
)
```

## Arguments

- path:

  Path to a YAML file.

- call:

  The execution environment of a currently running function, e.g.
  `caller_env()`. The function will be mentioned in error messages as
  the source of the error. See the `call` argument of
  [`abort()`](https://rlang.r-lib.org/reference/abort.html) for more
  information.

- x:

  For `write_sp_list_yaml()`, a `sp_list_definition` object or a
  `ms_list` object. For `as_sp_list_definition()`, a named list with the
  same structure as a YAML file or an unnamed list of column
  definitions.

- ...:

  Must be empty.

- display_name:

  List display name. Used by `as_sp_list_definition()` if `x` is an
  unnamed list of column definitions.

- sp_list:

  A `ms_list` object. If supplied, `list_name`, `list_id`, `site_url`,
  `site`, `drive_name`, `drive_id`, `drive`, and any additional
  parameters passed to `...` are all ignored.

- keep_defaults:

  If `FALSE` (default), drop properties with the default value returned
  by the Graph API (e.g. `required: false`) to keep definitions short.
  Properties that aren't included aren't compared by
  [`compare_sp_list()`](https://elipousson.github.io/sharepointr/reference/compare_sp_list.md).

- read_only:

  Read-only list properties to include as a reference to the existing
  list. One of `"stable"` (default) for properties that don't change
  after a list is created (`id`, `name`, `webUrl`, `createdDateTime`,
  `parentReference`, `sharepointIds`, and `system`), `"all"`, `"none"`,
  or a character vector of property names (e.g. `c("id", "createdBy")`).
  Column ids (and view ids) are included if `"id"` is included.
  `createdBy` and `lastModifiedBy` include the name and email of a
  person.

- include_views:

  If `TRUE`, include the list views (excluding hidden and personal
  views). Defaults to `FALSE`. Views are read with the SharePoint REST
  API, which requires a delegated (user) login. See
  [`list_sp_list_views()`](https://elipousson.github.io/sharepointr/reference/list_sp_list_views.md).

- merge:

  If `TRUE` (default) and `path` exists, keep the comment header and
  column order from the existing file. `custom` metadata for the list
  and each column comes from `x` if it has any and is otherwise kept
  from the existing file (a list never has `custom` metadata, so it's
  always kept when `x` is a `ms_list` object). Read-only list properties
  and column ids always come from `x`. Views come from `x` if it has
  views (e.g. with `include_views = TRUE`) and are otherwise kept from
  the existing file. Columns that are only in the existing file are
  dropped (unless the Graph API doesn't return their column type).
  Comments after the header are always lost.

- doc_start:

  If `TRUE`, write a document start marker (`---`) after the comment
  header (or at the start of a file with no header). If `FALSE`, don't.
  If `NULL` (default), write the marker only if the existing file has
  one (with `merge = TRUE`).

## Value

A `sp_list_definition` object: a list with `format_version`,
`displayName`, `description`, `list`, any read-only list properties,
`custom`, and `columns` elements. `write_sp_list_yaml()` invisibly
returns the definition that was written.

## Details

YAML format

    # Comments before the first key are kept by write_sp_list_yaml()
    ---
    format_version: 1
    displayName: Capital Project
    description: Capital projects and their status.
    list:
      template: genericList
    # Read-only properties of an existing list (optional)
    id: 5a8b3c4d-0000-0000-0000-000000000000
    webUrl: https://example.sharepoint.com/sites/Planning/Lists/CapitalProject
    parentReference:
      siteId: example.sharepoint.com,1111,2222
    custom:
      owner: Planning
    columns:
      - name: Title
        displayName: Project Name
        required: true
        text: {}
      - name: ProjectID
        displayName: Project ID
        description: Project reference ID
        required: true
        text: {}
      - name: Notes
        displayName: Project Notes
        text:
          allowMultipleLines: true
        custom:
          form_order: 2
      - name: Status
        choice:
          choices:
            - Active
            - Closed
          displayAs: radioButtons

Top-level keys use the Graph
[list](https://learn.microsoft.com/en-us/graph/api/resources/list?view=graph-rest-1.0)
property names:

- `displayName` (required): the list display name. SharePoint sets the
  read-only list `name` (used in the list URL) from the display name
  when a list is created. Changing the display name later doesn't change
  the URL.

- `columns` (required): a sequence of column definitions.

- `description` (optional): the list description.

- `list` (optional): list settings using the
  [listInfo](https://learn.microsoft.com/en-us/graph/api/resources/listinfo?view=graph-rest-1.0)
  property names `template` (e.g. `genericList`, the default, or
  `documentLibrary`), `hidden`, and `contentTypesEnabled`. The template
  can't be changed after a list is created.

- `format_version` (optional): the format version. Only `1` is
  supported.

- `custom` (optional): a mapping that isn't validated (see below).

Comments and blank lines before the first key are a header that
`write_sp_list_yaml()` keeps when it updates a file. An optional
document start marker (`---`) after the header marks where the header
ends. Other comments (including comments between `---` and the first
key) are lost when a file is rewritten, so use `custom` for notes that
need to be kept. A file can only have one YAML document.

Read-only list properties can also be included as a reference to an
existing list: `id`, `name`, `webUrl`, `createdDateTime`, `createdBy`,
`lastModifiedDateTime`, `lastModifiedBy`, `eTag`, `parentReference`,
`sharepointIds`, and `system`. These properties are never sent to
SharePoint.
[`compare_sp_list()`](https://elipousson.github.io/sharepointr/reference/compare_sp_list.md)
and
[`sync_sp_list()`](https://elipousson.github.io/sharepointr/reference/compare_sp_list.md)
use `id` and `parentReference.siteId` to get the list if `sp_list` isn't
supplied, and error if a supplied list has a different `id`.
[`create_sp_list()`](https://elipousson.github.io/sharepointr/reference/create_sp_list.md)
ignores them.

Columns can also include an `id` as a reference to an existing column.
Columns are always matched by `name`.

Column keys use the Graph
[columnDefinition](https://learn.microsoft.com/en-us/graph/api/resources/columndefinition?view=graph-rest-1.0)
property names:

- `name` (required): the internal column name. The name can't be changed
  after a column is created and should avoid names that look like
  spreadsheet cell references (e.g. `V4`). For a list (but not a
  document library), the name of a new column can't be longer than 32
  characters, counting each space or special character as 7 (e.g. a
  space is stored as `_x0020_`). SharePoint cuts longer names without an
  error, so
  [`create_sp_list()`](https://elipousson.github.io/sharepointr/reference/create_sp_list.md)
  and
  [`create_sp_list_column()`](https://elipousson.github.io/sharepointr/reference/create_sp_list_column.md)
  error instead. Display names can be longer: the column settings page
  allows up to 255 characters.

- `displayName`, `description`, `required`, `enforceUniqueValues`,
  `hidden`, `indexed`, `readOnly`, `defaultValue` (with `value` or
  `formula`), and `validation` (see
  [`column_validation()`](https://elipousson.github.io/sharepointr/reference/column_validation.md)).

- Exactly one column type key holding the properties for that type. Use
  an empty mapping ([`{}`](https://rdrr.io/r/base/Paren.html)) for a
  type with no properties.

A `Title` column updates the default title column of a `genericList`
list instead of adding a new column.

Column type keys and properties:

|  |  |
|----|----|
| Type key | Properties |
| `text` | `allowMultipleLines`, `appendChangesToExistingText`, `linesForEditing`, `maxLength`, `textType` |
| `choice` | `allowTextEntry`, `choices`, `displayAs` |
| `number` | `decimalPlaces`, `displayAs`, `maximum`, `minimum` |
| `dateTime` | `displayAs`, `format` |
| `currency` | `locale` |
| `calculated` | `formula`, `outputType`, `format` |
| `lookup` | `listId`, `columnName`, `allowMultipleValues`, `allowUnlimitedLength`, `primaryLookupColumnId` |
| `personOrGroup` | `allowMultipleSelection`, `chooseFromType`, `displayAs` |
| `hyperlinkOrPicture` | `isPicture` |
| `term` | `allowMultipleValues`, `showFullyQualifiedName` |
| `boolean`, `geolocation`, `thumbnail` | none |

Validation rules:

- Unknown keys are errors, with a hint for common alternatives (e.g.
  `label` for `displayName`). Read-only properties (e.g. `id`) are
  errors.

- Values must match the type and allowed values in the Graph API
  documentation.

- A `calculated` column requires `formula` and `outputType`. `format` is
  only allowed when `outputType` is `dateTime`.

- A `lookup` column requires `listId` and `columnName`. The `listId` is
  specific to a site.

- Column names must be unique. Duplicate display names are a warning
  since formulas reference columns by display name.

Keys that aren't columnDefinition properties go under `custom`, either
for the list or for each column. sharepointr doesn't validate `custom`
and doesn't send it to SharePoint, so it can hold metadata used by other
applications (e.g. form order or app-enforced choices).

Properties that aren't included in a column definition aren't compared
or changed by
[`sync_sp_list()`](https://elipousson.github.io/sharepointr/reference/compare_sp_list.md).
Removing a property from a file doesn't reset it to the default value.

List views

An optional `views` key holds a sequence of list views using the
SharePoint REST API SP.View property names (see
[`list_sp_list_views()`](https://elipousson.github.io/sharepointr/reference/list_sp_list_views.md)):

    views:
      - Title: Active Projects
        DefaultView: true
        ViewFields:
          - LinkTitle
          - ProjectStatus
          - Budget
        ViewQuery: <Where><Eq><FieldRef Name="ProjectStatus"/><Value Type="Choice">Active</Value></Eq></Where>
        RowLimit: 50
        CustomFormatter:
          additionalRowClass: sp-field-severity--good

- `Title` is required and must be unique. Only one view can set
  `DefaultView: true`.

- Other properties are `ViewFields` (internal column names), `ViewQuery`
  (a CAML query), `RowLimit`, `Paged`, `Scope`, `Hidden`, `MobileView`,
  `MobileDefaultView`, and `CustomFormatter` (view formatting as a YAML
  mapping or a JSON string). `Id` and `ServerRelativeUrl` can be
  included as a reference to an existing view.

- A warning is given if a view shows fields that aren't columns in the
  definition or built-in fields (e.g. `LinkTitle`, `ID`, or `Modified`).

`create_sp_list(definition = )` creates views after creating the
columns. A view titled `All Items` updates the default view of a new
`genericList` list.
[`compare_sp_list()`](https://elipousson.github.io/sharepointr/reference/compare_sp_list.md)
and
[`sync_sp_list()`](https://elipousson.github.io/sharepointr/reference/compare_sp_list.md)
compare and update views only if the definition has a `views` element.
Views are only written by `write_sp_list_yaml()` if
`include_views = TRUE`.

## See also

[`sp_list_definition_table()`](https://elipousson.github.io/sharepointr/reference/sp_list_definition_table.md)
to convert a definition to a data frame.

## Examples

``` r
path <- system.file("extdata", "example-list.yaml", package = "sharepointr")

definition <- read_sp_list_yaml(path)

definition
#> <sp_list_definition> Example Projects (genericList)
#> Example list of projects.
#> 9 columns: boolean (1), calculated (1), choice (1), currency (1), dateTime (1),
#> number (1), text (3)

sp_list_definition_table(definition)
#>          list_name          name      displayName          description
#> 1 Example Projects         Title     Project Name                 <NA>
#> 2 Example Projects     ProjectID       Project ID Project reference ID
#> 3 Example Projects  ProjectNotes    Project Notes                 <NA>
#> 4 Example Projects ProjectStatus           Status                 <NA>
#> 5 Example Projects     StartDate       Start Date                 <NA>
#> 6 Example Projects        Budget           Budget                 <NA>
#> 7 Example Projects        Phases Number of Phases                 <NA>
#> 8 Example Projects      IsActive           Active                 <NA>
#> 9 Example Projects    BudgetText       Budget ($)                 <NA>
#>         type required enforceUniqueValues indexed maxLength form_order section
#> 1       text     TRUE                  NA      NA        NA         NA    <NA>
#> 2       text     TRUE                TRUE    TRUE        20          1 Summary
#> 3       text       NA                  NA      NA        NA          2 Summary
#> 4     choice       NA                  NA      NA        NA          3    <NA>
#> 5   dateTime       NA                  NA      NA        NA         NA    <NA>
#> 6   currency       NA                  NA      NA        NA         NA    <NA>
#> 7     number       NA                  NA      NA        NA         NA    <NA>
#> 8    boolean       NA                  NA      NA        NA         NA    <NA>
#> 9 calculated       NA                  NA      NA        NA         NA    <NA>
#>   allowMultipleLines                  choices    displayAs   format locale
#> 1                 NA                     NULL         <NA>     <NA>   <NA>
#> 2                 NA                     NULL         <NA>     <NA>   <NA>
#> 3               TRUE                     NULL         <NA>     <NA>   <NA>
#> 4                 NA Planning, Active, Closed radioButtons     <NA>   <NA>
#> 5                 NA                     NULL         <NA> dateOnly   <NA>
#> 6                 NA                     NULL         <NA>     <NA>  en-us
#> 7                 NA                     NULL         <NA>     <NA>   <NA>
#> 8                 NA                     NULL         <NA>     <NA>   <NA>
#> 9                 NA                     NULL         <NA>     <NA>   <NA>
#>   decimals decimalPlaces minimum                                        formula
#> 1     <NA>          <NA>      NA                                           <NA>
#> 2     <NA>          <NA>      NA                                           <NA>
#> 3     <NA>          <NA>      NA                                           <NA>
#> 4     <NA>          <NA>      NA                                           <NA>
#> 5     <NA>          <NA>      NA                                           <NA>
#> 6     none          <NA>      NA                                           <NA>
#> 7     <NA>          none       0                                           <NA>
#> 8     <NA>          <NA>      NA                                           <NA>
#> 9     <NA>          <NA>      NA =IF(ISBLANK([Budget]),"",USDOLLAR([Budget],0))
#>   outputType
#> 1       <NA>
#> 2       <NA>
#> 3       <NA>
#> 4       <NA>
#> 5       <NA>
#> 6       <NA>
#> 7       <NA>
#> 8       <NA>
#> 9       text
```

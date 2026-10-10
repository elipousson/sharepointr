# Compare or sync a list definition with an existing SharePoint list

**\[experimental\]**

`compare_sp_list()` compares a list definition (e.g. from a YAML file
read with
[`read_sp_list_yaml()`](https://elipousson.github.io/sharepointr/reference/sp_list_definition.md))
with an existing SharePoint list and returns the list settings, columns,
and views to add, update, or delete.

`sync_sp_list()` applies those changes. By default, it only prints the
planned changes (`dry_run = TRUE`) and doesn't delete columns or views
(`delete = FALSE`).

## Usage

``` r
compare_sp_list(
  definitions,
  sp_list = NULL,
  ...,
  views = TRUE,
  call = caller_env()
)

sync_sp_list(
  definitions,
  sp_list = NULL,
  ...,
  dry_run = TRUE,
  delete = FALSE,
  allow_data_loss = FALSE,
  views = TRUE,
  call = caller_env()
)
```

## Arguments

- definitions:

  A list definition: a `sp_list_definition` object (see
  [`read_sp_list_yaml()`](https://elipousson.github.io/sharepointr/reference/sp_list_definition.md)),
  a path to a YAML file, or a list of column definitions created with
  [`create_column_definition()`](https://elipousson.github.io/sharepointr/reference/create_column_definition.md)
  or
  [`create_column_definition_list()`](https://elipousson.github.io/sharepointr/reference/create_column_definition_list.md).

- sp_list:

  A `ms_list` object. If `NULL`, the list is retrieved with
  [`get_sp_list()`](https://elipousson.github.io/sharepointr/reference/sp_list.md)
  using the definition `id` (with the site from `parentReference.siteId`
  or from additional arguments passed to `...`) or, if the definition
  has no `id`, the definition `displayName` and any additional arguments
  passed to `...`. If the definition has an `id`, it must match the `id`
  of `sp_list`. For `compare_sp_list()`, `sp_list` can also be a list of
  column metadata from `get_sp_list_metadata(as_data_frame = FALSE)`
  (only columns are compared).

- ...:

  Additional parameters passed to
  [`get_sp_list()`](https://elipousson.github.io/sharepointr/reference/sp_list.md)
  if `sp_list` is `NULL`.

- views:

  If `TRUE` (default), compare views if the definition has a `views`
  element. If `FALSE`, views are skipped.

- call:

  The execution environment of a currently running function, e.g.
  `caller_env()`. The function will be mentioned in error messages as
  the source of the error. See the `call` argument of
  [`abort()`](https://rlang.r-lib.org/reference/abort.html) for more
  information.

- dry_run:

  If `TRUE` (default), print the planned changes without changing the
  list.

- delete:

  If `TRUE`, delete columns and views that aren't in the definitions.
  Defaults to `FALSE`.

- allow_data_loss:

  If `TRUE`, apply changes that may cause data loss (see details).
  Defaults to `FALSE`.

## Value

`compare_sp_list()` returns a data frame with one row per added or
deleted column or view and one row per changed property, with columns:

- `object`: `"list"`, `"column"`, or `"view"`.

- `name`: list display name, internal column name, or view title.

- `id`: column or view ID for existing columns and views.

- `action`: one of `"add"`, `"update"`, `"delete"`, `"blocked"`, or
  `"unverified"`.

- `property`: changed property, e.g. `"displayName"`,
  `"text.allowMultipleLines"`, `"list.hidden"`, or `"RowLimit"`.

- `current`, `proposed`: list columns with the current and proposed
  values.

- `method`: `"graph"` or `"rest"` for changes that can be applied.

- `data_loss`: `TRUE` if the change may cause data loss.

- `note`: explanation for blocked, unverified, or data loss changes.

`sync_sp_list()` invisibly returns the same data frame with a `status`
column: `"planned"` (for a dry run), `"applied"`, `"skipped"`,
`"blocked"`, or `"failed"`.

## Details

Comparing columns

Columns are matched by internal name (`name`). Only the properties
included in a definition are compared, so a definition with `text: {}`
matches any text column. A property missing from a definition isn't
changed.

SharePoint internal columns and the `Title` column are excluded unless
`Title` is included in the definitions. Columns in the list that aren't
in the definitions are returned with `action = "delete"`.

Each change has one of these actions:

- `"add"`: the column or view isn't in the list.

- `"update"`: a property is different.

- `"delete"`: the column or view isn't in the definitions.

- `"blocked"`: the change can't be made. This includes changing the
  column type (e.g. text to number), changing a lookup column's source
  list, adding a column type the Graph API can't create, changing the
  list template, and removing the default view without setting another
  default view.

- `"unverified"`: the current value can't be read with the Graph API.
  This includes `validation` (which `sync_sp_list()` applies every time)
  and columns where the Graph API doesn't return the column type
  (hyperlink, picture, thumbnail, and term columns).

A column's internal name can't be changed. A renamed column is returned
as a column to add and a column to delete.

If `sp_list` is a `ms_list` object and `definitions` is a list
definition, the list `displayName`, `description`, and `list` settings
(`hidden` and `contentTypesEnabled`) are also compared. A different
`template` is blocked since the template can't be changed after a list
is created.

Comparing views

Views are only compared if the definition has a `views` element and
`views = TRUE`. A definition without views never adds, changes, or
deletes views.

Views are matched by `Id` (if included in the definition) or `Title`, so
a view with an `Id` can be renamed. Only the properties included in a
view definition are compared. Hidden and personal views are excluded,
and views in the list that aren't in the definition are returned with
`action = "delete"`.

Setting `DefaultView: true` makes a view the default view (and the
current default view is no longer the default). The current default view
can't be removed from the default or deleted unless another view is set
as the default view. Changes are applied in this order: new views,
updated views, the default view, and then deleted views.

Views are read and changed with the SharePoint REST API. Use
`views = FALSE` to skip views (e.g. if the SharePoint REST API isn't
available).

Changes that use the SharePoint REST API

SharePoint stores single and multiple lines of text and single and
multiple choice columns as different field types, and the Graph API
can't change them. These changes use the SharePoint REST API
(`method = "rest"`):

- `text.allowMultipleLines`: switching to multiple lines keeps existing
  values. Switching to a single line truncates values longer than 255
  characters, so it is skipped unless `allow_data_loss = TRUE`.

- `choice.displayAs` to or from `"checkBoxes"`: switching to multiple
  choice keeps existing values. Switching to a single choice may drop
  values from items with more than one choice, so it is skipped unless
  `allow_data_loss = TRUE`.

- `validation`: the Graph API can't create or update column validation.

- All view changes.

The SharePoint REST API requires a delegated (user) login with a refresh
token, such as the default Microsoft365R login.

## Examples

``` r
if (FALSE) { # \dontrun{
definition <- read_sp_list_yaml("list-fields/capital-project.yaml")

compare_sp_list(definition, site_url = "<SharePoint site url>")

# Print planned changes
sync_sp_list(definition, site_url = "<SharePoint site url>")

# Apply changes
sync_sp_list(
  definition,
  site_url = "<SharePoint site url>",
  dry_run = FALSE
)
} # }
```

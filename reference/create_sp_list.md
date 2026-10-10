# Create, update, or delete a SharePoint List

`create_sp_list()` allows the creation of a SharePoint list for a site.
See:
<https://learn.microsoft.com/en-us/graph/api/list-create?view=graph-rest-1.0&tabs=http>

`update_sp_list()` allows the modification of the list display name and
description.

`delete_sp_list()` deletes an existing list and requires user
confirmation by default.

Notes on creating a SharePoint list:

- Dashes (\`"-"“) in list names are removed from the list name but
  retained in the list display name.

- Calculated columns are added after the list is created since formulas
  may reference other columns.

- Column validation is applied with the SharePoint REST API after the
  list is created since the Graph API doesn't support it.

- A `"Title"` column in `columns` or `definition` updates the default
  `"Title"` column of a `"genericList"` list (combined with
  `title_definition`) instead of adding a new column.

- Views in `definition` are created with the SharePoint REST API after
  the columns are created. A view titled `"All Items"` updates the
  default view of a `"genericList"` list.

Notes on updating a SharePoint list:

- The `"Title"` column type is always a "text" type column and can't be
  changed.

## Usage

``` r
create_sp_list(
  list_name = NULL,
  ...,
  description = NULL,
  columns = NULL,
  template = NULL,
  content_types = NULL,
  hidden = NULL,
  title_definition = list(required = FALSE),
  definition = NULL,
  site_url = NULL,
  site = NULL,
  call = caller_env()
)

update_sp_list(
  list_name = NULL,
  list_id = NULL,
  sp_list = NULL,
  display_name = NULL,
  description = NULL,
  ...,
  site_url = NULL,
  site = NULL,
  drive_name = NULL,
  drive_id = NULL,
  drive = NULL,
  call = caller_env()
)

delete_sp_list(
  list_name = NULL,
  list_id = NULL,
  sp_list = NULL,
  confirm = TRUE,
  ...,
  site_url = NULL,
  site = NULL,
  drive_name = NULL,
  drive_id = NULL,
  drive = NULL,
  call = caller_env()
)
```

## Arguments

- list_name:

  List name used as `displayName` property. Required unless `definition`
  is supplied.

- ...:

  Additional parameters passed to
  [`get_sp_site()`](https://elipousson.github.io/sharepointr/reference/sp_site.md)
  or
  [`Microsoft365R::get_sharepoint_site()`](https://rdrr.io/pkg/Microsoft365R/man/client.html).

- description:

  Optional description.

- columns:

  Optional. Use
  [`create_column_definition()`](https://elipousson.github.io/sharepointr/reference/create_column_definition.md)
  to create a single column definition or
  [`create_column_definition_list()`](https://elipousson.github.io/sharepointr/reference/create_column_definition_list.md)
  to create a list of column definitions. `custom` metadata is dropped.
  A `sp_list_definition` object is used as `definition`.

- template:

  Optional list template (Graph listInfo property `template`). Defaults
  to `"genericList"`.

- content_types:

  Optional. Set `TRUE` for `contentTypesEnabled` to be enabled.

- hidden:

  Optional. Set `TRUE` for list to be hidden.

- title_definition:

  Named list used to update the column definition of the default
  `"Title"` column created when using the `"genericList"` template. By
  default, makes Title column optional.

- definition:

  Optional. A list definition from
  [`read_sp_list_yaml()`](https://elipousson.github.io/sharepointr/reference/sp_list_definition.md)
  or a path to a YAML file. The definition `displayName`, `description`,
  `columns`, and `list` settings (`template`, `hidden`, and
  `contentTypesEnabled`) are used unless the matching argument is
  supplied. Read-only list properties (e.g. `id`) and column ids are
  ignored. `definition` can't be combined with `columns`. Views in the
  definition are also created (see
  [`list_sp_list_views()`](https://elipousson.github.io/sharepointr/reference/list_sp_list_views.md)).

- site_url:

  A SharePoint site URL in the format "https://\[tenant
  name\].sharepoint.com/sites/\[site name\]". Any SharePoint item or
  document URL can also be parsed to build a site URL using the tenant
  and site name included in the URL.

- site:

  A `ms_site` object. If `site` is supplied, `site_url`, `site_name`,
  and `site_id` are ignored.

- call:

  The execution environment of a currently running function, e.g.
  `caller_env()`. The function will be mentioned in error messages as
  the source of the error. See the `call` argument of
  [`abort()`](https://rlang.r-lib.org/reference/abort.html) for more
  information.

- list_id:

  List ID for list to update or delete.

- sp_list:

  A
  [`Microsoft365R::ms_list`](https://rdrr.io/pkg/Microsoft365R/man/ms_list.html)
  object.

- display_name:

  Display name to replace existing display name. Used by
  `update_sp_list()`.

- drive_name, drive_id:

  SharePoint Drive name or ID passed to `get_drive` method for
  SharePoint site object.

- drive:

  A `ms_drive` object. If `drive` is supplied, `drive_name` and
  `drive_id` are ignored.

- confirm:

  If `TRUE`, confirm deletion of list before proceeding.

## Value

For `create_sp_list()`, invisibly returns a `ms_list` object for the
newly created list. For `update_sp_list()`, the updated `ms_list`
object. For `delete_sp_list()`, invisibly returns `NULL`.

## Examples

``` r
if (FALSE) { # \dontrun{
create_sp_list(
  definition = "list-fields/capital-project.yaml",
  site_url = "<SharePoint site url>"
)
} # }
```

# List, get, create, update, or delete SharePoint list views

**\[experimental\]**

- `list_sp_list_views()` lists the views for a SharePoint list.

- `get_sp_list_view()` gets a single view by title or ID (or the default
  view).

- `create_sp_list_view()` creates a view.

- `update_sp_list_view()` updates a view. Only properties that differ
  from the existing view are changed.

- `delete_sp_list_view()` deletes a view. The default view can't be
  deleted.

The Graph API doesn't support list views, so these functions use the
SharePoint REST API and require a delegated (user) login with a refresh
token, such as the default Microsoft365R login. View properties use the
SharePoint REST API
[SP.View](https://learn.microsoft.com/en-us/previous-versions/office/sharepoint-csom/jj244979(v=office.15))
property names (e.g. `ViewFields` or `RowLimit`) and the arguments use
the same names in snake case (e.g. `view_fields` or `row_limit`).

## Usage

``` r
list_sp_list_views(
  sp_list = NULL,
  ...,
  hidden = FALSE,
  as_data_frame = TRUE,
  list_name = NULL,
  site_url = NULL,
  site = NULL,
  call = caller_env()
)

get_sp_list_view(
  sp_list = NULL,
  view_title = NULL,
  view_id = NULL,
  ...,
  list_name = NULL,
  site_url = NULL,
  site = NULL,
  call = caller_env()
)

create_sp_list_view(
  sp_list = NULL,
  title = NULL,
  ...,
  view_fields = NULL,
  view_query = NULL,
  row_limit = NULL,
  paged = NULL,
  default_view = NULL,
  hidden = NULL,
  scope = NULL,
  custom_formatter = NULL,
  view_definition = NULL,
  list_name = NULL,
  site_url = NULL,
  site = NULL,
  call = caller_env()
)

update_sp_list_view(
  sp_list = NULL,
  view_title = NULL,
  view_id = NULL,
  ...,
  title = NULL,
  view_fields = NULL,
  view_query = NULL,
  row_limit = NULL,
  paged = NULL,
  default_view = NULL,
  hidden = NULL,
  scope = NULL,
  custom_formatter = NULL,
  view_definition = NULL,
  list_name = NULL,
  site_url = NULL,
  site = NULL,
  call = caller_env()
)

delete_sp_list_view(
  sp_list = NULL,
  view_title = NULL,
  view_id = NULL,
  ...,
  confirm = TRUE,
  list_name = NULL,
  site_url = NULL,
  site = NULL,
  call = caller_env()
)
```

## Arguments

- sp_list:

  A `ms_list` object. If `NULL`, the list is retrieved with
  [`get_sp_list()`](https://elipousson.github.io/sharepointr/reference/sp_list.md)
  using `list_name` and any additional arguments passed to `...`.

- ...:

  Additional arguments passed to
  [`get_sp_list()`](https://elipousson.github.io/sharepointr/reference/sp_list.md)
  if `sp_list` is `NULL`.

- hidden:

  For `list_sp_list_views()`, if `TRUE`, include hidden views. For
  `create_sp_list_view()` and `update_sp_list_view()`, if `TRUE`, hide
  the view. SP.View property: `Hidden`.

- as_data_frame:

  If `TRUE` (default), return a data frame with one row per view and a
  `ViewFields` list column. If `FALSE`, return a list of views.

- list_name:

  List name or URL. Used to get the list if `sp_list` is `NULL`.

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

- view_title, view_id:

  Title or ID of an existing view. If both are `NULL`,
  `get_sp_list_view()` returns the default view.

- title:

  View title. Required for `create_sp_list_view()` unless supplied with
  `view_definition`. For `update_sp_list_view()`, a new title for the
  view. SP.View property: `Title`.

- view_fields:

  Character vector of internal column names to show in the view, in
  order. Use `"LinkTitle"` for the title column with a link to the item.
  For `create_sp_list_view()`, defaults to the fields of the default
  view. SP.View property: `ViewFields`.

- view_query:

  A CAML query used to filter, sort, or group items (see details).
  SP.View property: `ViewQuery`.

- row_limit:

  Number of items to show per page. SP.View property: `RowLimit`.

- paged:

  If `TRUE`, show items in pages of `row_limit` items. SP.View property:
  `Paged`.

- default_view:

  If `TRUE`, make the view the default view for the list. The current
  default view is no longer the default. SP.View property:
  `DefaultView`.

- scope:

  For lists with folders, whether to show items in folders. One of `0`
  (default), `1` (recursive), `2` (recursive all), or `3` (files only).
  SP.View property: `Scope`.

- custom_formatter:

  JSON view formatting as a JSON string or a list. See [Use view
  formatting to customize
  SharePoint](https://learn.microsoft.com/en-us/sharepoint/dev/declarative-customization/view-formatting).
  SP.View property: `CustomFormatter`.

- view_definition:

  Optional. A named list of SP.View properties (e.g.
  `list(Title = "Active", RowLimit = 50)`). Used in place of the other
  view arguments.

- confirm:

  If `TRUE` (default), ask for confirmation before deleting a view.

## Value

`list_sp_list_views()` returns a data frame or a list of views.
`get_sp_list_view()`, `create_sp_list_view()`, and
`update_sp_list_view()` return a named list of SP.View properties (`Id`,
`Title`, `ViewFields`, `ViewQuery`, `RowLimit`, `DefaultView`, and other
properties). `delete_sp_list_view()` invisibly returns `NULL`.

## Details

View queries

`view_query` is a
[CAML](https://learn.microsoft.com/en-us/sharepoint/dev/schema/query-schema)
query with optional `<Where>`, `<OrderBy>`, and `<GroupBy>` elements
(but without an enclosing `<Query>` element). Reference columns by
internal name. For example, to show active items sorted by amount:

    <Where><Eq><FieldRef Name="Status"/><Value Type="Choice">Active</Value></Eq></Where>
    <OrderBy><FieldRef Name="Amount" Ascending="FALSE"/></OrderBy>

Limitations

- Board, gallery, and calendar views can be listed but their layout
  settings can't be changed.

- Personal views can be listed but not created.

- Hidden views include list form settings (e.g. a hidden "Untitled Form"
  view holds custom form formatting) and are excluded by default.

- Changing view fields removes and re-adds every field. If a request
  fails partway through, call `update_sp_list_view()` again.

- Renaming a view doesn't change the view URL.

## Examples

``` r
if (FALSE) { # \dontrun{
list_sp_list_views(list_name = "Projects", site_url = "<SharePoint site url>")

create_sp_list_view(
  sp_list,
  title = "Active Projects",
  view_fields = c("LinkTitle", "Status", "Amount"),
  view_query = '<Where><Eq><FieldRef Name="Status"/>
    <Value Type="Choice">Active</Value></Eq></Where>',
  row_limit = 50
)

update_sp_list_view(
  sp_list,
  view_title = "Active Projects",
  default_view = TRUE
)
} # }
```

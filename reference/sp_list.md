# Get a SharePoint list or a list of SharePoint lists

`get_sp_list()` is a wrapper for the `get_list` and `list_items`
methods. This function is still under development and does not support
the URL parsing used by
[`get_sp_item()`](https://elipousson.github.io/sharepointr/reference/get_sp_item.md).
`list_sp_lists()` returns all lists for a SharePoint site or drive as a
list or data frame. Note, when using `filter` with `get_sp_list()`,
names used in the expression must be prefixed with "fields/" to
distinguish them from item metadata.

## Usage

``` r
get_sp_list(
  list_name = NULL,
  list_id = NULL,
  ...,
  site_url = NULL,
  site = NULL,
  drive_name = NULL,
  drive_id = NULL,
  drive = NULL,
  metadata = FALSE,
  as_data_frame = FALSE,
  call = caller_env()
)

list_sp_lists(
  site_url = NULL,
  filter = NULL,
  n = Inf,
  ...,
  site = NULL,
  drive_name = NULL,
  drive_id = NULL,
  drive = NULL,
  as_data_frame = TRUE,
  call = caller_env()
)

get_sp_list_metadata(
  list_name = NULL,
  list_id = NULL,
  sp_list = NULL,
  ...,
  keep = c("all", "editable", "external"),
  sync_fields = FALSE,
  site_url = NULL,
  site = NULL,
  drive_name = NULL,
  drive_id = NULL,
  drive = NULL,
  call = caller_env()
)
```

## Arguments

- list_name, list_id:

  SharePoint List name or ID string.

- ...:

  Arguments passed on to
  [`get_sp_drive`](https://elipousson.github.io/sharepointr/reference/sp_drive.md)

  `drive_url`

  :   A SharePoint Drive URL to parse for a Drive name and other
      information. If `drive_name` is a URL, it is used as `drive_url`.

  `default_drive_name`

  :   Drive name string used only if input is a document URL and drive
      name is not part of the URL. Defaults to
      `getOption("sharepointr.default_drive_name", "Documents")`

  `cache`

  :   If `TRUE`, cache drive to a file using
      [`cache_sp_drive()`](https://elipousson.github.io/sharepointr/reference/sp_drive.md).

  `refresh`

  :   If `TRUE`, get a new drive even if the existing drive is cached as
      a local option. If `FALSE`, use the cached `ms_drive` object if it
      exists.

  `cache_file`

  :   File name for cached drive or site. Default `NULL`.

  `overwrite`

  :   If `TRUE`, replace the existing cached object named by
      `cache_file` with the new object. If `FALSE`, error if a cached
      file with the same `cache_file` name already exists.

- site_url:

  A SharePoint site URL in the format "https://\[tenant
  name\].sharepoint.com/sites/\[site name\]". Any SharePoint item or
  document URL can also be parsed to build a site URL using the tenant
  and site name included in the URL.

- site:

  A `ms_site` object. If `site` is supplied, `site_url`, `site_name`,
  and `site_id` are ignored.

- drive_name, drive_id:

  SharePoint Drive name or ID passed to `get_drive` method for
  SharePoint site object.

- drive:

  A `ms_drive` object. If `drive` is supplied, `drive_name` and
  `drive_id` are ignored.

- metadata:

  If `TRUE`, `get_sp_list()` applies the `get_column_info` method to the
  returned SharePoint list and returns a data frame with column metadata
  for the list.

- as_data_frame:

  If `TRUE`, return a data frame with a "ms_list" column.
  `get_sp_list()` returns a 1 row data frame and `list_sp_lists()`
  returns a data frame with n rows or all lists available for the
  SharePoint site or drive. Defaults to `FALSE`. Ignored is
  `metadata = TRUE` as list metadata is always returned as a data frame.

- call:

  The execution environment of a currently running function, e.g.
  `caller_env()`. The function will be mentioned in error messages as
  the source of the error. See the `call` argument of
  [`abort()`](https://rlang.r-lib.org/reference/abort.html) for more
  information.

- filter:

  A string with [an OData
  expression](https://learn.microsoft.com/en-us/graph/query-parameters?tabs=http#filter-parameter)
  apply as a filter to the results. Learn more in the [Microsoft Graph
  API
  documentation](https://learn.microsoft.com/en-us/graph/filter-query-parameter)
  on using filter query parameters.

- n:

  Maximum number of lists, plans, tasks, or other items to return.
  Defaults to `NULL` which sets n to `Inf`.

- sp_list:

  A `ms_list` object. If supplied, `list_name`, `list_id`, `site_url`,
  `site`, `drive_name`, `drive_id`, `drive`, and any additional
  parameters passed to `...` are all ignored.

- keep:

  One of "all" (default), "editable", "external" (non-internal fields).
  Argument determines if the returned list metadata includes read only
  columns or hidden columns.

- sync_fields:

  If `TRUE`, use the `sync_fields` method to sync the fields of the
  local `ms_list` object with the fields of the SharePoint List source
  before retrieving list metadata.

## Value

A data frame `as_data_frame = TRUE` or a `ms_list` object (or list of
`ms_list` objects) if `FALSE`.

## See also

- [Microsoft365R::ms_list](https://rdrr.io/pkg/Microsoft365R/man/ms_list.html)

- [Microsoft365R::ms_list_item](https://rdrr.io/pkg/Microsoft365R/man/ms_list_item.html)

- [`create_sp_list()`](https://elipousson.github.io/sharepointr/reference/create_sp_list.md);
  [`delete_sp_list()`](https://elipousson.github.io/sharepointr/reference/create_sp_list.md)

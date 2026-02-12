# Get, list, update, and delete SharePoint list items

`list_sp_list_items()` lists `sp_list` items. Additional functions
should be completed for the `get_item`, `create_item`, `update_item`,
and `delete_item` methods documented in
[Microsoft365R::ms_list](https://rdrr.io/pkg/Microsoft365R/man/ms_list.html).

## Usage

``` r
list_sp_list_items(
  list_name = NULL,
  list_id = NULL,
  sp_list = NULL,
  ...,
  filter = NULL,
  select = NULL,
  all_metadata = FALSE,
  as_data_frame = TRUE,
  col_formatting = c("asis", "date"),
  display_nm = c("drop", "label", "replace"),
  select_type = c("asis", "editable", "external"),
  name_repair = "unique",
  pagesize = 5000,
  site_url = NULL,
  site = NULL,
  drive_name = NULL,
  drive_id = NULL,
  drive = NULL,
  call = caller_env()
)

get_sp_list_items(
  list_name = NULL,
  list_id = NULL,
  sp_list = NULL,
  ...,
  filter = NULL,
  select = NULL,
  all_metadata = FALSE,
  as_data_frame = TRUE,
  col_formatting = c("asis", "date"),
  display_nm = c("drop", "label", "replace"),
  name_repair = "unique",
  pagesize = 5000,
  site_url = NULL,
  site = NULL,
  drive_name = NULL,
  drive_id = NULL,
  drive = NULL,
  call = caller_env()
)

get_sp_list_item(
  id,
  list_name = NULL,
  list_id = NULL,
  sp_list = NULL,
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

- list_name, list_id:

  SharePoint List name or ID string.

- sp_list:

  A `ms_list` object. If supplied, `list_name`, `list_id`, `site_url`,
  `site`, `drive_name`, `drive_id`, `drive`, and any additional
  parameters passed to `...` are all ignored.

- ...:

  Arguments passed on to
  [`get_sp_list`](https://elipousson.github.io/sharepointr/reference/sp_list.md)

  `list_name,list_id`

  :   SharePoint List name or ID string.

  `metadata`

  :   If `TRUE`,
      [`get_sp_list()`](https://elipousson.github.io/sharepointr/reference/sp_list.md)
      applies the `get_column_info` method to the returned SharePoint
      list and returns a data frame with column metadata for the list.

  `drive_name,drive_id`

  :   SharePoint Drive name or ID passed to `get_drive` method for
      SharePoint site object.

- filter:

  A string with [an OData
  expression](https://learn.microsoft.com/en-us/graph/query-parameters?tabs=http#filter-parameter)
  apply as a filter to the results. Learn more in the [Microsoft Graph
  API
  documentation](https://learn.microsoft.com/en-us/graph/filter-query-parameter)
  on using filter query parameters.

- select:

  A character vector of column names to include in the returned data
  frame of list items. If `NULL`, the data frame includes all columns
  from the list.

- all_metadata:

  If `TRUE`, the returned data frame will contain extended metadata as
  separate columns, while the data fields will be in a nested data frame
  named fields. This is always set to `FALSE` if `n = NULL` or
  `as_data_frame = FALSE`.

- as_data_frame:

  If `TRUE`, return a data frame with a "ms_list" column.
  [`get_sp_list()`](https://elipousson.github.io/sharepointr/reference/sp_list.md)
  returns a 1 row data frame and
  [`list_sp_lists()`](https://elipousson.github.io/sharepointr/reference/sp_list.md)
  returns a data frame with n rows or all lists available for the
  SharePoint site or drive. Defaults to `FALSE`. Ignored is
  `metadata = TRUE` as list metadata is always returned as a data frame.

- col_formatting:

  "asis" (default) or "date". If "date", use the list column metadata
  and convert date columns to Date class and datetime columns to POSIXct
  class vectors (latter is not yet tested).

- display_nm:

  Option of "drop" (default), "label", or "replace". If "drop", display
  names are not accessed or used. If "label", display names are used to
  label matching columns in the returned data frame. If "replace",
  display names replace column names in the returned data frame. When
  working with the last option, the `name_repair` argument is required
  since there is no requirement on SharePoint for lists to use unique
  display names and invalid data frames can result.

- select_type:

  Columns to select. Ignored if `select` is supplied. "asis" returns all
  available columns. "editable" returns ID and all non-read-only columns
  and "external" returns ID and all non-internal columns.

- name_repair:

  Passed to repair argument of
  [`vctrs::vec_as_names()`](https://vctrs.r-lib.org/reference/vec_as_names.html)

- pagesize:

  Number of list items to return. Reduce from default of 5000 is
  experiencing timeouts.

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

- call:

  The execution environment of a currently running function, e.g.
  `caller_env()`. The function will be mentioned in error messages as
  the source of the error. See the `call` argument of
  [`abort()`](https://rlang.r-lib.org/reference/abort.html) for more
  information.

- id:

  Required. A SharePoint list item ID typically an integer for the
  record number starting from 1 with the first record.

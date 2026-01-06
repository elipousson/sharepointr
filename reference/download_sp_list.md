# Download a SharePoint List

`download_sp_list()` downloads a SharePoint list to a CSV or XLSX file.
`keep_list_cols` is intended to allow the preservation of list columns
but it is not yet supported.

## Usage

``` r
download_sp_list(
  ...,
  new_path = "",
  sp_list = NULL,
  fileext = "csv",
  keep_list_cols = c("createdBy", "lastModifiedBy"),
  call = caller_env()
)
```

## Arguments

- ...:

  Arguments passed on to
  [`get_sp_list`](https://elipousson.github.io/sharepointr/reference/sp_list.md)

  `list_name,list_id`

  :   SharePoint List name or ID string.

  `as_data_frame`

  :   If `TRUE`, return a data frame with a "ms_list" column.
      [`get_sp_list()`](https://elipousson.github.io/sharepointr/reference/sp_list.md)
      returns a 1 row data frame and
      [`list_sp_lists()`](https://elipousson.github.io/sharepointr/reference/sp_list.md)
      returns a data frame with n rows or all lists available for the
      SharePoint site or drive. Defaults to `FALSE`. Ignored is
      `metadata = TRUE` as list metadata is always returned as a data
      frame.

  `metadata`

  :   If `TRUE`,
      [`get_sp_list()`](https://elipousson.github.io/sharepointr/reference/sp_list.md)
      applies the `get_column_info` method to the returned SharePoint
      list and returns a data frame with column metadata for the list.

  `drive_name,drive_id`

  :   SharePoint Drive name or ID passed to `get_drive` method for
      SharePoint site object.

  `drive`

  :   A `ms_drive` object. If `drive` is supplied, `drive_name` and
      `drive_id` are ignored.

  `site_url`

  :   A SharePoint site URL in the format "https://\[tenant
      name\].sharepoint.com/sites/\[site name\]". Any SharePoint item or
      document URL can also be parsed to build a site URL using the
      tenant and site name included in the URL.

  `site`

  :   A `ms_site` object. If `site` is supplied, `site_url`,
      `site_name`, and `site_id` are ignored.

- new_path:

  Optional path to new file. If not `new_path` provided, the file name
  is pulled from the name of the SharePoint list using the provided
  `fileext`. If `new_path` is provided, `fileext` is ignored.

- sp_list:

  SharePoint list object. If supplied, all parameters supplied to `...`
  are ignored.

- fileext:

  File extension to use for output file. Must be `"csv"` or `"xlsx"`.

- keep_list_cols:

  Column names for those columns to maintain in a list format instead of
  attempting to convert to a character vector.

- call:

  The execution environment of a currently running function, e.g.
  `caller_env()`. The function will be mentioned in error messages as
  the source of the error. See the `call` argument of
  [`abort()`](https://rlang.r-lib.org/reference/abort.html) for more
  information.

# Create a new column definition based on an existing list

**\[experimental\]**

## Usage

``` r
copy_column_definition_list(sp_list = NULL, ...)
```

## Arguments

- sp_list:

  A `ms_list` object or a data frame created by
  [`get_sp_list_metadata()`](https://elipousson.github.io/sharepointr/reference/sp_list.md).
  Optional if additional parameters are provided to `...` that can be
  used to get a SharePoint list to copy column definitions from.

- ...:

  Arguments passed on to
  [`get_sp_list_metadata`](https://elipousson.github.io/sharepointr/reference/sp_list.md)

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

  `keep`

  :   One of "all" (default), "editable", "external" (non-internal
      fields). Argument determines if the returned list metadata
      includes read only columns or hidden columns.

  `sync_fields`

  :   If `TRUE`, use the `sync_fields` method to sync the fields of the
      local `ms_list` object with the fields of the SharePoint List
      source before retrieving list metadata.

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

  `call`

  :   The execution environment of a currently running function, e.g.
      `caller_env()`. The function will be mentioned in error messages
      as the source of the error. See the `call` argument of
      [`abort()`](https://rlang.r-lib.org/reference/abort.html) for more
      information.

  `site`

  :   A `ms_site` object. If `site` is supplied, `site_url`,
      `site_name`, and `site_id` are ignored.

## Details

`copy_column_definition_list()` takes an existing SharePoint list and
uses the list metadata to create a column definition list that can be
used to create a new SharePoint list. Note: lookup columns retain the
original lookup list references so self-referencing lookup columns are
copied as lookup columns referencing the source list.

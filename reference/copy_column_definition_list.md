# Create a new column definition based on an existing list

`copy_column_definition_list()` takes an existing SharePoint list and
uses the list metadata to create a column definition list that can be
used to create a new SharePoint list. NOTE: choice column types are not
yet supported so choice definitions from the source list are dropped.

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

# Get SharePoint list column definition for a single column

`get_sp_list_column()` gets a list column definition for a single column
specified by column name or ID.

## Usage

``` r
get_sp_list_column(
  sp_list = NULL,
  column_name = NULL,
  column_id = NULL,
  ...,
  list_name = NULL,
  site_url = NULL,
  site = NULL,
  column_name_type = "name",
  call = caller_env()
)
```

## Arguments

- sp_list:

  A `ms_list` object. If supplied, `list_name`, `list_id`, `site_url`,
  `site`, `drive_name`, `drive_id`, `drive`, and any additional
  parameters passed to `...` are all ignored.

- column_name, column_id:

  Column name or ID to get a definition for.

- ...:

  Arguments passed on to
  [`get_sp_list`](https://elipousson.github.io/sharepointr/reference/sp_list.md)

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

  `filter`

  :   A string with [an OData
      expression](https://learn.microsoft.com/en-us/graph/query-parameters?tabs=http#filter-parameter)
      apply as a filter to the results. Learn more in the [Microsoft
      Graph API
      documentation](https://learn.microsoft.com/en-us/graph/filter-query-parameter)
      on using filter query parameters.

  `n`

  :   Maximum number of lists, plans, tasks, or other items to return.
      Defaults to `NULL` which sets n to `Inf`.

- list_name:

  SharePoint List name. Optional if `sp_list` or `list_id` are provided.

- site_url:

  A SharePoint site URL in the format "https://\[tenant
  name\].sharepoint.com/sites/\[site name\]". Any SharePoint item or
  document URL can also be parsed to build a site URL using the tenant
  and site name included in the URL.

- site:

  A `ms_site` object. If `site` is supplied, `site_url`, `site_name`,
  and `site_id` are ignored.

- column_name_type:

  "name" or "displayName". Used to match column ID so column_name must
  be unique if `column_name_type = "displayName"`.

- call:

  The execution environment of a currently running function, e.g.
  `caller_env()`. The function will be mentioned in error messages as
  the source of the error. See the `call` argument of
  [`abort()`](https://rlang.r-lib.org/reference/abort.html) for more
  information.

## Details

See the [Get columnDefinition Graph API
documentation](https://learn.microsoft.com/en-us/graph/api/columndefinition-get?view=graph-rest-1.0&tabs=http)
for more information.

# Get SharePoint list column definition

`get_sp_list_column()` get a list column definition.

## Usage

``` r
get_sp_list_column(
  sp_list = NULL,
  column_name = NULL,
  column_id = NULL,
  ...,
  list_name = NULL,
  list_id = NULL,
  column_name_type = "name"
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

  `call`

  :   The execution environment of a currently running function, e.g.
      `caller_env()`. The function will be mentioned in error messages
      as the source of the error. See the `call` argument of
      [`abort()`](https://rlang.r-lib.org/reference/abort.html) for more
      information.

  `site`

  :   A `ms_site` object. If `site` is supplied, `site_url`,
      `site_name`, and `site_id` are ignored.

- list_name, list_id:

  SharePoint List name or ID string.

- column_name_type:

  "name" or "displayName". Used to match column ID so column_name must
  be unique if `column_name_type = "displayName"`.

## Details

See Graph API documentation
<https://learn.microsoft.com/en-us/graph/api/columndefinition-get?view=graph-rest-1.0&tabs=http>

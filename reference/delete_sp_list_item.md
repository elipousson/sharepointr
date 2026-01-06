# Delete SharePoint list item or items

`delete_sp_list_item()` deletes a single SharePoint list item and
`delete_sp_list_items()` deletes multiple SharePoint list items. Set
`confirm = FALSE` to use without interactive confirmation.

## Usage

``` r
delete_sp_list_item(
  item_id = NULL,
  sp_list_item = NULL,
  ...,
  list_name = NULL,
  list_id = NULL,
  sp_list = NULL,
  site_url = NULL,
  site = NULL,
  confirm = TRUE,
  call = caller_env()
)

delete_sp_list_items(
  item_id = NULL,
  ...,
  sp_list = NULL,
  filter = NULL,
  confirm = TRUE,
  .progress = TRUE
)
```

## Arguments

- item_id:

  ID value for list item or items to delete.

- sp_list_item:

  Optional. A SharePoint list item object to delete.

- ...:

  Additional parameters passed to
  [`get_sp_site()`](https://elipousson.github.io/sharepointr/reference/sp_site.md)
  or
  [`Microsoft365R::get_sharepoint_site()`](https://rdrr.io/pkg/Microsoft365R/man/client.html).

- list_name, list_id:

  SharePoint List name or ID string.

- sp_list:

  A `ms_list` object. If supplied, `list_name`, `list_id`, `site_url`,
  `site`, `drive_name`, `drive_id`, `drive`, and any additional
  parameters passed to `...` are all ignored.

- site_url:

  A SharePoint site URL in the format "https://\[tenant
  name\].sharepoint.com/sites/\[site name\]". Any SharePoint item or
  document URL can also be parsed to build a site URL using the tenant
  and site name included in the URL.

- site:

  A `ms_site` object. If `site` is supplied, `site_url`, `site_name`,
  and `site_id` are ignored.

- confirm:

  If `TRUE` (default), user confirmation is required to delete items.

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

- .progress:

  Whether to show a progress bar. Use `TRUE` to turn on a basic progress
  bar, use a string to give it a name, or see
  [progress_bars](https://purrr.tidyverse.org/reference/progress_bars.html)
  for more details.

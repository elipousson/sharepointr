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
  .id = "id",
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
  .id = "id",
  sp_list = NULL,
  filter = NULL,
  confirm = TRUE,
  .progress = TRUE,
  call = caller_env()
)
```

## Arguments

- item_id:

  ID value for list item or items to delete. `item_id` can also be a
  data frame with a column named with the `.id` value, a single named
  list record, or (for `delete_sp_list_items()`) a list of named lists
  (one per item) where each record includes an element named with the
  `.id` value. Item IDs must be whole numbers or non-empty strings and
  are checked before any items are deleted. `delete_sp_list_item()`
  requires a single item ID.

- sp_list_item:

  Optional. A SharePoint list item object to delete.

- ...:

  For `delete_sp_list_item()`, must be empty. For
  `delete_sp_list_items()`, additional parameters passed to
  [`get_sp_list()`](https://elipousson.github.io/sharepointr/reference/sp_list.md)
  if `sp_list` is `NULL`.

- .id:

  Name of column (if `item_id` is a data frame) or element (if `item_id`
  is a list of records) to use for item ID values. Defaults to "id".

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

  Optional. A string with an OData filter expression used to find the
  items to delete if `item_id` is `NULL`. Can't be supplied with
  `item_id`. See
  [`list_sp_list_items()`](https://elipousson.github.io/sharepointr/reference/sp_list_item.md).

- .progress:

  Whether to show a progress bar. Use `TRUE` to turn on a basic progress
  bar, use a string to give it a name, or see
  [progress_bars](https://purrr.tidyverse.org/reference/progress_bars.html)
  for more details.

## Value

For `delete_sp_list_item()`, invisibly returns an empty list with a
`"status"` attribute giving the HTTP response status code. For
`delete_sp_list_items()`, invisibly returns a list of these responses,
one per deleted item.

# Create or update list items

Create or update list items

## Usage

``` r
create_sp_list_items(
  data,
  list_name = NULL,
  list_id = NULL,
  sp_list = NULL,
  ...,
  allow_display_nm = FALSE,
  .id = "id",
  site_url = NULL,
  site = NULL,
  drive_name = NULL,
  drive_id = NULL,
  drive = NULL,
  check_fields = TRUE,
  sync_fields = FALSE,
  create_list = FALSE,
  strict = FALSE,
  .batch = getOption("sharepointr.batch", TRUE),
  .progress = TRUE,
  call = caller_env()
)

update_sp_list_items(
  data,
  list_name = NULL,
  list_id = NULL,
  sp_list = NULL,
  ...,
  .id = "id",
  allow_display_nm = FALSE,
  check_fields = TRUE,
  strict = FALSE,
  na_fields = c("drop", "replace"),
  drop_fields = c("ContentType", "Attachments"),
  .batch = getOption("sharepointr.batch", TRUE),
  .progress = TRUE,
  call = caller_env()
)

update_sp_list_item(
  ...,
  .data = NULL,
  item_id = NULL,
  sp_list_item = NULL,
  .id = "id",
  check_fields = TRUE,
  na_fields = c("drop", "replace"),
  drop_fields = c("ContentType", "Attachments"),
  list_name = NULL,
  list_id = NULL,
  sp_list = NULL,
  site_url = NULL,
  site = NULL,
  drive_name = NULL,
  drive_id = NULL,
  drive = NULL,
  .multi_fields = NULL,
  call = caller_env()
)
```

## Arguments

- data:

  Required. A data frame or a list of named lists (one record per item)
  to import as items to the supplied or identified SharePoint list. If
  data is an sf object, the geometry column is coerced to text using
  [`sf::st_as_text()`](https://r-spatial.github.io/sf/reference/st_as_text.html).
  For `update_sp_list_items()`, each record must include an `.id`
  element and `data` can also be a single named list record for one
  item. Unlike a data frame, any field missing from a record is left
  unchanged, even when `na_fields = "replace"`. For
  `create_sp_list_items()`, wrap a single record in a list (e.g.
  `list(record)`) and `data` must be a data frame if
  `create_list = TRUE`.

- list_name, list_id:

  SharePoint List name or ID string.

- sp_list:

  A `ms_list` object. If supplied, `list_name`, `list_id`, `site_url`,
  `site`, `drive_name`, `drive_id`, `drive`, and any additional
  parameters passed to `...` are all ignored.

- ...:

  Additional parameters passed to
  [`get_sp_site()`](https://elipousson.github.io/sharepointr/reference/sp_site.md)
  or
  [`Microsoft365R::get_sharepoint_site()`](https://rdrr.io/pkg/Microsoft365R/man/client.html).

- allow_display_nm:

  If `TRUE`, allow data to use list field display names instead of
  standard names. Note this requires a separate API call so may result
  in a slower request. Default `FALSE`.

- .id:

  Name of the column in `data` (or the element in each record if `data`
  is a list) with item ID values. Defaults to `"id"`. Item IDs must be
  whole numbers or non-empty strings and are checked before any items
  are updated. For `create_sp_list_items()`, `.id` is only used to keep
  the ID column name from being replaced when `allow_display_nm = TRUE`.
  For `update_sp_list_item()`, `.id` is used to get `item_id` from
  `.data` if `item_id` isn't supplied.

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

- check_fields:

  If `TRUE` (default), column names (or record field names) for the
  input data are matched to the fields of the list object. If `FALSE`,
  names aren't checked and the Graph API errors for any name that isn't
  a list field.

- sync_fields:

  If `TRUE`, use the `sync_fields` method to sync the fields of the
  local `ms_list` object with the fields of the SharePoint List source
  before retrieving list metadata.

- create_list:

  If `TRUE` and `list_name` is supplied, a new list is created using
  [`data_as_column_definition_list()`](https://elipousson.github.io/sharepointr/reference/data_as_column_definition_list.md)
  to set the column definitions for the list.

- strict:

  If `TRUE`, all column names in a data frame (or field names in a list
  of records) must match field names in the supplied SharePoint list. If
  `FALSE` (default), unmatched names are dropped with a message. Only
  used if `check_fields = TRUE`.

- .batch:

  If `TRUE` (default), items are sent with Microsoft Graph `$batch`
  requests (up to 20 items per request), which is much faster than a
  separate request for each item. Requests throttled by the Graph API
  are retried after the requested delay. If any items fail, the
  remaining items are still sent and the error lists the failed items.
  If `FALSE`, a separate request is sent for each item and the first
  failed item is an error. Use `options(sharepointr.batch = FALSE)` to
  change the default for the session. In either case, requests are sent
  in parallel if `mirai::daemons()` are set (see
  [`purrr::in_parallel()`](https://purrr.tidyverse.org/reference/in_parallel.html)).
  For `create_sp_list_items()`, items sent in a `$batch` request (or in
  parallel) may be created in a different order than `data`, so new item
  IDs may not follow the order of `data`. Use `.batch = FALSE` (without
  daemons) if item IDs must follow the order of `data`.

- .progress:

  Whether to show a progress bar. Use `TRUE` to turn on a basic progress
  bar, use a string to give it a name, or see
  [progress_bars](https://purrr.tidyverse.org/reference/progress_bars.html)
  for more details.

- call:

  The execution environment of a currently running function, e.g.
  `caller_env()`. The function will be mentioned in error messages as
  the source of the error. See the `call` argument of
  [`abort()`](https://rlang.r-lib.org/reference/abort.html) for more
  information.

- na_fields:

  How to handle `NA` fields in input data. One of `"drop"` (remove `NA`
  and empty fields, e.g. a multi-select value of `character(0)`, before
  updating list items, leaving existing values in place) or `"replace"`
  (overwrite existing list values with new replacement NA values or, for
  multi-value fields, an empty selection).

- drop_fields:

  Column names to drop from `data` even if they are listed as editable
  fields. Defaults to `c("ContentType", "Attachments")`

- .data:

  A list or data frame with fields to update.

- item_id:

  A SharePoint list item id. Either `item_id` or `sp_list_item` must be
  provided but not both.

- sp_list_item:

  Optional. A SharePoint list item object to update.

- .multi_fields:

  Optional. Names of multi-value (Collection) fields, such as
  multi-select choice columns, that should always be sent as an array
  with an `"@odata.type"` annotation. If `NULL` and `sp_list` is
  available, field names are found from the list column definitions.
  Otherwise, only fields with a length other than 1 are treated as
  multi-value fields.

## Value

`create_sp_list_items()` and `update_sp_list_items()` invisibly return
the input `data`, unmodified (even if `data` is empty).

## Details

Validation of data with with `create_sp_list_items()`

The handling of item creation when column names in `data` do not match
the fields names in the supplied list includes a few options:

- If no names in data match fields in the list, the function errors and
  lists the field names.

- If all names in data match fields in the list the records are created.
  Any fields that do not have corresponding names in data remain blank.

- If any names in data do not match fields in the list, by default,
  those columns are dropped before adding items to the list.

- If `strict = TRUE` and any names in data to not match fields, the
  function errors.

## Examples

``` r
sp_list_url <- "<SharePoint List URL with a Name field>"

if (is_sp_url(sp_list_url)) {
  create_sp_list_items(
    data = data.frame(
      Name = c("Jim", "Jane", "Jayden")
    ),
    list_name = sp_list_url
  )
}
```

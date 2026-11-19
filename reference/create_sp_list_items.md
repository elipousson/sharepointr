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
  unmatched_fields = c("drop", "error", "keep"),
  coerce = c("basic", "asis", "geometry"),
  validate = c("none", "warn", "error"),
  create_list = FALSE,
  .batch = getOption("sharepointr.batch", TRUE),
  .progress = TRUE,
  check_fields = deprecated(),
  strict = deprecated()
)

update_sp_list_items(
  data,
  list_name = NULL,
  list_id = NULL,
  sp_list = NULL,
  ...,
  .id = "id",
  allow_display_nm = FALSE,
  unmatched_fields = c("drop", "error", "keep"),
  coerce = c("basic", "asis", "geometry"),
  validate = c("none", "warn", "error"),
  na_fields = c("drop", "replace"),
  drop_fields = c("ContentType", "Attachments"),
  .batch = getOption("sharepointr.batch", TRUE),
  .progress = TRUE,
  check_fields = deprecated(),
  strict = deprecated()
)

update_sp_list_item(
  ...,
  .data = NULL,
  item_id = NULL,
  sp_list_item = NULL,
  .id = "id",
  unmatched_fields = c("drop", "error", "keep"),
  coerce = c("basic", "asis", "geometry"),
  validate = c("none", "warn", "error"),
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
  .quiet = FALSE,
  check_fields = deprecated()
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

- unmatched_fields:

  What to do with column names in a data frame (or field names in a list
  of records) that don't match field names in the supplied SharePoint
  list. One of:

  - `"drop"` (default): drop unmatched names with a message. An error if
    no names match.

  - `"error"`: an error if any name doesn't match.

  - `"keep"`: names aren't checked and the Graph API errors for any name
    that isn't a list field.

- coerce:

  How to convert values in `data` to match the list column types. One
  of:

  - `"basic"` (default): convert numbers, logical values, and factors to
    text for text and choice columns; convert text to numbers for number
    and currency columns; and convert whole numbers (or text) to
    integers for the `LookupId` fields of lookup and person columns.
    Values that can't be converted are left unchanged with a warning.
    Data with `sf` geometry columns is an error.

  - `"asis"`: send values unchanged.

  - `"geometry"`: do everything in `"basic"` and convert `sf` geometry
    columns to well-known text (WKT) with
    [`sf::st_as_text()`](https://r-spatial.github.io/sf/reference/st_as_text.html).

  Coercion changes types but doesn't check values. Use `validate` to
  check values. See the section on single item functions for the cost of
  coercion with `update_sp_list_item()`.

- validate:

  What to do with values that don't match the list column definitions,
  after values are coerced. One of:

  - `"none"` (default): don't check values.

  - `"warn"`: warn and send the items.

  - `"error"`: error before any items are sent.

  Values are checked for text longer than the column `maxLength`,
  numbers outside the column minimum and maximum, choices that aren't in
  a choice column (unless the column allows text entry), and missing
  values in required columns that have no default value. Missing
  required values are checked for new items and for updates that replace
  values with `NA` (`na_fields = "replace"`), since other fields are
  left unchanged. Values that don't match are reported together (up to
  10). Missing required values are always a warning (even with
  `validate = "error"`) since SharePoint creates items without them.
  Field names are checked with `unmatched_fields`.

- create_list:

  If `TRUE` and `list_name` is supplied, a new list is created using
  [`data_as_column_definition_list()`](https://elipousson.github.io/sharepointr/reference/data_as_column_definition_list.md)
  to set the column definitions for the list.

- .batch:

  If `TRUE` (default), items are sent with Microsoft Graph `$batch`
  requests (up to 20 items per request), which is much faster than a
  separate request for each item. Requests throttled by the Graph API or
  failing with a temporary error (e.g. "Database is read only") are
  retried up to 5 times after the requested delay (or an increasing
  delay of up to 60 seconds). If any items fail, the remaining items are
  still sent and the error lists the failed items with the HTTP status.
  If `FALSE`, a separate request is sent for each item and the first
  failed item is an error. Use `options(sharepointr.batch = FALSE)` to
  change the default for the session. In either case, requests are sent
  in parallel if
  [`mirai::daemons()`](https://mirai.r-lib.org/reference/daemons.html)
  are set (see
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

- check_fields, strict:

  **\[deprecated\]** Use `unmatched_fields` instead:
  `check_fields = FALSE` is `"keep"` and `strict = TRUE` is `"error"`.

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

  Optional. A SharePoint list item object to update. The column
  definitions for the list are requested to check field names and coerce
  values (see the section on single item functions).

- .multi_fields:

  Optional. Names of multi-value (Collection) fields, such as
  multi-select choice columns, that should always be sent as an array
  with an `"@odata.type"` annotation. If `NULL` and `sp_list` is
  available, field names are found from the list column definitions.
  Otherwise, only fields with a length other than 1 are treated as
  multi-value fields.

- .quiet:

  If `TRUE`, don't show a progress message for the update. Used by
  `update_sp_list_items()` when updating items one at a time.

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

- If `unmatched_fields = "error"` and any names in data do not match
  fields, the function errors.

## Single item functions

`create_sp_list_items()` and `update_sp_list_items()` get the list
column definitions once and use them to check field names
(`unmatched_fields`) and coerce values (`coerce`) for every item.
`update_sp_list_item()` and
[`create_sp_list_item()`](https://elipousson.github.io/sharepointr/reference/create_sp_list_item.md)
work on one item at a time so:

- If you supply `sp_list` (and `item_id`), the column definitions are
  requested from the Graph API for every call. Looping over items adds
  one extra request per item. To avoid the request, set
  `coerce = "asis"`, `unmatched_fields = "keep"`, `validate = "none"`,
  and supply `.multi_fields` (for
  [`create_sp_list_item()`](https://elipousson.github.io/sharepointr/reference/create_sp_list_item.md),
  set `.coerce = "asis"` and `.validate = "none"`).

- If you supply `sp_list_item` (a list item object) to
  `update_sp_list_item()`, the column definitions are requested for the
  item's list (a `ms_list` object is created from the item's site and
  list IDs) so the same extra request is made for every call, and the
  same arguments avoid it.

Use the plural functions to update more than one item (they also send
requests in batches), or coerce and check the data first and send it
with `coerce = "asis"`.

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

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
  na_fields = c("drop", "replace"),
  drop_fields = c("ContentType", "Attachments"),
  .progress = TRUE,
  call = caller_env()
)

update_sp_list_item(
  ...,
  .data = NULL,
  item_id = NULL,
  sp_list_item = NULL,
  na_fields = c("drop", "replace"),
  .id = "id",
  list_name = NULL,
  list_id = NULL,
  sp_list = NULL,
  site_url = NULL,
  site = NULL,
  drive_name = NULL,
  drive_id = NULL,
  drive = NULL,
  call = caller_env()
)
```

## Arguments

- data:

  Required. A data frame to import as items to the supplied or
  identified SharePoint list.

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

  Column or element name with `item_item` value in `data`. Allows users
  to pass a modified version of the list item data with the id column
  and any updated columns.

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

  If `TRUE` (default), column names for the input data are matched to
  the fields of the list object. If `FALSE`, the function will error if
  any column names can't be matched to a field in the supplied
  SharePoint list.

- sync_fields:

  If `TRUE`, use the `sync_fields` method to sync the fields of the
  local `ms_list` object with the fields of the SharePoint List source
  before retrieving list metadata.

- create_list:

  If `TRUE` and `list_name` is supplied, a new list is created using
  [`data_as_column_definition_list()`](https://elipousson.github.io/sharepointr/reference/data_as_column_definition_list.md)
  to set the column definitions for the list.

- strict:

  Not yet implemented as of 2024-08-12. If `TRUE`, all column names in
  data must be matched to field names in the supplied SharePoint list.
  If `FALSE` (default), unmatched columns will be dropped with a
  warning.

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
  fields before updating list items, leaving existing values in place)
  or `"replace"` (overwrite existing list values with new replacement NA
  values).

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

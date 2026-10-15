# Get or update the properties of a SharePoint file or folder

`get_sp_item_properties()` gets the properties of a file or folder, such
as the name, size, and creation date. Set `fields = TRUE` to also get
the values of the document library columns (fields) for the item. To get
the fields for many items, use
[`get_sp_list()`](https://elipousson.github.io/sharepointr/reference/sp_list.md)
to get the document library as a list and use
[`list_sp_list_items()`](https://elipousson.github.io/sharepointr/reference/sp_list_item.md)
or
[`get_sp_list_item()`](https://elipousson.github.io/sharepointr/reference/sp_list_item.md)
instead.

**\[experimental\]**

`update_sp_item_properties()` renames a file or folder or updates the
values of document library columns for the item. Field values are
updated with
[`update_sp_list_item()`](https://elipousson.github.io/sharepointr/reference/create_sp_list_items.md)
using the list for the document library, so the same field name checks
and formatting (e.g. for multi-choice columns) are used. To move an item
to another folder, use
[`sp_item_move()`](https://elipousson.github.io/sharepointr/reference/sp_item_copy.md)
instead.

## Usage

``` r
get_sp_item_properties(
  path = NULL,
  item_id = NULL,
  item_url = NULL,
  ...,
  drive = NULL,
  drive_name = NULL,
  drive_id = NULL,
  site_url = NULL,
  fields = FALSE,
  as_data_frame = FALSE,
  call = caller_env()
)

update_sp_item_properties(
  path = NULL,
  ...,
  .data = NULL,
  name = NULL,
  item_id = NULL,
  item_url = NULL,
  item = NULL,
  check_fields = TRUE,
  na_fields = c("drop", "replace"),
  drive_name = NULL,
  drive_id = NULL,
  drive = NULL,
  site_url = NULL,
  fields = FALSE,
  as_data_frame = FALSE,
  call = caller_env()
)
```

## Arguments

- path:

  A SharePoint file URL or the relative path to a file located in a
  SharePoint drive. If input is a relative path, the string should *not*
  include the drive name. If input is a shared file URL, the text
  "Shared " is removed from the start of the SharePoint drive name by
  default. If file is a document URL, the `default_drive_name` argument
  is used as the `drive_name` and the `item_id` is extracted from the
  URL.

- item_id:

  A SharePoint item ID passed to the `itemid` parameter of the
  `get_item` method for `ms_drive` objects.

- item_url:

  A SharePoint item URL used to parse the item ID, drive name, and site
  URL.

- ...:

  For `get_sp_item_properties()`, additional parameters passed to
  [`get_sp_drive()`](https://elipousson.github.io/sharepointr/reference/sp_drive.md).
  For `update_sp_item_properties()`, named field values to update, e.g.
  `Title = "Annual report"`. Names can be column names or display names.
  Ignored if `.data` is supplied.

- drive:

  A `ms_drive` object. If drive is supplied, `drive_name`, `site_url`,
  and any additional parameters passed to `...` are ignored.

- drive_name, drive_id:

  SharePoint drive name or ID.

- site_url:

  A SharePoint site URL in the format "https://\[tenant
  name\].sharepoint.com/sites/\[site name\]". Any SharePoint item or
  document URL can also be parsed to build a site URL using the tenant
  and site name included in the URL.

- fields:

  If `TRUE`, add a `fields` element with the document library column
  values for the item (a named list). The `id` field is the list item id
  (not the drive item id). If `as_data_frame = TRUE`, `fields` is a list
  column with a 1 row data frame of the field values (use
  `tidyr::unnest(data, fields, names_sep = "_")` to add the fields as
  columns). Defaults to `FALSE`. Fields are only available for items in
  a SharePoint document library.

- as_data_frame:

  If `TRUE`, return a 1 row data frame. If `FALSE` (default), return a
  list of item properties.

- call:

  The execution environment of a currently running function, e.g.
  `caller_env()`. The function will be mentioned in error messages as
  the source of the error. See the `call` argument of
  [`abort()`](https://rlang.r-lib.org/reference/abort.html) for more
  information.

- .data:

  A named list or a single row data frame with field values to update.
  Optional.

- name:

  A new name for the item. Optional. `name` must not include a folder
  path. An error is returned if an item with the same name already
  exists in the folder.

- item:

  A `ms_drive_item` object. If `item` is supplied, `path`, `item_id`,
  `item_url`, and the drive arguments are ignored.

- check_fields:

  If `TRUE` (default), column names (or record field names) for the
  input data are matched to the fields of the list object. If `FALSE`,
  names aren't checked and the Graph API errors for any name that isn't
  a list field.

- na_fields:

  How to handle `NA` fields in input data. One of `"drop"` (remove `NA`
  and empty fields, e.g. a multi-select value of `character(0)`, before
  updating list items, leaving existing values in place) or `"replace"`
  (overwrite existing list values with new replacement NA values or, for
  multi-value fields, an empty selection).

## Value

A list of item properties, or a 1 row data frame if
`as_data_frame = TRUE`. `update_sp_item_properties()` returns the
properties after the update.

## See also

[`get_sp_item()`](https://elipousson.github.io/sharepointr/reference/get_sp_item.md),
[`get_sp_list_item()`](https://elipousson.github.io/sharepointr/reference/sp_list_item.md)

## Examples

``` r
sp_item_url <- "<SharePoint item url>"

if (is_sp_url(sp_item_url)) {
  get_sp_item_properties(sp_item_url, fields = TRUE)

  update_sp_item_properties(
    sp_item_url,
    Title = "Annual report",
    name = "annual-report-2026.docx"
  )
}
```

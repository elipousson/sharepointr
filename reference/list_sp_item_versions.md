# List, get, and download versions of a SharePoint item

`list_sp_item_versions()` lists the versions of a SharePoint file (a
`driveItem`) and when and by whom they were saved, which makes it
possible to check the recent edit history of a file such as an Excel
workbook. `get_sp_item_version()` returns a single version, and
`download_sp_item_version()` saves the content of a past version of the
file.

## Usage

``` r
list_sp_item_versions(
  ...,
  sp_item = NULL,
  n = NULL,
  modified_between = NULL,
  item_cols = c("id", "none", "summary"),
  version_cols = c("properties", "all"),
  as_data_frame = TRUE,
  call = caller_env()
)

get_sp_item_version(
  version_id,
  ...,
  sp_item = NULL,
  item_cols = c("id", "none", "summary"),
  version_cols = c("properties", "all"),
  as_data_frame = TRUE,
  call = caller_env()
)

download_sp_item_version(
  version_id,
  ...,
  sp_item = NULL,
  dest = NULL,
  overwrite = FALSE,
  call = caller_env()
)
```

## Arguments

- ...:

  Arguments passed on to
  [`get_sp_item`](https://elipousson.github.io/sharepointr/reference/get_sp_item.md)

  `path`

  :   A SharePoint file URL or the relative path to a file located in a
      SharePoint drive. If input is a relative path, the string should
      *not* include the drive name. If input is a shared file URL, the
      text "Shared " is removed from the start of the SharePoint drive
      name by default. If file is a document URL, the
      `default_drive_name` argument is used as the `drive_name` and the
      `item_id` is extracted from the URL.

  `item_id`

  :   A SharePoint item ID passed to the `itemid` parameter of the
      `get_item` method for `ms_drive` objects.

  `item_url`

  :   A SharePoint item URL used to parse the item ID, drive name, and
      site URL.

  `drive_name,drive_id`

  :   SharePoint drive name or ID.

  `drive`

  :   A `ms_drive` object. If drive is supplied, `drive_name`,
      `site_url`, and any additional parameters passed to `...` are
      ignored.

  `properties`

  :   If `TRUE`, use the `get_item_properties` method and return item
      properties instead of the item.

  `site_url`

  :   A SharePoint site URL in the format "https://\[tenant
      name\].sharepoint.com/sites/\[site name\]". Any SharePoint item or
      document URL can also be parsed to build a site URL using the
      tenant and site name included in the URL.

- sp_item:

  A `ms_drive_item` object for a SharePoint file. Additional parameters
  passed to `...` are ignored if `sp_item` is supplied.

- n:

  Maximum number of versions to return, starting with the newest
  (latest). Defaults to `NULL` (all versions). Applied after
  `modified_between`.

- modified_between:

  A length 2 vector of dates or date-times with the start and end of the
  period to return versions for (inclusive, as in
  [`dplyr::between()`](https://dplyr.tidyverse.org/reference/between.html)).
  Use `NA` for an open start or end. A `Date` end includes that whole
  day. Character values are parsed as UTC. If the lubridate package is
  installed, a `lubridate::interval()` is also accepted.

- item_cols:

  Item columns to add to the returned data frame: `"id"` (default) adds
  `item_id` and `drive_id`, `"summary"` also adds `item_name` and
  `item_web_url`, and `"none"` adds no item columns.

- version_cols:

  Version columns to return: `"properties"` (default) returns
  `version_id`, `version`, `last_modified`, `last_modified_by`,
  `last_modified_by_email`, `last_modified_by_id`, and `size` and
  `"all"` also returns everything else the API provides, including
  `download_url`. The download URL includes a short-lived access token
  so is not returned by default. Column names use snake case (unlike the
  Graph API property names that
  [`sp_dir_info()`](https://elipousson.github.io/sharepointr/reference/sp_dir_info.md)
  returns).

- as_data_frame:

  If `TRUE` (default), return a data frame. If `FALSE`, return the
  response from the API as a list.

- call:

  The execution environment of a currently running function, e.g.
  `caller_env()`. The function will be mentioned in error messages as
  the source of the error. See the `call` argument of
  [`abort()`](https://rlang.r-lib.org/reference/abort.html) for more
  information.

- version_id:

  Version ID, e.g. `"3.0"`, as returned by `list_sp_item_versions()`.

- dest:

  Path to save the file to. Defaults to the name of the item with the
  version ID added before the file extension (e.g. `"book_v3.0.xlsx"`)
  in the working directory.

- overwrite:

  If `TRUE`, overwrite an existing file at `dest`.

## Value

For `list_sp_item_versions()`, a data frame with one row for each
version (newest first) if `as_data_frame = TRUE` or a list with the
versions in `value` otherwise. For `get_sp_item_version()`, a one row
data frame or a list. For `download_sp_item_version()`, the path to the
downloaded file (invisibly).

## Details

These functions use the `do_operation` method for a `ms_drive_item`
object directly. The intent is to add comparable methods back to the
Microsoft365R package which may include changes to the functionality and
output of these functions.

Versions are only available if versioning is enabled for the document
library (the default for SharePoint). The Graph API doesn't document the
order it returns versions in. In testing with 60 files, it always
returned versions from newest to oldest, so `n` is sent to the API as
`$top` to limit the size of the response for files with many versions
and returns the newest versions. The versions that are returned are
sorted by last modified time. The API does not support filtering
versions by date, so if `modified_between` is used, all versions are
requested and `n` is applied afterward. SharePoint may combine edits
made close together into a single version.

## Version IDs

Version IDs (e.g. `"3.0"`) are only unique within a single item. Use
`item_cols = "id"` (the default) to keep the item ID alongside the
version ID if you combine the results for more than one item.

See the Microsoft Graph documentation for [listing
versions](https://learn.microsoft.com/en-us/graph/api/driveitem-list-versions)
and the [driveItemVersion
resource](https://learn.microsoft.com/en-us/graph/api/resources/driveitemversion).

## Examples

``` r
if (FALSE) { # \dontrun{
# List the five most recent versions of a file
list_sp_item_versions(item_url = "<SharePoint file URL>", n = 5)

# Versions saved in October 2026
list_sp_item_versions(
  item_url = "<SharePoint file URL>",
  modified_between = c("2026-10-01", "2026-10-31")
)
} # }
```

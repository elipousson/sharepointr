# Get a SharePoint item

`get_sp_item()` wraps the `get_item` method for `ms_drive` objects and
returns a `ms_drive_item` object by default. Additional parameters in
`...` are passed to
[`get_sp_drive()`](https://elipousson.github.io/sharepointr/reference/sp_drive.md).

Use
[`get_sp_item_properties()`](https://elipousson.github.io/sharepointr/reference/sp_item_properties.md)
to get the item properties instead. Setting `properties = TRUE` returns
the same properties, but only
[`get_sp_item_properties()`](https://elipousson.github.io/sharepointr/reference/sp_item_properties.md)
can include the document library column values (fields) for the item.

## Usage

``` r
get_sp_item(
  path = NULL,
  item_id = NULL,
  item_url = NULL,
  ...,
  drive_name = NULL,
  drive_id = NULL,
  drive = NULL,
  site_url = NULL,
  properties = FALSE,
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

  Arguments passed on to
  [`get_sp_drive`](https://elipousson.github.io/sharepointr/reference/sp_drive.md)

  `drive_name,drive_id`

  :   SharePoint Drive name or ID passed to `get_drive` method for
      SharePoint site object.

  `drive_url`

  :   A SharePoint Drive URL to parse for a Drive name and other
      information. If `drive_name` is a URL, it is used as `drive_url`.

  `default_drive_name`

  :   Drive name string used only if input is a document URL and drive
      name is not part of the URL. Defaults to
      `getOption("sharepointr.default_drive_name", "Documents")`

  `cache`

  :   If `TRUE`, cache drive to a file using
      [`cache_sp_drive()`](https://elipousson.github.io/sharepointr/reference/sp_drive.md).

  `refresh`

  :   If `TRUE`, get a new drive even if the existing drive is cached as
      a local option. If `FALSE`, use the cached `ms_drive` object if it
      exists.

  `cache_file`

  :   File name for cached drive or site. Default `NULL`.

  `site`

  :   A `ms_site` object. If `site` is supplied, `site_url`,
      `site_name`, and `site_id` are ignored.

  `overwrite`

  :   If `TRUE`, replace the existing cached object named by
      `cache_file` with the new object. If `FALSE`, error if a cached
      file with the same `cache_file` name already exists.

- drive_name, drive_id:

  SharePoint drive name or ID.

- drive:

  A `ms_drive` object. If drive is supplied, `drive_name`, `site_url`,
  and any additional parameters passed to `...` are ignored.

- site_url:

  A SharePoint site URL in the format "https://\[tenant
  name\].sharepoint.com/sites/\[site name\]". Any SharePoint item or
  document URL can also be parsed to build a site URL using the tenant
  and site name included in the URL.

- properties:

  If `TRUE`, use the `get_item_properties` method and return item
  properties instead of the item.

- as_data_frame:

  If `TRUE`, return a data frame. If `FALSE` (default), return a
  `ms_item` or `ms_item_properties` object.

- call:

  The execution environment of a currently running function, e.g.
  `caller_env()`. The function will be mentioned in error messages as
  the source of the error. See the `call` argument of
  [`abort()`](https://rlang.r-lib.org/reference/abort.html) for more
  information.

## Value

A `ms_drive_item` object (or a list of item properties if
`properties = TRUE`), or a 1 row data frame if `as_data_frame = TRUE`.

## See also

[`get_sp_item_properties()`](https://elipousson.github.io/sharepointr/reference/sp_item_properties.md),
[Microsoft365R::ms_drive_item](https://rdrr.io/pkg/Microsoft365R/man/ms_drive_item.html)

## Examples

``` r
sp_item_url <- "<SharePoint item url>"

if (is_sp_url(sp_item_url)) {
  get_sp_item(
    item_url = sp_item_url
  )
}
```

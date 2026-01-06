# List versions for a SharePoint item

This is an implementation of a new method for a `ms_item` object using
the `do_operation` method directly. The intent is to add a list_versions
method back to the Microsoft365R package which may include changes to
the functionality and output of this function.

## Usage

``` r
list_sp_item_versions(..., sp_item = NULL, as_data_frame = TRUE)
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

  `call`

  :   The execution environment of a currently running function, e.g.
      `caller_env()`. The function will be mentioned in error messages
      as the source of the error. See the `call` argument of
      [`abort()`](https://rlang.r-lib.org/reference/abort.html) for more
      information.

- sp_item:

  SharePoint item to get versions for. Additional parameters passed to
  `...` are ignored if sp_item is supplied.

- as_data_frame:

  If `TRUE`, return a data frame of versions. If `FALSE`, return a list.

## Value

A data frame if `as_data_frame = TRUE` or a list if `FALSE`.

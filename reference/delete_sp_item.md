# Delete SharePoint items (files and directories)

`delete_sp_item()` deletes items including files and directories using
the `delete` method for . By default `confirm = TRUE`, which requires
the user to respond to a prompt: "Do you really want to delete the drive
item ...? (yes/No/cancel)" to continue.

## Usage

``` r
delete_sp_item(
  path = NULL,
  confirm = TRUE,
  by_item = FALSE,
  ...,
  item_id = NULL,
  item_url = NULL,
  item = NULL,
  drive_name = NULL,
  drive_id = NULL,
  drive = NULL,
  site_url = NULL,
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

- confirm:

  If `TRUE`, confirm before deleting item. If `TRUE` and session is not
  interactive, the function will error.

- by_item:

  For business OneDrive or SharePoint document libraries, you may need
  to set `by_item = TRUE` to delete the contents of a folder depending
  on the policies set up by your SharePoint administrator policies.
  Note, that this method can be slow for large folders.

- ...:

  Arguments passed on to
  [`get_sp_item`](https://elipousson.github.io/sharepointr/reference/get_sp_item.md)

  `drive_name,drive_id`

  :   SharePoint drive name or ID.

  `as_data_frame`

  :   If `TRUE`, return a data frame. If `FALSE` (default), return a
      `ms_item` or `ms_item_properties` object.

- item_id:

  A SharePoint item ID passed to the `itemid` parameter of the
  `get_item` method for `ms_drive` objects.

- item_url:

  A SharePoint item URL used to parse the item ID, drive name, and site
  URL.

- item:

  A `ms_drive_item` class object. Optional if path or other parameters
  to get an SharePoint item are supplied.

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

- call:

  The execution environment of a currently running function, e.g.
  `caller_env()`. The function will be mentioned in error messages as
  the source of the error. See the `call` argument of
  [`abort()`](https://rlang.r-lib.org/reference/abort.html) for more
  information.

## Details

Trouble-shooting errors

If you get the error: "The resource you are attempting to access is
locked", you or another user may have the file or a file within the
directory open for editing. Close the file and try deleting the item
again.

If you get the error: "Request was cancelled by event received. If
attempting to delete a non-empty folder, it's possible that it's on
hold." set `by_item = TRUE` and try again.

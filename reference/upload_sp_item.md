# Upload a file or folder to a SharePoint Drive

`upload_sp_item()` wraps the `upload_folder` and `upload_file` method
for `ms_drive` objects. `upload_sp_items()` uploads multiple files or
folders. If `{carrier}` and `{mirai}` are installed and
[`mirai::daemons()`](https://mirai.r-lib.org/reference/daemons.html) are
set, `upload_sp_items()` uploads files in parallel (folders are always
uploaded one at a time).

## Usage

``` r
upload_sp_item(
  file = NULL,
  dest = NULL,
  ...,
  src = NULL,
  overwrite = FALSE,
  drive_name = NULL,
  drive_id = NULL,
  drive = NULL,
  blocksize = 327680000,
  recursive = FALSE,
  parallel = FALSE,
  call = caller_env()
)

upload_sp_items(
  file = NULL,
  dest,
  ...,
  src = NULL,
  overwrite = FALSE,
  drive_name = NULL,
  drive_id = NULL,
  drive = NULL,
  blocksize = 327680000,
  recursive = FALSE,
  parallel = FALSE,
  call = caller_env()
)
```

## Arguments

- file:

  Path for file or directory to upload. Optional if `src` is supplied.

- dest:

  Destination on SharePoint for file to upload. Must be a
  `ms_drive_item` for a folder, a SharePoint folder URL, or a drive
  path. If a `ms_drive_item` is provided and `drive_name` is `NULL`, the
  item URL is used to determine the drive. If `NULL`, the top level of
  the provided drive is used as the destination. If file is a directory,
  `dest` must be an *existing* directory. If `dest` is a SharePoint
  folder or document library URL and `drive_name`, `drive_id`, and
  `drive` aren't supplied, the drive and folder are found with the
  [Microsoft Graph shares
  API](https://learn.microsoft.com/en-us/graph/api/shares-get) (see
  [`get_sp_item()`](https://elipousson.github.io/sharepointr/reference/get_sp_item.md)).
  If the request fails, the drive and folder path are parsed from the
  URL instead. For `upload_sp_items()`, `dest` can also be a character
  vector with one destination for each file. Destinations can be in
  different drives.

- ...:

  Additional parameters passed to
  [`get_sp_site()`](https://elipousson.github.io/sharepointr/reference/sp_site.md)
  or
  [`Microsoft365R::get_sharepoint_site()`](https://rdrr.io/pkg/Microsoft365R/man/client.html).

- src:

  Data source path passed to `upload_folder` or `upload_file` method.
  Defaults to `NULL` and set to use file value by default.

- overwrite:

  If `FALSE` (default), error if an item with the name specified in
  `file` or `src` already exists at the specified destination. If
  `TRUE`, overwrite any existing items with the same name. The latter is
  the default for the `upload_file` method.

- drive_name, drive_id:

  SharePoint drive name or ID.

- drive:

  A `ms_drive` object. If drive is supplied, `drive_name`, `site_url`,
  and any additional parameters passed to `...` are ignored.

- blocksize, recursive, parallel:

  Additional parameters passed to `upload_folder` or `upload_file`
  method for `ms_drive` objects.

- call:

  The execution environment of a currently running function, e.g.
  `caller_env()`. The function will be mentioned in error messages as
  the source of the error. See the `call` argument of
  [`abort()`](https://rlang.r-lib.org/reference/abort.html) for more
  information.

## Value

Invisibly returns the destination path (`dest`) for the uploaded file or
directory.

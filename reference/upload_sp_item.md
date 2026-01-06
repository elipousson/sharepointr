# Upload a file or folder to a SharePoint Drive

`upload_sp_item()` wraps the `upload_folder` and `upload_file` method
for `ms_drive` objects.

## Usage

``` r
upload_sp_item(
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

upload_sp_items(file = NULL, dest, ..., src = NULL, call = caller_env())
```

## Arguments

- file:

  Path for file or directory to upload. Optional if `src` is supplied.

- dest:

  Destination on SharePoint for file to upload. SharePoint folder URLs
  are supported.

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

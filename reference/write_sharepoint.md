# Write an object to file and upload file to SharePoint

`write_sharepoint()` uses
[`upload_sp_item()`](https://elipousson.github.io/sharepointr/reference/upload_sp_item.md)
to upload an object created using:

- [`sf::write_sf()`](https://r-spatial.github.io/sf/reference/st_write.html)
  if x is an `sf` object

- [`readr::write_csv()`](https://readr.tidyverse.org/reference/write_delim.html)
  if x is a `data.frame` and file does not include a xlsx extension

- [`openxlsx2::write_xlsx()`](https://janmarvin.github.io/openxlsx2/reference/write_xlsx.html)
  if x is a `data.frame` file does include a xlsx extension

- The [`print()`](https://rdrr.io/r/base/print.html) method from
  `{officer}` if x is a `rdocx`, `rpptx`, or `rxlsx` object

- [`readr::write_rds()`](https://readr.tidyverse.org/reference/read_rds.html)
  if x is any other class

## Usage

``` r
write_sharepoint(
  x,
  file,
  dest,
  ...,
  .f = NULL,
  new_path = tempdir(),
  overwrite = FALSE,
  drive_name = NULL,
  drive_id = NULL,
  drive = NULL,
  site_url = NULL,
  site_name = NULL,
  site_id = NULL,
  site = NULL,
  blocksize = 327680000,
  call = caller_env()
)
```

## Arguments

- x:

  Object to write to file and upload to SharePoint. `sf`, `rdocx`,
  `rpptx`, `rxlsx`, and `data.frame` objects are saved with the
  functions noted in the description. All other object types are saved
  as `rds` outputs.

- file:

  File to write to. Passed to `file` parameter for
  [`readr::write_csv()`](https://readr.tidyverse.org/reference/write_delim.html)
  or
  [`readr::write_rds()`](https://readr.tidyverse.org/reference/read_rds.html),
  `dsn` for
  [`sf::write_sf()`](https://r-spatial.github.io/sf/reference/st_write.html),
  or `target` for [`print()`](https://rdrr.io/r/base/print.html) (when
  working with `{officer}` class objects).

- dest:

  Destination on SharePoint for file to upload. SharePoint folder URLs
  are supported.

- ...:

  Additional parameters passed to write function.

- .f:

  Optional function to write the input data to disk before uploading
  file to SharePoint.

- new_path:

  Path to write file to. Defaults to
  [`tempdir()`](https://rdrr.io/r/base/tempfile.html)

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

- site_url:

  A SharePoint site URL in the format "https://\[tenant
  name\].sharepoint.com/sites/\[site name\]". Any SharePoint item or
  document URL can also be parsed to build a site URL using the tenant
  and site name included in the URL.

- site_name, site_id:

  Site name or ID of the SharePoint site as an alternative to the
  SharePoint site URL. Exactly one of `site_url`, `site_name`, and
  `site_id` must be supplied.

- site:

  A `ms_site` object. If `site` is supplied, `site_url`, `site_name`,
  and `site_id` are ignored.

- blocksize:

  Additional parameter passed to `upload_folder` or `upload_file` method
  for `ms_drive` objects.

- call:

  The execution environment of a currently running function, e.g.
  `caller_env()`. The function will be mentioned in error messages as
  the source of the error. See the `call` argument of
  [`abort()`](https://rlang.r-lib.org/reference/abort.html) for more
  information.

## Value

Invisibly returns the input object x.

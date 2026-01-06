# Get a SharePoint drive or set a default SharePoint drive

`get_sp_drive()` wraps the `get_drive` method returns a `ms_drive`
object.

`cache_sp_drive()` allows you to cache a default SharePoint drive for
use by other functions. Additional parameters in `...` are passed to
`get_sp_drive()`.

## Usage

``` r
get_sp_drive(
  drive_name = NULL,
  drive_id = NULL,
  drive_url = NULL,
  properties = FALSE,
  ...,
  site_url = NULL,
  site = NULL,
  default_drive_name = getOption("sharepointr.default_drive_name", "Documents"),
  cache = getOption("sharepointr.cache", FALSE),
  refresh = getOption("sharepointr.refresh", TRUE),
  overwrite = FALSE,
  cache_file = NULL,
  call = caller_env()
)

cache_sp_drive(
  ...,
  drive = NULL,
  cache_file = getOption("sharepointr.cache_file_drive", "sp_drive.rds"),
  overwrite = FALSE,
  call = caller_env()
)
```

## Arguments

- drive_name, drive_id:

  SharePoint Drive name or ID passed to `get_drive` method for
  SharePoint site object.

- drive_url:

  A SharePoint Drive URL to parse for a Drive name and other
  information. If `drive_name` is a URL, it is used as `drive_url`.

- properties:

  If `TRUE`, return the drive properties instead of the `ms_drive`
  object. Defaults to `FALSE`.

- ...:

  Arguments passed on to
  [`get_sp_site`](https://elipousson.github.io/sharepointr/reference/sp_site.md)

  `site_name,site_id`

  :   Site name or ID of the SharePoint site as an alternative to the
      SharePoint site URL. Exactly one of `site_url`, `site_name`, and
      `site_id` must be supplied.

- site_url:

  A SharePoint site URL in the format "https://\[tenant
  name\].sharepoint.com/sites/\[site name\]". Any SharePoint item or
  document URL can also be parsed to build a site URL using the tenant
  and site name included in the URL.

- site:

  A `ms_site` object. If `site` is supplied, `site_url`, `site_name`,
  and `site_id` are ignored.

- default_drive_name:

  Drive name string used only if input is a document URL and drive name
  is not part of the URL. Defaults to
  `getOption("sharepointr.default_drive_name", "Documents")`

- cache:

  If `TRUE`, cache drive to a file using `cache_sp_drive()`.

- refresh:

  If `TRUE`, get a new drive even if the existing drive is cached as a
  local option. If `FALSE`, use the cached `ms_drive` object if it
  exists.

- overwrite:

  If `TRUE`, replace the existing cached object named by `cache_file`
  with the new object. If `FALSE`, error if a cached file with the same
  `cache_file` name already exists.

- cache_file:

  File name for cached drive or site. Default `NULL`.

- call:

  The execution environment of a currently running function, e.g.
  `caller_env()`. The function will be mentioned in error messages as
  the source of the error. See the `call` argument of
  [`abort()`](https://rlang.r-lib.org/reference/abort.html) for more
  information.

- drive:

  A `ms_drive` object. If `drive` is supplied, `drive_name` and
  `drive_id` are ignored.

## See also

[Microsoft365R::ms_drive](https://rdrr.io/pkg/Microsoft365R/man/ms_drive.html)

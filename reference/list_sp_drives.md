# List drives for a SharePoint site

`list_sp_drives()` loads a SharePoint site uses the `list_drives` method
to returns a data frame with a list column or `ms_drive` objects or, if
`as_data_frame = FALSE`. This is helpful if a drive has been renamed and
can't easily be identified using a Drive URL alone.

## Usage

``` r
list_sp_drives(
  ...,
  site = NULL,
  filter = NULL,
  n = NULL,
  as_data_frame = TRUE,
  call = caller_env()
)
```

## Arguments

- ...:

  Arguments passed on to
  [`get_sp_site`](https://elipousson.github.io/sharepointr/reference/sp_site.md)

  `site_url`

  :   A SharePoint site URL in the format "https://\[tenant
      name\].sharepoint.com/sites/\[site name\]". Any SharePoint item or
      document URL can also be parsed to build a site URL using the
      tenant and site name included in the URL.

  `site_name,site_id`

  :   Site name or ID of the SharePoint site as an alternative to the
      SharePoint site URL. Exactly one of `site_url`, `site_name`, and
      `site_id` must be supplied.

  `refresh`

  :   If `TRUE`, get a new site even if the existing site is cached as a
      local option. If `FALSE`, use the cached `ms_site` object.

  `cache`

  :   If `TRUE`, cache site to a file using
      [`cache_sp_site()`](https://elipousson.github.io/sharepointr/reference/sp_site.md).

  `cache_file`

  :   File name for cached drive or site. Default `NULL`.

  `overwrite`

  :   If `TRUE`, replace the existing cached object named by
      `cache_file` with the new object. If `FALSE`, error if a cached
      file with the same `cache_file` name already exists.

- site:

  A `ms_site` object. If `site` is supplied, `site_url`, `site_name`,
  and `site_id` are ignored.

- filter:

  Filter to apply to query

- n:

  Max number of drives to return

- as_data_frame:

  If `TRUE` (default), return list as a data frame.

- call:

  The execution environment of a currently running function, e.g.
  `caller_env()`. The function will be mentioned in error messages as
  the source of the error. See the `call` argument of
  [`abort()`](https://rlang.r-lib.org/reference/abort.html) for more
  information.

## See also

[Microsoft365R::ms_site](https://rdrr.io/pkg/Microsoft365R/man/ms_site.html)

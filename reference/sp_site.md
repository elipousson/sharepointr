# Get a SharePoint site or set a default SharePoint site

`get_sp_site()` is a wrapper for
[`Microsoft365R::get_sharepoint_site()`](https://rdrr.io/pkg/Microsoft365R/man/client.html)
and returns a `ms_site` object. `cache_sp_site()` allows you to cache a
default SharePoint site for use by other functions. Users seeking to
access a SharePoint subsite must provide the `site_id` instead of a
`site_url` or `site_name` value. You can see available subsite ID values
by using the `list_subsites()` method for
[`Microsoft365R::ms_site`](https://rdrr.io/pkg/Microsoft365R/man/ms_site.html)
objects.

## Usage

``` r
get_sp_site(
  site_url = NULL,
  site_name = NULL,
  site_id = NULL,
  ...,
  cache = getOption("sharepointr.cache", FALSE),
  refresh = getOption("sharepointr.refresh", TRUE),
  overwrite = FALSE,
  cache_file = NULL,
  call = caller_env()
)

cache_sp_site(
  ...,
  site = NULL,
  cache_file = NULL,
  cache_dir = NULL,
  overwrite = FALSE,
  call = caller_env()
)
```

## Arguments

- site_url:

  A SharePoint site URL in the format "https://\[tenant
  name\].sharepoint.com/sites/\[site name\]". Any SharePoint item or
  document URL can also be parsed to build a site URL using the tenant
  and site name included in the URL.

- site_name, site_id:

  Site name or ID of the SharePoint site as an alternative to the
  SharePoint site URL. Exactly one of `site_url`, `site_name`, and
  `site_id` must be supplied.

- ...:

  Arguments passed on to
  [`Microsoft365R::get_sharepoint_site`](https://rdrr.io/pkg/Microsoft365R/man/client.html)

  `app`

  :   A custom app registration ID to use for authentication. See below.

  `scopes`

  :   The Microsoft Graph scopes (permissions) to obtain. It should
      never be necessary to change these.

  `token`

  :   An AAD OAuth token object, of class
      [`AzureAuth::AzureToken`](https://rdrr.io/pkg/AzureAuth/man/AzureToken.html).
      If supplied, the `tenant`, `app`, `scopes` and `...` arguments
      will be ignored. See "Authenticating with a token" below.

  `tenant`

  :   For `get_business_onedrive`, `get_sharepoint_site` and `get_team`,
      the name of your Azure Active Directory (AAD) tenant. If not
      supplied, use the value of the `CLIMICROSOFT365_TENANT`
      environment variable, or "common" if that is unset.

- cache:

  If `TRUE`, cache site to a file using `cache_sp_site()`.

- refresh:

  If `TRUE`, get a new site even if the existing site is cached as a
  local option. If `FALSE`, use the cached `ms_site` object.

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

- site:

  A `ms_site` object. If `site` is supplied, `site_url`, `site_name`,
  and `site_id` are ignored.

- cache_dir:

  Cache directory. By default, uses an option named
  "sharepointr.cache_dir". If "sharepointr.cache_dir" is not set, the
  cache directory is set to `rappdirs::user_cache_dir("sharepointr")`.

## See also

[Microsoft365R::ms_site](https://rdrr.io/pkg/Microsoft365R/man/ms_site.html)

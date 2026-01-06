# List SharePoint pages or get a single SharePoint page

`list_sp_pages()` returns a list of SharePoint pages associated with a
specified SharePoint site. `get_sp_page()` returns a single SharePoint
page.

## Usage

``` r
list_sp_pages(
  ...,
  site = NULL,
  page_type = c("sitePage", "page"),
  as_data_frame = TRUE,
  call = caller_env()
)

get_sp_page(page_url = NULL, page_id = NULL, ..., site = NULL)
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

  Optional `ms_site` object to use. If not provided, the `...` arguments
  are passed to
  [`get_sp_site()`](https://elipousson.github.io/sharepointr/reference/sp_site.md).

- page_type:

  Page type to request. One of "sitePage" or "page".

- as_data_frame:

  If `TRUE`, return a data frame with details on the SharePoint site
  pages. If `FALSE`, return a list.

- call:

  The execution environment of a currently running function, e.g.
  `caller_env()`. The function will be mentioned in error messages as
  the source of the error. See the `call` argument of
  [`abort()`](https://rlang.r-lib.org/reference/abort.html) for more
  information.

- page_url, page_id:

  SharePoint page URL or ID.

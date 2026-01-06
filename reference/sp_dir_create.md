# Create SharePoint folders

`sp_dir_create()` is a wrapper for the `create_folder` method that
handles character vectors. If `drive_name` is a folder URL and
`relative` is `TRUE`, the values for `path` are appended to the file
path parsed from the url.

## Usage

``` r
sp_dir_create(
  path,
  ...,
  drive_name = NULL,
  drive_id = NULL,
  drive = NULL,
  relative = FALSE,
  call = caller_env()
)
```

## Arguments

- path:

  A character vector of one or more paths.

- ...:

  Arguments passed on to
  [`get_sp_drive`](https://elipousson.github.io/sharepointr/reference/sp_drive.md)

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

  `site_url`

  :   A SharePoint site URL in the format "https://\[tenant
      name\].sharepoint.com/sites/\[site name\]". Any SharePoint item or
      document URL can also be parsed to build a site URL using the
      tenant and site name included in the URL.

  `site`

  :   A `ms_site` object. If `site` is supplied, `site_url`,
      `site_name`, and `site_id` are ignored.

  `overwrite`

  :   If `TRUE`, replace the existing cached object named by
      `cache_file` with the new object. If `FALSE`, error if a cached
      file with the same `cache_file` name already exists.

- drive_name, drive_id:

  SharePoint Drive name or ID passed to `get_drive` method for
  SharePoint site object.

- drive:

  A `ms_drive` object. If `drive` is supplied, `drive_name` and
  `drive_id` are ignored.

- relative:

  If `TRUE` and `drive_name` is a folder URL, the values for `path` are
  appended to the file path parsed from the url. If `relative` is a
  character vector, it must be length 1 or the same length as path and
  appended to path as a vector of parent directories. The second option
  takes precedence over any file path parsed from the url.

- call:

  The execution environment of a currently running function, e.g.
  `caller_env()`. The function will be mentioned in error messages as
  the source of the error. See the `call` argument of
  [`abort()`](https://rlang.r-lib.org/reference/abort.html) for more
  information.

## Examples

``` r
drive_url <- "<link to SharePoint drive>"

if (is_sp_url(drive_url)) {
  sp_dir_create(
    path = "parent_folder/subfolder",
    drive_name = drive_url
  )

  sp_dir_create(
    path = c("subfolder1", "subfolder2", "subfolder3"),
    relative = "parent_folder",
    drive_name = drive_url
  )
}

dir_url <- "<link to SharePoint directory>"

if (is_sp_url(dir_url)) {
  sp_dir_create(
    path = c("subfolder1", "subfolder2", "subfolder3"),
    drive_name = dir_url,
    relative = TRUE
  )
}
```

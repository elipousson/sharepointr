# List SharePoint files and folders

`sp_dir_info()` is a wrapper for the `list_files` method with some
additional features based on
[`fs::dir_info()`](https://fs.r-lib.org/reference/dir_ls.html).
`sp_dir_ls()` returns a character vector and does not yet include
support for the `recurse` argument. If `{fs}` is installed, the size
column is formatted using
[`fs::as_fs_bytes()`](https://fs.r-lib.org/reference/fs_bytes.html) and
an additional "type" factor column is added with values for directory
and file.

## Usage

``` r
sp_dir_info(
  path = NULL,
  ...,
  info = "partial",
  select = NULL,
  full_names = TRUE,
  pagesize = 1000,
  drive_name = NULL,
  drive_id = NULL,
  drive = NULL,
  recurse = FALSE,
  sort = "name-asc",
  type = "any",
  regexp = NULL,
  invert = FALSE,
  perl = FALSE,
  .batch = getOption("sharepointr.batch", TRUE),
  call = caller_env()
)

sp_dir_ls(
  path = NULL,
  ...,
  full_names = FALSE,
  pagesize = 1000,
  drive_name = NULL,
  drive_id = NULL,
  drive = NULL,
  type = "any",
  regexp = NULL,
  invert = FALSE,
  perl = FALSE,
  call = caller_env()
)
```

## Arguments

- path:

  Path to directory or folder. SharePoint folder URLs are allowed. If
  `NULL`, path is set to default "/". `path` can be a string or a
  character vector. If a vector or path of URLs are supplied, provide a
  `drive` object to improve performance. If `path` is a SharePoint
  folder or document library URL and `drive_name`, `drive_id`, and
  `drive` aren't supplied, the drive and folder are found with the
  [Microsoft Graph shares
  API](https://learn.microsoft.com/en-us/graph/api/shares-get) (see
  [`get_sp_item()`](https://elipousson.github.io/sharepointr/reference/get_sp_item.md)).
  If the request fails, the drive and folder path are parsed from the
  URL instead.

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

  `site_url`

  :   A SharePoint site URL in the format "https://\[tenant
      name\].sharepoint.com/sites/\[site name\]". Any SharePoint item or
      document URL can also be parsed to build a site URL using the
      tenant and site name included in the URL.

  `cache_file`

  :   File name for cached drive or site. Default `NULL`.

  `site`

  :   A `ms_site` object. If `site` is supplied, `site_url`,
      `site_name`, and `site_id` are ignored.

  `overwrite`

  :   If `TRUE`, replace the existing cached object named by
      `cache_file` with the new object. If `FALSE`, error if a cached
      file with the same `cache_file` name already exists.

- info:

  The information to return: "partial", "name" or "all". If "partial", a
  data frame is returned containing the name, size, ID and whether the
  item is a file or folder. If "all", a data frame is returned
  containing all the properties for each item (this can be large).

- select:

  A character vector of [driveItem
  properties](https://learn.microsoft.com/en-us/graph/api/resources/driveitem)
  to return in addition to the name, size, ID, and `isdir` columns, e.g.
  `c("webUrl", "lastModifiedDateTime")`. Passed to the Graph API as the
  `$select` query parameter so only these properties are requested. If
  supplied, `info` must be "partial" (the default) or "all" and "all" is
  treated as "partial". Properties used by `sort` are always included.

- full_names:

  If `TRUE` (default), return the full file path as the name for each
  item.

- pagesize:

  Maximum number of items to return. Defaults to 1000. Decrease if you
  are experiencing timeouts.

- drive_name, drive_id:

  SharePoint Drive name or ID passed to `get_drive` method for
  SharePoint site object.

- drive:

  A `ms_drive` object. If `drive` is supplied, `drive_name` and
  `drive_id` are ignored.

- recurse:

  If `TRUE`, get info for each directory at the supplied path and
  combine this info with the item info for the supplied path.
  Directories are listed one level at a time and a single progress bar
  reports the number of directories listed and queued.

- sort:

  How to sort the result: "name-asc" (default), "name-desc", "size-asc",
  "size-desc", "created-asc", "created-desc", "modified-asc",
  "modified-desc", or "none" to keep the order that directories were
  listed in. Names are sorted in C-locale order so uppercase letters
  sort before lowercase letters. `sort` is ignored if `info = "name"`.
  The properties used by `sort` are added to the result if they are not
  already included. `sort` is applied if `recurse = TRUE` or if `sort`
  is supplied; otherwise the order returned by SharePoint is kept.

- type:

  Type of item to return. Can be "any", "file", or "directory".
  "directory" is not a supported option for `sp_dir_ls()`. As with
  [`fs::dir_info()`](https://fs.r-lib.org/reference/dir_ls.html), if
  `recurse = TRUE`, all directories are searched whatever the value of
  `type`, and `type` only filters the items returned.

- regexp:

  Regular expression passed to
  [`grep()`](https://rdrr.io/r/base/grep.html) and used to filter the
  items before they are returned. As with
  [`fs::dir_info()`](https://fs.r-lib.org/reference/dir_ls.html),
  `regexp` is applied after all directories are listed, so directories
  that do not match are still searched if `recurse = TRUE`. If
  `full_names = TRUE`, `regexp` is matched against the full path. If
  `full_names = FALSE`, it is matched against the item name only (unlike
  [`fs::dir_info()`](https://fs.r-lib.org/reference/dir_ls.html)).

- invert:

  logical. If `TRUE` return indices or values for elements that do *not*
  match.

- perl:

  logical. Should Perl-compatible regexps be used?

- .batch:

  If `TRUE` (default), the directories at each level of a recursive
  listing are requested with Microsoft Graph
  [\$batch](https://learn.microsoft.com/en-us/graph/json-batching)
  requests (up to 20 directories per request), which is much faster than
  a request per directory. If `{carrier}` and `{mirai}` are installed
  and
  [`mirai::daemons()`](https://mirai.r-lib.org/reference/daemons.html)
  are set, the `$batch` requests for each level are sent in parallel and
  the progress bar is updated after each level. Use `.batch = FALSE` or
  `options(sharepointr.batch = FALSE)` to send a request per directory.

- call:

  The execution environment of a currently running function, e.g.
  `caller_env()`. The function will be mentioned in error messages as
  the source of the error. See the `call` argument of
  [`abort()`](https://rlang.r-lib.org/reference/abort.html) for more
  information.

## Value

For `sp_dir_info()`, a data frame with one row per file or folder at
`path`, with columns determined by `info` (`"partial"`, `"name"`, or
`"all"`). For `sp_dir_ls()`, a character vector of file and folder names
or paths.

## Examples

``` r
dir_url <- "<link to SharePoint directory or drive>"

if (is_sp_url(dir_url)) {
  sp_dir_info(
    path = dir_url
  )

  sp_dir_ls(
    path = dir_url
  )
}
```

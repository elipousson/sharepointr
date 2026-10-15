# Copy or move SharePoint files and folders

These functions copy or move items in a SharePoint document library.
Their interface is based on
[`fs::file_copy()`](https://fs.r-lib.org/reference/copy.html),
[`fs::file_move()`](https://fs.r-lib.org/reference/file_move.html), and
[`fs::dir_copy()`](https://fs.r-lib.org/reference/copy.html):

- `sp_item_copy()` copies files. Use `sp_dir_copy()` to copy folders.

- `sp_item_move()` moves (or renames) files or folders.

- `sp_dir_copy()` and `sp_dir_move()` copy or move folders and their
  contents.

As with `{fs}`, if `new_path` is an existing folder, each item is placed
inside that folder and keeps its name. Otherwise, `new_path` is the full
path for the new item and its parent folder must already exist. A
`new_path` that ends in `"/"` must be an existing folder.

`new_path` can be a path relative to the drive that holds the item, or a
SharePoint folder or document library URL. Items can be copied to
another drive or site, but they can only be moved within the same drive.

## Usage

``` r
sp_item_copy(
  path,
  new_path,
  ...,
  overwrite = FALSE,
  wait = TRUE,
  drive_name = NULL,
  drive_id = NULL,
  drive = NULL,
  site_url = NULL,
  call = caller_env()
)

sp_item_move(
  path,
  new_path,
  ...,
  overwrite = FALSE,
  drive_name = NULL,
  drive_id = NULL,
  drive = NULL,
  site_url = NULL,
  call = caller_env()
)

sp_dir_copy(
  path,
  new_path,
  ...,
  overwrite = FALSE,
  wait = TRUE,
  drive_name = NULL,
  drive_id = NULL,
  drive = NULL,
  site_url = NULL,
  call = caller_env()
)

sp_dir_move(
  path,
  new_path,
  ...,
  drive_name = NULL,
  drive_id = NULL,
  drive = NULL,
  site_url = NULL,
  call = caller_env()
)
```

## Arguments

- path:

  A character vector of file or folder paths, or SharePoint file or
  folder URLs. A relative path must not include the drive name. `path`
  can also be a `ms_drive_item` object or a list of `ms_drive_item`
  objects.

- new_path:

  A character vector of new paths, or SharePoint folder or document
  library URLs. `new_path` must be length 1 or the same length as
  `path`. A relative `new_path` is in the same drive as the item it is
  paired with.

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

  `site`

  :   A `ms_site` object. If `site` is supplied, `site_url`,
      `site_name`, and `site_id` are ignored.

- overwrite:

  If `FALSE` (default), an error is returned if an item already exists
  at the new path. If `TRUE`, an existing file is replaced. SharePoint
  can't replace a folder, so `sp_dir_copy()` works like
  [`fs::dir_copy()`](https://fs.r-lib.org/reference/copy.html) instead:
  if `new_path` is an existing folder and `overwrite = TRUE`, the
  contents of `path` are copied into `new_path` (replacing any files
  with the same name). `sp_dir_move()` has no `overwrite` argument
  because a folder can't be moved to an existing folder.

- wait:

  If `TRUE` (default), wait until each copy is complete. See details.

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

## Value

Invisibly returns a character vector with the new path of each item,
relative to the drive it was copied or moved to.

## Details

Copying is asynchronous

Microsoft Graph copies items in the background. If `wait = TRUE` (the
default), `sp_item_copy()` and `sp_dir_copy()` check the status of each
copy until it is complete, so they can report an error if a copy fails.
Large folders can take a while to copy. If `wait = FALSE`, the copy may
still be running when the function returns, and a failed copy isn't
reported.

## See also

[Microsoft365R::ms_drive_item](https://rdrr.io/pkg/Microsoft365R/man/ms_drive_item.html)

## Examples

``` r
dir_url <- "<link to SharePoint directory>"

if (is_sp_url(dir_url)) {
  drive <- get_sp_drive(drive_name = dir_url)

  # Copy a file into an existing folder
  sp_item_copy("Reports/report.docx", "Archive", drive = drive)

  # Rename a file
  sp_item_move(
    "Reports/report.docx",
    "Reports/report-2026.docx",
    drive = drive
  )

  # Copy a folder to a new folder named "Reports-backup"
  sp_dir_copy("Reports", "Reports-backup", drive = drive)

  # Move a folder into the folder at a SharePoint URL
  sp_dir_move("Reports-backup", dir_url, drive = drive)
}
```

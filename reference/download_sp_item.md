# Download one or more items from SharePoint to a file or folder

`download_sp_item()` wraps the `download` method for SharePoint items
making it easier to download items based on a shared file URL or
document URL.

## Usage

``` r
download_sp_item(
  path = NULL,
  new_path = "",
  ...,
  item_id = NULL,
  item_url = NULL,
  item = NULL,
  drive_name = NULL,
  drive_id = NULL,
  drive = NULL,
  site_url = NULL,
  dest = NULL,
  overwrite = FALSE,
  recursive = FALSE,
  parallel = FALSE,
  call = caller_env()
)

download_sp_file(file, new_path = "", ..., call = caller_env())
```

## Arguments

- path, file:

  Required. A SharePoint shared file URL, document URL, or, if `item_id`
  is supplied, a file name to use with `path` to set `dest` with
  location and filename for downloaded item.

- new_path:

  Path to directory for downloaded item. Optional if `dest` is supplied.
  If path contains a file name, the item will be downloaded using that
  file name instead of the file name of the original item. If `new_path`
  refers to a nonexistent directory and the item is a file, the
  directory will be silently created using
  [`fs::dir_create()`](https://fs.r-lib.org/reference/create.html).

- ...:

  Arguments passed on to
  [`get_sp_item`](https://elipousson.github.io/sharepointr/reference/get_sp_item.md)

  `drive_name,drive_id`

  :   SharePoint drive name or ID.

  `properties`

  :   If `TRUE`, use the `get_item_properties` method and return item
      properties instead of the item.

  `as_data_frame`

  :   If `TRUE`, return a data frame. If `FALSE` (default), return a
      `ms_item` or `ms_item_properties` object.

- item_id:

  A SharePoint item ID passed to the `itemid` parameter of the
  `get_item` method for `ms_drive` objects.

- item_url:

  A SharePoint item URL used to parse the item ID, drive name, and site
  URL.

- item:

  A `ms_drive_item` class object. Optional if path or other parameters
  to get an SharePoint item are supplied.

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

- dest, overwrite, recursive, parallel:

  Parameters passed to `download` method for `ms_drive_item` object.

- call:

  The execution environment of a currently running function, e.g.
  `caller_env()`. The function will be mentioned in error messages as
  the source of the error. See the `call` argument of
  [`abort()`](https://rlang.r-lib.org/reference/abort.html) for more
  information.

## Value

Invisibly returns the input `dest` or the `dest` parsed from the input
path or item properties.

## Details

The default value for `path` is `""` so, by default, SharePoint items
are downloaded to the current working directory. Set `overwrite = TRUE`
to allow this function to overwrite an existing file.
`download_sp_file()` is identical except for the name of the path
parameter (which is file instead of path).

Note, if the selected item is a folder and `recurse = TRUE`, it may take
some time to download the enclosed items and `{Microsoft365R}` does not
provide a progress bar for that operation.

## Batch downloads for SharePoint items

If provided with a vector of paths or a vector of item ID values,
`download_sp_item()` can execute a batch download on a set of files or
folders. Make sure to supply a vector to `new_path` or `dest` vector
with the directory names or file names to use as a destination for the
downloads. With either option, you must supply a `drive`, a `drive_name`
and `site`, or a `drive_url`. You can also pass a bare list of items and
the value for the `dest` can be inferred from the item properties.

## Examples

``` r
# Download a single directory

sp_dir_url <- "<SharePoint directory url>"

new_path <- "local file path"

if (is_sp_url(sp_dir_url)) {
  download_sp_item(
    sp_dir_url,
    new_path = new_path,
    recursive = TRUE
  )
}

# Batch download multiple directories from a SharePoint Drive

sp_drive_url <- "<SharePoint Drive url>"

if (is_sp_url(sp_drive_url)) {
  drive <- get_sp_drive(drive_name = sp_drive_url)

  drive_dir_list <- sp_dir_info(
    drive = drive,
    recurse = TRUE,
    type = "dir"
  )

  download_sp_item(
    item_id = drive_dir_list$id,
    dest = drive_dir_list$name,
    recursive = TRUE,
    drive = drive
  )
}
```

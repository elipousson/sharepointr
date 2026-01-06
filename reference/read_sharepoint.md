# Read a SharePoint item based on a file URL or file name and site details

`read_sharepoint()` is designed to download a SharePoint item to a
temporary folder and read the file based on the file extension. If a
function is provided to .f, it is used to read the downloaded file. If
not, class of the returned object depends on the file extension of the
file parameter.

- If the file is a csv, csv2, or tsv file or a Microsoft Excel file
  (xlsx or xls),
  [`readr::read_delim()`](https://readr.tidyverse.org/reference/read_delim.html)
  or
  [`readxl::read_excel()`](https://readxl.tidyverse.org/reference/read_excel.html)
  is used to return a data frame.

- If the file is a rds file,
  [`readr::read_rds()`](https://readr.tidyverse.org/reference/read_rds.html)
  is used to return the saved object.

- If the file is a pptx or docx file,
  [`officer::read_docx()`](https://davidgohel.github.io/officer/reference/read_docx.html)
  or
  [`officer::read_pptx()`](https://davidgohel.github.io/officer/reference/read_pptx.html)
  are used to read the file into a `rdocx` or `rpptx` object.

- If the file has a "gpkg", "geojson", "kml", "gdb", or "zip" file
  extension,
  [`sf::read_sf()`](https://r-spatial.github.io/sf/reference/st_read.html)
  is used to read the file into a `sf` data frame.

If the file has none of these file extensions, an attempt is made to
read the file with
[`readr::read_lines()`](https://readr.tidyverse.org/reference/read_lines.html).

The function also serves as a wrapper for
[`list_sp_list_items()`](https://elipousson.github.io/sharepointr/reference/sp_list_item.md)
if the provided `file` parameter is a SharePoint list URL.

## Usage

``` r
read_sharepoint(
  file,
  ...,
  .f = NULL,
  new_path = tempdir(),
  overwrite = TRUE,
  drive_name = NULL,
  drive_id = NULL,
  drive = NULL,
  site_url = NULL,
  site_name = NULL,
  site_id = NULL,
  site = NULL
)
```

## Arguments

- file:

  Required. A SharePoint shared file URL, document URL, or, if `item_id`
  is supplied, a file name to use in combination with `new_path` to set
  `dest` with location and filename for downloaded item. If file appears
  to be a SharePoint list URL, the list items are retrived with
  [`list_sp_list_items()`](https://elipousson.github.io/sharepointr/reference/sp_list_item.md).

- ...:

  Additional parameters passed to one of the functions identified in the
  description or supplied to `.f`

- .f:

  Optional function to use to read file downloaded from SharePoint.

- new_path:

  Path to directory for downloaded item. Optional if `dest` is supplied.
  If path contains a file name, the item will be downloaded using that
  file name instead of the file name of the original item. If `new_path`
  refers to a nonexistent directory and the item is a file, the
  directory will be silently created using
  [`fs::dir_create()`](https://fs.r-lib.org/reference/create.html).

- overwrite:

  If `TRUE`, replace the existing cached object named by `cache_file`
  with the new object. If `FALSE`, error if a cached file with the same
  `cache_file` name already exists.

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

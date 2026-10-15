# Reading and writing items from SharePoint

``` r

library(sharepointr)
```

sharepointr builds on the `ms_site`, `ms_drive`, and `ms_drive_item`
objects from [`{Microsoft365R}`](https://github.com/Azure/Microsoft365R)
and the [Microsoft Graph API for
files](https://learn.microsoft.com/en-us/graph/api/resources/onedrive)
(SharePoint document libraries are “drives” and files and folders are
[“drive
items”](https://learn.microsoft.com/en-us/graph/api/resources/driveitem)).
Most functions accept a SharePoint URL in place of these objects. See
the Microsoft365R article on [OneDrive and
SharePoint](https://cran.r-project.org/web/packages/Microsoft365R/vignettes/od_sp.html)
for more on the underlying methods and the Microsoft365R article on
[authentication](https://cran.r-project.org/web/packages/Microsoft365R/vignettes/auth.html)
if you have trouble logging in.

## Downloading and reading files from SharePoint

You can use
[`download_sp_item()`](https://elipousson.github.io/sharepointr/reference/download_sp_item.md)
to download files or folders from SharePoint:

``` r
docx_url <- "https://bmore.sharepoint.com/:w:/r/sites/MayorsOffice-DataGovernance/Policy%20Documents/Data%20Classification%20Standard.docx?d=w54a9ae7eaa894e94b6d6d14516f3aaa4&csf=1&web=1&e=ee7ZSX"

download_sp_item(
  path = docx_url,
  new_path = tempdir()
)
#> Loading Microsoft Graph login for default tenant
#> 
ℹ Downloading SharePoint item to ' ]8;;file:///var/folders/3f/50m42dx1333_dfqb5772j6_40000gn/T//RtmpIIrptB/Data Classification Standard.docx/var/folders/3f/50m42dx13 ]8;;…

✔ Downloading SharePoint item to ' ]8;;file:///var/folders/3f/50m42dx1333_dfqb5772j6_40000gn/T//RtmpIIrptB/Data Classification Standard.docx/var/folders/3f/50m42dx13 ]8;;…
```

For files on SharePoint,
[`read_sharepoint()`](https://elipousson.github.io/sharepointr/reference/read_sharepoint.md)
extends
[`download_sp_item()`](https://elipousson.github.io/sharepointr/reference/download_sp_item.md)
by downloading the selected item to a temporary folder and reading the
file based on the file extension:

- csv, csv2, or tsv files with
  [`readr::read_delim()`](https://readr.tidyverse.org/reference/read_delim.html)
  and xlsx or xls files with
  [`readxl::read_excel()`](https://readxl.tidyverse.org/reference/read_excel.html)
- rds files with
  [`readr::read_rds()`](https://readr.tidyverse.org/reference/read_rds.html)
- docx or pptx files with
  [`officer::read_docx()`](https://davidgohel.github.io/officer/reference/read_docx.html)
  or
  [`officer::read_pptx()`](https://davidgohel.github.io/officer/reference/read_pptx.html)
- gpkg, geojson, kml, gdb, or zip (shapefile) files with
  [`sf::read_sf()`](https://r-spatial.github.io/sf/reference/st_read.html)

``` r
docx <- read_sharepoint(docx_url)
#> Loading Microsoft Graph login for default tenant
#> 
ℹ Downloading SharePoint item to ' ]8;;file:///var/folders/3f/50m42dx1333_dfqb5772j6_40000gn/T//RtmpIIrptB/Data Classification Standard.docx/var/folders/3f/50m42dx13 ]8;;…

✔ Downloading SharePoint item to ' ]8;;file:///var/folders/3f/50m42dx1333_dfqb5772j6_40000gn/T//RtmpIIrptB/Data Classification Standard.docx/var/folders/3f/50m42dx13 ]8;;…
#> 
ℹ Reading item with ` ]8;;x-r-help:officer::read_docxofficer::read_docx ]8;;()`

✔ Reading item with ` ]8;;x-r-help:officer::read_docxofficer::read_docx ]8;;()` [59ms]

docx
#> rdocx document with 62 element(s)
#> 
#> * styles:
#>                 Normal              heading 1 
#>            "paragraph"            "paragraph" 
#>              heading 2 Default Paragraph Font 
#>            "paragraph"            "character" 
#>           Normal Table                No List 
#>                "table"            "numbering" 
#>         Heading 1 Char             Table Grid 
#>            "character"                "table" 
#>         List Paragraph         Heading 2 Char 
#>            "paragraph"            "character" 
#>                  Title             Title Char 
#>            "paragraph"            "character" 
#>           Normal (Web)                 header 
#>            "paragraph"            "paragraph" 
#>            Header Char                 footer 
#>            "character"            "paragraph" 
#>            Footer Char          markedcontent 
#>            "character"            "character" 
#>            TOC Heading                  toc 1 
#>            "paragraph"            "paragraph" 
#>                  toc 2              Hyperlink 
#>            "paragraph"            "character" 
#>                  toc 3                  toc 4 
#>            "paragraph"            "paragraph" 
#>                  toc 5                  toc 6 
#>            "paragraph"            "paragraph" 
#>                  toc 7                  toc 8 
#>            "paragraph"            "paragraph" 
#>                  toc 9     Unresolved Mention 
#>            "paragraph"            "character" 
#>      FollowedHyperlink               Revision 
#>            "character"            "paragraph" 
#>    Unresolved Mention1   annotation reference 
#>            "character"            "character" 
#>        annotation text      Comment Text Char 
#>            "paragraph"            "character" 
#>     annotation subject   Comment Subject Char 
#>            "paragraph"            "character" 
#>           Balloon Text      Balloon Text Char 
#>            "paragraph"            "character" 
#>          footnote text     Footnote Text Char 
#>            "paragraph"            "character" 
#>     footnote reference 
#>            "character"
```

Use the `.f` argument to read the file with a different function:

``` r
wb_url <- "https://bmore.sharepoint.com/:x:/r/sites/MayorsOffice-DataGovernance/Shared%20Documents/Data%20Governance/Agency%20Naming%20Conventions.xlsx?d=w98ecba59d1f84c23862c6ad71e7f8695&csf=1&web=1&e=sSuZYo"

wb <- read_sharepoint(wb_url, .f = openxlsx2::wb_load)
#> Loading Microsoft Graph login for default tenant
#> 
ℹ Downloading SharePoint item to ' ]8;;file:///var/folders/3f/50m42dx1333_dfqb5772j6_40000gn/T//RtmpIIrptB/Agency Naming Conventions.xlsx/var/folders/3f/50m42dx13 ]8;;…

✔ Downloading SharePoint item to ' ]8;;file:///var/folders/3f/50m42dx1333_dfqb5772j6_40000gn/T//RtmpIIrptB/Agency Naming Conventions.xlsx/var/folders/3f/50m42dx13 ]8;;…
#> 
ℹ Reading item with ` ]8;;x-r-help:openxlsx2::wb_loadopenxlsx2::wb_load ]8;;()`

✔ Reading item with ` ]8;;x-r-help:openxlsx2::wb_loadopenxlsx2::wb_load ]8;;()` [183ms]

wb
#> A Workbook object.
#>  
#> Worksheets:
#>  Sheets: Sheet1 
#>  Write order: 1
```

As a convenience,
[`read_sharepoint()`](https://elipousson.github.io/sharepointr/reference/read_sharepoint.md)
also reads the items from a SharePoint list URL using
[`list_sp_list_items()`](https://elipousson.github.io/sharepointr/reference/sp_list_item.md):

``` r
list_url <- "https://bmore.sharepoint.com/sites/MayorsOffice-DataGovernance/Lists/Data%20Governance%20Progress%20Tracker"

list_items <- read_sharepoint(list_url)
#> Loading Microsoft Graph login for default tenant
#> 
ℹ Getting list from SharePoint

✔ Getting list from SharePoint [292ms]
#> 
ℹ Getting list items from SharePoint

✔ Getting list items from SharePoint [368ms]

head(list_items[, 1:4])
#>   id ContentType
#> 1  1        Item
#> 2  2        Item
#> 3  3        Item
#> 4  4        Item
#> 5  5        Item
#> 6  6        Item
#>                                                 Title
#> 1                      Baltimore City Fire Department
#> 2                    Baltimore City Health Department
#> 3 Baltimore City Office of Information and Technology
#> 4                 Baltimore City Recreation and Parks
#> 5                               Department of Finance
#> 6                      Department of General Services
#>               Modified
#> 1 2022-07-22T14:26:20Z
#> 2 2022-09-22T21:16:22Z
#> 3 2022-07-22T14:10:49Z
#> 4 2022-07-22T14:11:19Z
#> 5 2022-07-22T14:14:15Z
#> 6 2022-07-22T14:11:25Z
```

See the [Reading and writing to SharePoint
Lists](https://elipousson.github.io/sharepointr/articles/sp-lists.md)
article for more information.

## Writing and uploading files to SharePoint

You can use
[`upload_sp_item()`](https://elipousson.github.io/sharepointr/reference/upload_sp_item.md)
to upload a local file to a SharePoint folder or document library (or
[`upload_sp_items()`](https://elipousson.github.io/sharepointr/reference/upload_sp_item.md)
to upload multiple files).

``` r
folder_url <- "https://bmore.sharepoint.com/:f:/r/sites/MayorsOffice-DataGovernance/Shared%20Documents/RStats?csf=1&web=1&e=S1XxVU"

upload_sp_item(
  file = system.file("gpkg/nc.gpkg", package = "sf"),
  dest = folder_url
)
#> Loading Microsoft Graph login for default tenant
#> 
ℹ Uploading file ' ]8;;file:///Users/elipousson/Projects/01_rpackages/sharepointr/vignettes/nc.gpkgnc.gpkg ]8;;' to SharePoint drive

✔ File upload complete [2.4s]                 
```

Using
[`read_sharepoint()`](https://elipousson.github.io/sharepointr/reference/read_sharepoint.md),
we can confirm that the file has been uploaded:

``` r
sp_drive <- get_sp_drive(folder_url)
#> Loading Microsoft Graph login for default tenant

nc <- read_sharepoint(
  "RStats/nc.gpkg",
  drive = sp_drive
)
#> 
ℹ Downloading SharePoint item to
#> ' ]8;;file:///var/folders/3f/50m42dx1333_dfqb5772j6_40000gn/T//RtmpIIrptB/nc.gpkg/var/folders/3f/50m42dx13 ]8;;…
#> 
✔ Downloading SharePoint item to ' ]8;;file:///var/folders/3f/50m42dx1333_dfqb5772j6_40000gn/T//RtmpIIrptB/nc.gpkg/var/folders/3f/50m42dx13 ]8;;…
#> 
ℹ Reading item with ` ]8;;x-r-help:sf::read_sfsf::read_sf ]8;;()`

✔ Reading item with ` ]8;;x-r-help:sf::read_sfsf::read_sf ]8;;()` [48ms]

plot(nc["AREA"])
```

![plot of chunk nc_plot](articles/nc_plot-1.png)

plot of chunk nc_plot

[`write_sharepoint()`](https://elipousson.github.io/sharepointr/reference/write_sharepoint.md)
extends
[`upload_sp_item()`](https://elipousson.github.io/sharepointr/reference/upload_sp_item.md)
by allowing you to pass an R object instead of a file path. Just as
[`read_sharepoint()`](https://elipousson.github.io/sharepointr/reference/read_sharepoint.md)
picks a function to read a file,
[`write_sharepoint()`](https://elipousson.github.io/sharepointr/reference/write_sharepoint.md)
picks a function to write the object based on its class
(e.g. [`sf::write_sf()`](https://r-spatial.github.io/sf/reference/st_write.html)
for sf objects,
[`readr::write_csv()`](https://readr.tidyverse.org/reference/write_delim.html)
or
[`openxlsx2::write_xlsx()`](https://janmarvin.github.io/openxlsx2/reference/write_xlsx.html)
for data frames, and
[`readr::write_rds()`](https://readr.tidyverse.org/reference/read_rds.html)
for other objects). Use `.f` to supply your own function.

``` r
write_sharepoint(
  mtcars,
  file = "mtcars.csv",
  dest = folder_url
)
#> Loading Microsoft Graph login for default tenant
#> 
ℹ Uploading file ' ]8;;file:///Users/elipousson/Projects/01_rpackages/sharepointr/vignettes/mtcars.csvmtcars.csv ]8;;' to SharePoint drive

✔ File upload complete [1.1s]                    
```

To wrap up this example, we need to remove the uploaded files from
SharePoint to keep a tidy shared file system.

[`delete_sp_item()`](https://elipousson.github.io/sharepointr/reference/delete_sp_item.md)
supports the option to use a shared item URL to select which file to
remove but, in this case, it is easier to set the `drive` argument along
with a relative filepath:

``` r

# Remove the file
delete_sp_item(
  file.path("RStats", "nc.gpkg"),
  drive = sp_drive,
  confirm = FALSE
)

delete_sp_item(
  file.path("RStats", "mtcars.csv"),
  drive = sp_drive,
  confirm = FALSE
)
```

## Listing files

If you do not know the URL or file path for an item on SharePoint, use
[`sp_dir_info()`](https://elipousson.github.io/sharepointr/reference/sp_dir_info.md)
to get a data frame of the items in a folder or
[`sp_dir_ls()`](https://elipousson.github.io/sharepointr/reference/sp_dir_info.md)
to get the item names.
[`sp_dir_info()`](https://elipousson.github.io/sharepointr/reference/sp_dir_info.md)
supports recursive listings but this can be slow depending on the number
of items in the SharePoint library.

This last example is not computed but it shows how to list and remove
empty nested directories left over from a failed manual import (using
[dplyr](https://dplyr.tidyverse.org) and
[stringr](https://stringr.tidyverse.org)):

``` r

# List directories
dir_info <- sp_dir_info("<SharePoint Folder URL>", type = "directory", recurse = TRUE)

# Filter to empty directories and sort by depth
empty_dirs <- dir_info |>
  dplyr::filter(size == 0) |>
  dplyr::mutate(
    path_depth = stringr::str_count(name, "/")
  ) |>
  dplyr::arrange(dplyr::desc(path_depth))

# Get drive
drive <- get_sp_drive(
  drive_name = "<SharePoint Document Library Name>",
  site_url = "<SharePoint Site URL>"
)

# Delete empty directories and skip confirmation
purrr::walk(
  empty_dirs[["id"]],
  \(x) {
    delete_sp_item(
      item_id = x,
      drive = drive,
      confirm = FALSE
    )
  }
)
```

Overall, the intent of this package is to maximize flexibility in how
and where you read and write files from SharePoint. Suggestions are
welcome so please share your own tips on working with the Microsoft
SharePoint API and the
[Microsoft365R](https://github.com/Azure/Microsoft365R) package.

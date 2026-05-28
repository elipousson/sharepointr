# Reading and writing items from SharePoint

``` r

library(sharepointr)
```

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
ℹ Downloading SharePoint item to
#> ' ]8;;file://C:\Users\ELI~1.POU\AppData\Local\Temp\Rtmp80Xill/Data
#> Classification Standard.docxC:\Users\ELI~1.POU\AppData\Loc ]8;;…


#> Error:
#> ! Path exists and overwrite is FALSE
#> 
✖ Downloading SharePoint item to ' ]8;;file://C:\Users\ELI~1.POU\AppData\Local\Temp\Rtmp80Xill/Data Classification Standard.docxC:\Users\ELI~1.POU\AppData\Loc ]8;;…
```

For files on SharePoint,
[`read_sharepoint()`](https://elipousson.github.io/sharepointr/reference/read_sharepoint.md)
extends
[`download_sp_item()`](https://elipousson.github.io/sharepointr/reference/download_sp_item.md)
by downloading the selected item to a temporary folder by default and,
depending on the file extension, tries to read the file using
[readr](https://readr.tidyverse.org),
[readxl](https://readxl.tidyverse.org),
[officer](https://ardata-fr.github.io/officeverse/), or
[sf](https://r-spatial.github.io/sf/).

``` r
docx <- read_sharepoint(docx_url)
#> Loading Microsoft Graph login for default tenant
#> 
ℹ Downloading SharePoint item to ' ]8;;file://C:\Users\ELI~1.POU\AppData\Local\Temp\Rtmp80Xill/Data Classification Standard.docxC:\Users\ELI~1.POU\AppData\Loc ]8;;…

✔ Downloading SharePoint item to ' ]8;;file://C:\Users\ELI~1.POU\AppData\Local\Temp\Rtmp80Xill/Data Classification Standard.docxC:\Users\ELI~1.POU\AppData\Loc ]8;;…


#> 
ℹ Reading item with ` ]8;;x-r-help:officer::read_docxofficer::read_docx ]8;;()`

✔ Reading item with ` ]8;;x-r-help:officer::read_docxofficer::read_docx ]8;;()` [125ms]



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

By default,
[`read_sharepoint()`](https://elipousson.github.io/sharepointr/reference/read_sharepoint.md)
checks the file extension the provided item and uses the appropriate
function from [readr](https://readr.tidyverse.org),
[officer](https://ardata-fr.github.io/officeverse/), or
[sf](https://r-spatial.github.io/sf/). Using the `.f` argument,
[`read_sharepoint()`](https://elipousson.github.io/sharepointr/reference/read_sharepoint.md)
also allows a user provided function to read the input:

``` r
wb_url <- "https://bmore.sharepoint.com/:x:/r/sites/MayorsOffice-DataGovernance/Shared%20Documents/Data%20Governance/Agency%20Naming%20Conventions.xlsx?d=w98ecba59d1f84c23862c6ad71e7f8695&csf=1&web=1&e=sSuZYo"

wb <- read_sharepoint(wb_url, .f = openxlsx2::wb_load)
#> Loading Microsoft Graph login for default tenant
#> 
ℹ Downloading SharePoint item to ' ]8;;file://C:\Users\ELI~1.POU\AppData\Local\Temp\Rtmp80Xill/Agency Naming Conventions.xlsxC:\Users\ELI~1.POU\AppData\Loc ]8;;…

✔ Downloading SharePoint item to ' ]8;;file://C:\Users\ELI~1.POU\AppData\Local\Temp\Rtmp80Xill/Agency Naming Conventions.xlsxC:\Users\ELI~1.POU\AppData\Loc ]8;;…


#> 
ℹ Reading item with ` ]8;;x-r-help:openxlsx2::wb_loadopenxlsx2::wb_load ]8;;()`

✔ Reading item with ` ]8;;x-r-help:openxlsx2::wb_loadopenxlsx2::wb_load ]8;;()` [222ms]



wb
#> A Workbook object.
#>  
#> Worksheets:
#>  Sheets: Sheet1 
#>  Write order: 1
```

As a convenience,
[`read_sharepoint()`](https://elipousson.github.io/sharepointr/reference/read_sharepoint.md)
also supports reading SharePoint lists as a wrapper for
[`get_sp_list_items()`](https://elipousson.github.io/sharepointr/reference/sp_list_item.md):

``` r

list_url <- "https://bmore.sharepoint.com/sites/MayorsOffice-DataGovernance/Lists/Data%20Governance%20Progress%20Tracker"

list_items <- read_sharepoint(list_url)
#> Loading Microsoft Graph login for default tenant
#> Error in `read_sharepoint()`:
#> ! Not Found (HTTP 404). Failed to complete operation.
#>   Message: The provided path does not exist, or does not
#>   represent a site.

list_items
#> Error:
#> ! object 'list_items' not found
```

See the [Reading and writing to SharePoint
Lists](https://elipousson.github.io/articles/sp-lists.md) article for
more information.

## Writing and uploading files to SharePoint

You can use
[`upload_sp_item()`](https://elipousson.github.io/sharepointr/reference/upload_sp_item.md)
to upload a local file to a SharePoint folder or document library.

``` r
folder_url <- "https://bmore.sharepoint.com/:f:/r/sites/MayorsOffice-DataGovernance/Shared%20Documents/RStats?csf=1&web=1&e=S1XxVU"

upload_sp_item(
  file = system.file("gpkg/nc.gpkg", package = "sf"),
  dest = folder_url
)
#> Loading Microsoft Graph login for default tenant
#> 
ℹ Uploading file ' ]8;;file://c:/Users/Eli.Pousson/OneDrive - City Of Baltimore/Projects/sharepointr/vignettes/nc.gpkgnc.gpkg ]8;;' to SharePoint drive

✔ File upload complete [1.6s]                 
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
#> ' ]8;;file://C:\Users\ELI~1.POU\AppData\Local\Temp\Rtmp80Xill/nc.gpkgC:\Users\ELI~1.POU\AppData\Loc ]8;;…


#> 
✔ Downloading SharePoint item to ' ]8;;file://C:\Users\ELI~1.POU\AppData\Local\Temp\Rtmp80Xill/nc.gpkgC:\Users\ELI~1.POU\AppData\Loc ]8;;…


#> 
ℹ Reading item with ` ]8;;x-r-help:sf::read_sfsf::read_sf ]8;;()`

✔ Reading item with ` ]8;;x-r-help:sf::read_sfsf::read_sf ]8;;()` [16ms]



plot(nc["AREA"])
```

![plot of chunk nc_plot](articles/nc_plot-1.png)

plot of chunk nc_plot

[`write_sharepoint()`](https://elipousson.github.io/sharepointr/reference/write_sharepoint.md)
extends
[`upload_sp_item()`](https://elipousson.github.io/sharepointr/reference/upload_sp_item.md)
by allowing you to pass an R object instead of a file path. Like
[`read_sharepoint()`](https://elipousson.github.io/sharepointr/reference/read_sharepoint.md)
tries to guess the appropriate input function,
[`write_sharepoint()`](https://elipousson.github.io/sharepointr/reference/write_sharepoint.md)
tries to guess the appropriate output function based on the object
class.

``` r
write_sharepoint(
  mtcars,
  file = "mtcars.csv",
  dest = folder_url
)
#> Loading Microsoft Graph login for default tenant
#> 
ℹ Uploading file ' ]8;;file://c:/Users/Eli.Pousson/OneDrive - City Of Baltimore/Projects/sharepointr/vignettes/mtcars.csvmtcars.csv ]8;;' to SharePoint drive

✔ File upload complete [1.4s]                    
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

If you do not know the URL or file path for an item on SharePoint you
can also use the directory info functions to list items typically using
the
[`sp_dir_info()`](https://elipousson.github.io/sharepointr/reference/sp_dir_info.md)
function. This function supports recursive listings but this can be slow
depending on the number of items in the SharePoint library.

This last example is not computed but it shows how to list and remove
empty nested directories left over from a failed manual import:

``` r

# List directories
dir_info <- sp_dir_info("<SharePoint Folder URL>", type = "directory", recurse = TRUE)

# Filter to empty directories and sort by depth
empty_dirs <- dir_info |>
  filter(size == 0) |>
  mutate(
    path_depth = str_count(name, "/")
  ) |>
  arrange(desc(path_depth))

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

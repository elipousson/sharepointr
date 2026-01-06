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
#> Error: Path exists and overwrite is FALSE
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

docx
#> rdocx document with 62 element(s)
#> 
#> * styles:
#>                 Normal              heading 1              heading 2 
#>            "paragraph"            "paragraph"            "paragraph" 
#> Default Paragraph Font           Normal Table                No List 
#>            "character"                "table"            "numbering" 
#>         Heading 1 Char             Table Grid         List Paragraph 
#>            "character"                "table"            "paragraph" 
#>         Heading 2 Char                  Title             Title Char 
#>            "character"            "paragraph"            "character" 
#>           Normal (Web)                 header            Header Char 
#>            "paragraph"            "paragraph"            "character" 
#>                 footer            Footer Char          markedcontent 
#>            "paragraph"            "character"            "character" 
#>            TOC Heading                  toc 1                  toc 2 
#>            "paragraph"            "paragraph"            "paragraph" 
#>              Hyperlink                  toc 3                  toc 4 
#>            "character"            "paragraph"            "paragraph" 
#>                  toc 5                  toc 6                  toc 7 
#>            "paragraph"            "paragraph"            "paragraph" 
#>                  toc 8                  toc 9     Unresolved Mention 
#>            "paragraph"            "paragraph"            "character" 
#>      FollowedHyperlink               Revision    Unresolved Mention1 
#>            "character"            "paragraph"            "character" 
#>   annotation reference        annotation text      Comment Text Char 
#>            "character"            "paragraph"            "character" 
#>     annotation subject   Comment Subject Char           Balloon Text 
#>            "paragraph"            "character"            "paragraph" 
#>      Balloon Text Char          footnote text     Footnote Text Char 
#>            "character"            "paragraph"            "character" 
#>     footnote reference 
#>            "character" 
#> 
#> * Content at cursor location:
#>   level num_id text style_name content_type
#> 1    NA     NA       heading 1    paragraph
```

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
empty nested directories left over from a failed manual import;

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
walk(
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

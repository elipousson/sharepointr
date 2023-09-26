
<!-- README.md is generated from README.Rmd. Please edit that file -->

# sharepointr

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![License:
MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
<!-- badges: end -->

The goal of SharePointR is to make it easier to read, write, and work
with files stored in SharePoint by extending the `{Microsoft365R}`
package.

## Installation

You can install the development version of SharePointR like so:

``` r
# pak::pkg_install("elipousson/sharepointr")
```

## Requirements

To use this package (or `{Microsoft365}`) you must:

- Have a work or school account with access to [Microsoft
  SharePoint](https://www.microsoft.com/en-us/microsoft-365/sharepoint/collaboration)
- Have enabled permissions for the default `{Microsoft365}` app ID

See the `{Microsoft365}` [documentation on app registration for more
information](https://github.com/Azure/Microsoft365R/blob/master/inst/app_registration.md).

## Usage

`{Microsoft365}` uses S6 methods for nearly everything which may be
difficult for users (me included) who are less familiar with this
interface.

The `{sharepointr}` package seeks to ease this challenge by wrapping the
`{Microsoft365}` methods and adding support for the specification of
SharePoint sites, drives, and items using SharePoint URLs instead of
item or drive ID values.

``` r
library(sharepointr)
```

The most useful functions for most users may be `read_sharepoint()` and
`write_sharepoint()`.

`read_sharepoint()` downloads a SharePoint file to a temporary folder
and then, based on the file extension, reads it into your environment
using an appropriate function and package (e.g. using
`officer::read_docx()` for Microsoft Word files or `sf::read_sf()` for
common spatial data files):

``` r
docx_shared_url <- "https://bmore.sharepoint.com/:w:/r/sites/MayorsOffice-DataGovernance/Shared%20Documents/General/Baltimore%20Data%20Academy/Baltimore%20Data%20Academy%20Announcement%20Content.docx?d=w0a50d3cd74ce4a8da6d82596037f0148&csf=1&web=1&e=cBURo2"

read_sharepoint(docx_shared_url)
#> ℹ Getting item from SharePoint
#> Loading Microsoft Graph login for default tenant
#> ✔ Getting item from SharePoint [623ms]
#> 
#> ℹ Downloading SharePoint item to '/var/folders/3f/50m42dx1333_dfqb5772j6_40000g…
#> ✔ Downloading SharePoint item to '/var/folders/3f/50m42dx1333_dfqb5772j6_40000g…
#> 
#> ℹ Reading item with `officer::read_docx()`
#> ✔ Reading item with `officer::read_docx()` [29ms]
#> 
#> rdocx document with 19 element(s)
#> 
#> * styles:
#>                 Normal Default Paragraph Font           Normal Table 
#>            "paragraph"            "character"                "table" 
#>                No List         List Paragraph   annotation reference 
#>            "numbering"            "paragraph"            "character" 
#>        annotation text      Comment Text Char     annotation subject 
#>            "paragraph"            "character"            "paragraph" 
#>   Comment Subject Char              Hyperlink     Unresolved Mention 
#>            "character"            "character"            "character" 
#> 
#> * Content at cursor location:
#>   level num_id
#> 1    NA     NA
#>                                                                                                                                                  text
#> 1 If you have questions or feedback about the program, contact Chief Data Officer Justin Elszasz at justin.elszasz@baltimorecity.gov. Happy learning!
#>   style_name content_type
#> 1         NA    paragraph
```

`write_sharepoint()` saves an R object to local files and then uses
`upload_sp_item()` to uploads the file to SharePoint. I plan on adding
features to allow the custom mapping of file extensions and object
classes to specific functions or packages and adding more thorough
documentation.

Both functions rely on a set of helper functions: `get_sp_site()`,
`get_sp_drive()`, and `get_sp_item()`, that can parse a URL to determine
the SharePoint site URL, drive name, and file path based on the URL.

`get_sp_site()` is a minimal wrapper for
`Microsoft365R::get_sharepoint_site()`:

``` r
site_url <- "https://bmore.sharepoint.com/sites/MayorsOffice-DataGovernance"

get_sp_site(site_url = site_url)
#> Loading Microsoft Graph login for default tenant
#> <Sharepoint site 'Citywide Data Network'>
#>   directory id: bmore.sharepoint.com,1da01cb7-76c7-4487-b398-ec60dff8f52d,7abe409a-2aeb-4eb8-8dc3-8fe9106907af 
#>   web link: https://bmore.sharepoint.com/sites/MayorsOffice-DataGovernance 
#>   description: If you work with or are interested in data, feel free to join! 
#> ---
#>   Methods:
#>     delete, do_operation, get_drive, get_group, get_list,
#>     get_list_pager, get_lists, list_drives, list_subsites,
#>     sync_fields, update
```

`get_sp_drive()` returns a `ms_drive` object and `get_sp_item()` returns
a `ms_drive_item` object but support most shared file and folder URLs
(support for SharePoint List URLs is currently incomplete):

``` r
get_sp_drive(docx_shared_url)
#> Loading Microsoft Graph login for default tenant
#> <Document library 'Documents'>
#>   directory id: b!txygHcd2h0SzmOxg3_j1LZpAvnrrKrhOjcOP6RBpB6-8Kta613N3QJlbvrVKyTwO 
#>   web link: https://bmore.sharepoint.com/sites/MayorsOffice-DataGovernance/Shared%20Documents 
#>   description:  
#> ---
#>   Methods:
#>     copy_item, create_folder, create_share_link, delete,
#>     delete_item, do_operation, download_file, download_folder,
#>     get_item, get_item_properties, get_list_pager, list_files,
#>     list_items, list_shared_files, list_shared_items,
#>     load_dataframe, load_rdata, load_rds, move_item, open_item,
#>     save_dataframe, save_rdata, save_rds, set_item_properties,
#>     sync_fields, update, upload_file, upload_folder

get_sp_item(docx_shared_url)
#> Loading Microsoft Graph login for default tenant
#> <Drive item 'Baltimore Data Academy Announcement Content.docx'>
#>   directory id: 017P4HV6ON2NIAVTTURVFKNWBFSYBX6AKI 
#>   web link: https://bmore.sharepoint.com/sites/MayorsOffice-DataGovernance/_layouts/15/Doc.aspx?sourcedoc=%7B0A50D3CD-74CE-4A8D-A6D8-2596037F0148%7D&file=Baltimore%20Data%20Academy%20Announcement%20Content.docx&action=default&mobileredirect=true 
#>   type: file 
#> ---
#>   Methods:
#>     copy, create_folder, create_share_link, delete,
#>     do_operation, download, get_item, get_list_pager,
#>     get_parent_folder, get_path, is_folder, list_files,
#>     list_items, load_dataframe, load_rdata, load_rds, move,
#>     open, save_dataframe, save_rdata, save_rds, sync_fields,
#>     update, upload
```

`download_sp_item()` is a wrapper for `get_sp_item()` that adds support
for downloading copies of your SharePoint files:

``` r
withr::with_tempdir({
  docx_dest <- download_sp_item(docx_shared_url)
  
  file.exists(docx_dest)
})
#> ℹ Getting item from SharePoint
#> Loading Microsoft Graph login for default tenant
#> ✔ Getting item from SharePoint [430ms]
#> 
#> ℹ Downloading SharePoint item to 'Baltimore Data Academy Announcement Content.d…
#> ✔ Downloading SharePoint item to 'Baltimore Data Academy Announcement Content.d…
#> 
#> [1] TRUE
```

The package also includes a handful of helper functions like
`sp_dir_create()` and `sp_dir_info()`:

``` r
sp_dir_info("https://bmore.sharepoint.com/:w:/r/sites/MayorsOffice-DataGovernance/Shared%20Documents/General/Baltimore%20Data%20Academy")
#> Loading Microsoft Graph login for default tenant
#>                                                                                                 name
#> 1                                                                                              Logos
#> 2                                                 BALT 02 Interpreting Data - Student Coursebook.pdf
#> 3                                            BALT 03_Leading with Data_Workday Lesson 1_03292023.pdf
#> 4                                             BALT 04_Data Stewardship_Workday Lesson 1_03292023.pdf
#> 5  BALT 05_Measuring Government Performance_Course Access Instructions_Workday Lesson 1_02282023.pdf
#> 6                                                   Baltimore Data Academy Announcement Content.docx
#> 7                                        Baltimore Data Academy New Course Announcement 7.11.23.docx
#> 8                                                                           Curriculum One Pager.pdf
#> 9                                                                                      Document.docx
#> 10                                                        Foundations of Data Literacy_2023 [43].pdf
#> 11                                       Interpreting Data with Greater Accuracy and Insight[97].pdf
#> 12                                                              Last SR by Agency as of 7.11.23.xlsx
#>       size isdir                                 id
#> 1  3422970  TRUE 017P4HV6I3IGKTFCO2FZD3FXPCGUPJSO6G
#> 2   720266 FALSE 017P4HV6KITC7MJJJESFD35BIDU5DR4BSL
#> 3   398246 FALSE 017P4HV6N2LBZHX6ERCBCIQRJIXGTZMYCK
#> 4   399017 FALSE 017P4HV6ICFKFITU4WC5CYAFJUTZAMHP7K
#> 5   400728 FALSE 017P4HV6MQCBPQQD6VUVCJWMWAKTIBZNYQ
#> 6    76665 FALSE 017P4HV6ON2NIAVTTURVFKNWBFSYBX6AKI
#> 7    55243 FALSE 017P4HV6PKOSFTLSMOAJDK3OGKFUVCIICU
#> 8    90575 FALSE 017P4HV6OKNLH7UWTQJBEZXWNFXBGBC6OC
#> 9    49677 FALSE 017P4HV6L5XTQ7IOMVYBGKSYMSOYDXMMPZ
#> 10  549730 FALSE 017P4HV6KALORFIRC2IBB3RN52WE4V7QGU
#> 11  633034 FALSE 017P4HV6NWPAN6PTWC3FEJB3KRR2WDWXFM
#> 12   16117 FALSE 017P4HV6K2WP2LBTN6PFGLVY4PIWOY7IAR
```

## Related packages

There are two similar packages available:

- [sharrpoint](https://gitlab.com/tolmay/sharrpoint): An R package to
  interact with Sharepoint API (files & lists).
- [sharepointr](https://github.com/LukasK13/sharepointr):A R package for
  reading from and writing to SharePoint lists.

I may rename this package to avoid the name conflict with the existing
sharepointr package—I didn’t find it until after I set up the
repository. However, it has a more limited feature set and may be no
longer under development.


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

### Reading and writing objects to and from SharePoint

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
#> ✔ Getting item from SharePoint [796ms]
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
`upload_sp_item()` to uploads the file to SharePoint.

I plan on adding features to allow the custom mapping of file extensions
and object classes to specific functions or packages and adding more
thorough documentation. Feel free to submit an issue or make a pull
request if you have ideas of how to do this.

### Working with SharePoint items, lists, and plans

This package currently support three main categories of SharePoint
objects:

- **Items and item properties** including:

  - **Directories**

  - **Files**

- **Lists and list items**

- **Plans and tasks**

Typically these functions return a `ms_object` object, a list of
`ms_object` objects, or a data frame. In some cases, the data frame is
based on the object properties and includes a list column where the
`ms_object` is stored.

For example, `get_sp_item()` returns a `ms_drive_item` object and
supports parsing for shared file and folder URLs:

``` r
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

Set `as_data_frame = TRUE` to return a data frame instead of a
`ms_drive_item` object:

``` r
get_sp_item(docx_shared_url, as_data_frame = TRUE)
#> Loading Microsoft Graph login for default tenant
#>                                                                                                                           @odata.context
#> 1 https://graph.microsoft.com/beta/$metadata#drives('b%21txygHcd2h0SzmOxg3_j1LZpAvnrrKrhOjcOP6RBpB6-8Kta613N3QJlbvrVKyTwO')/root/$entity
#>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      @microsoft.graph.downloadUrl
#> 1 https://bmore.sharepoint.com/sites/MayorsOffice-DataGovernance/_layouts/15/download.aspx?UniqueId=0a50d3cd-74ce-4a8d-a6d8-2596037f0148&Translate=false&tempauth=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJhdWQiOiIwMDAwMDAwMy0wMDAwLTBmZjEtY2UwMC0wMDAwMDAwMDAwMDAvYm1vcmUuc2hhcmVwb2ludC5jb21AMzEyY2IxMjYtYzZhZS00ZmMyLTgwMGQtMzE4ZTY3OWNlNmM3IiwiaXNzIjoiMDAwMDAwMDMtMDAwMC0wZmYxLWNlMDAtMDAwMDAwMDAwMDAwIiwibmJmIjoiMTY5ODg1MzQ2MiIsImV4cCI6IjE2OTg4NTcwNjIiLCJlbmRwb2ludHVybCI6ImVWS1o5aHllbHVsNU9PdzR6OWQ1U01sOVBkZXpXTjNOU3NscWxGM3V2ME09IiwiZW5kcG9pbnR1cmxMZW5ndGgiOiIxNTAiLCJpc2xvb3BiYWNrIjoiVHJ1ZSIsImNpZCI6IkZmdEFuRUFFOEUyZmx2dXpvQjFPaHc9PSIsInZlciI6Imhhc2hlZHByb29mdG9rZW4iLCJzaXRlaWQiOiJNV1JoTURGallqY3ROelpqTnkwME5EZzNMV0l6T1RndFpXTTJNR1JtWmpobU5USmsiLCJhcHBfZGlzcGxheW5hbWUiOiJBenVyZVIvTWljcm9zb2Z0MzY1UiIsImdpdmVuX25hbWUiOiJFbGkiLCJmYW1pbHlfbmFtZSI6IlBvdXNzb24iLCJhcHBpZCI6ImQ0NGEwNWQ1LWM2YTUtNGJiYi04MmQyLTQ0MzEyMzcyMjM4MCIsInRpZCI6IjMxMmNiMTI2LWM2YWUtNGZjMi04MDBkLTMxOGU2NzljZTZjNyIsInVwbiI6ImVsaS5wb3Vzc29uQGJhbHRpbW9yZWNpdHkuZ292IiwicHVpZCI6IjEwMDMyMDAxRkQ3Q0UxMjQiLCJjYWNoZWtleSI6IjBoLmZ8bWVtYmVyc2hpcHwxMDAzMjAwMWZkN2NlMTI0QGxpdmUuY29tIiwic2NwIjoiZ3JvdXAud3JpdGUgYWxsc2l0ZXMubWFuYWdlIGFsbHNpdGVzLndyaXRlIiwidHQiOiIyIiwiaXBhZGRyIjoiNDAuMTI2LjIzLjk4In0.dZpR8dRYrGiPxTsYgoIMqEOjwKmPByJzlGb9FWmzoGc&ApiVersion=2.0
#>        createdDateTime                                        eTag
#> 1 2023-01-13T16:42:07Z "{0A50D3CD-74CE-4A8D-A6D8-2596037F0148},56"
#>                                   id lastModifiedDateTime
#> 1 017P4HV6ON2NIAVTTURVFKNWBFSYBX6AKI 2023-01-26T18:17:57Z
#>                                               name
#> 1 Baltimore Data Academy Announcement Content.docx
#>                                                                                                                                                                                                                                      webUrl
#> 1 https://bmore.sharepoint.com/sites/MayorsOffice-DataGovernance/_layouts/15/Doc.aspx?sourcedoc=%7B0A50D3CD-74CE-4A8D-A6D8-2596037F0148%7D&file=Baltimore%20Data%20Academy%20Announcement%20Content.docx&action=default&mobileredirect=true
#>                                             cTag  size
#> 1 "c:{0A50D3CD-74CE-4A8D-A6D8-2596037F0148},140" 76665
#>                                                                                 createdBy
#> 1 Justin.Elszasz@baltimorecity.gov, a43c19f9-9a13-403d-9234-0c13f4e84b1c, Elszasz, Justin
#>                                                                                       lastModifiedBy
#> 1 Michael.Gottlieb@baltimorecity.gov, a2dedf36-3fce-4998-92f5-9350e749769f, Gottlieb, Michael (BCIT)
#>   shared
#> 1  users
#>                                                                                                                                                                                                                                                                                          parentReference
#> 1 documentLibrary, b!txygHcd2h0SzmOxg3_j1LZpAvnrrKrhOjcOP6RBpB6-8Kta613N3QJlbvrVKyTwO, 017P4HV6NGOMGBBVI5GBBZU5BFDTPDKJ7W, Baltimore Data Academy, /drives/b!txygHcd2h0SzmOxg3_j1LZpAvnrrKrhOjcOP6RBpB6-8Kta613N3QJlbvrVKyTwO/root:/General/Baltimore Data Academy, 1da01cb7-76c7-4487-b398-ec60dff8f52d
#>                                                                                                    file
#> 1 application/vnd.openxmlformats-officedocument.wordprocessingml.document, CftrnHpBa4HAhtv+a3TALjSSvS0=
#>                               fileSystemInfo                    ms_item
#> 1 2023-01-13T16:42:07Z, 2023-01-26T18:17:57Z <environment: 0x13b98d510>
```

These basic functions to “get” objects are extended by functions like
`download_sp_item()` that adds support for downloading copies of your
SharePoint files (this is the function that powers `read_sharepoint()`):

``` r
withr::with_tempdir({
  docx_dest <- download_sp_item(docx_shared_url)

  file.exists(docx_dest)
})
#> ℹ Getting item from SharePoint
#> Loading Microsoft Graph login for default tenant
#> ✔ Getting item from SharePoint [376ms]
#> 
#> ℹ Downloading SharePoint item to 'Baltimore Data Academy Announcement Content.d…
#> ✔ Downloading SharePoint item to 'Baltimore Data Academy Announcement Content.d…
#> 
#> [1] TRUE
```

Some of the original `{Microsoft365R}` S6 object methods already return
a data frame by default such as `sp_dir_info()`:

``` r
sp_dir_info("https://bmore.sharepoint.com/:w:/r/sites/MayorsOffice-DataGovernance/Shared%20Documents/General/Baltimore%20Data%20Academy")
#> Loading Microsoft Graph login for default tenant
#>                                                                                                                                name
#> 1                                                                                              General/Baltimore Data Academy/Logos
#> 2                                                 General/Baltimore Data Academy/BALT 02 Interpreting Data - Student Coursebook.pdf
#> 3                                            General/Baltimore Data Academy/BALT 03_Leading with Data_Workday Lesson 1_03292023.pdf
#> 4                                             General/Baltimore Data Academy/BALT 04_Data Stewardship_Workday Lesson 1_03292023.pdf
#> 5  General/Baltimore Data Academy/BALT 05_Measuring Government Performance_Course Access Instructions_Workday Lesson 1_02282023.pdf
#> 6                                                   General/Baltimore Data Academy/Baltimore Data Academy Announcement Content.docx
#> 7                                        General/Baltimore Data Academy/Baltimore Data Academy New Course Announcement 7.11.23.docx
#> 8                                                                           General/Baltimore Data Academy/Curriculum One Pager.pdf
#> 9                                                                                      General/Baltimore Data Academy/Document.docx
#> 10                                                        General/Baltimore Data Academy/Foundations of Data Literacy_2023 [43].pdf
#> 11                                       General/Baltimore Data Academy/Interpreting Data with Greater Accuracy and Insight[97].pdf
#> 12                                                              General/Baltimore Data Academy/Last SR by Agency as of 7.11.23.xlsx
#>       size isdir                                 id      type
#> 1    3.26M  TRUE 017P4HV6I3IGKTFCO2FZD3FXPCGUPJSO6G directory
#> 2  703.38K FALSE 017P4HV6KITC7MJJJESFD35BIDU5DR4BSL      file
#> 3  388.91K FALSE 017P4HV6N2LBZHX6ERCBCIQRJIXGTZMYCK      file
#> 4  389.67K FALSE 017P4HV6ICFKFITU4WC5CYAFJUTZAMHP7K      file
#> 5  391.34K FALSE 017P4HV6MQCBPQQD6VUVCJWMWAKTIBZNYQ      file
#> 6   74.87K FALSE 017P4HV6ON2NIAVTTURVFKNWBFSYBX6AKI      file
#> 7   53.95K FALSE 017P4HV6PKOSFTLSMOAJDK3OGKFUVCIICU      file
#> 8   88.45K FALSE 017P4HV6OKNLH7UWTQJBEZXWNFXBGBC6OC      file
#> 9   48.51K FALSE 017P4HV6L5XTQ7IOMVYBGKSYMSOYDXMMPZ      file
#> 10 536.85K FALSE 017P4HV6KALORFIRC2IBB3RN52WE4V7QGU      file
#> 11  618.2K FALSE 017P4HV6NWPAN6PTWC3FEJB3KRR2WDWXFM      file
#> 12  15.74K FALSE 017P4HV6K2WP2LBTN6PFGLVY4PIWOY7IAR      file
```

Others use the `as_data_frame` parameter to convert a list into a data
frame as a convenient alternative.

### Helpers for SharePoint sites and drives

Most functions in the package rely on a pair of helper functions:
`get_sp_site()`, `get_sp_drive()`, and `get_sp_item()`, that can parse a
URL to determine the SharePoint site URL, drive name, and file path
based on the URL.

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

`get_sp_drive()` returns a `ms_drive` object but required a SharePoint
URL that includes the name of the drive (otherwise it returns the drive
named in the “sharepointr.default_drive_name” option):

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
```

## Related packages

There are a few similar packages available:

- [sharrpoint](https://gitlab.com/tolmay/sharrpoint): An R package to
  interact with Sharepoint API (files & lists).
- [sharepointr](https://github.com/LukasK13/sharepointr): A R package
  for reading from and writing to SharePoint lists.
- [msgraphr](https://github.com/davidski/msgraphr): A minimal R wrapper
  of the SharePoint Online (Office 365) APIs (last updated 3 years ago).

I know this package name conflicts with the existing sharepointr
package. Unfortunately, I didn’t notice find it until after I set up the
repository. However, given that it appears that the sharepointr package
may be no longer under development, I plan stick with the current name
for the time being.

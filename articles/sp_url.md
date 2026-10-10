# Using SharePoint URLs to work with items and lists

``` r

library(sharepointr)
```

Most sharepointr functions accept a SharePoint URL in place of a site,
drive, list, or item object. This makes it possible to use a link copied
from SharePoint (using the “Copy link” option described in Microsoft’s
guide to [sharing SharePoint files or
folders](https://support.microsoft.com/en-us/office/share-sharepoint-files-or-folders-1fe37332-0f9a-4719-970e-d2578da4941c))
or from your browser address bar.

This is a folder URL. It is a shared link where people with existing
access can use the link.

``` r

dir_url <- "https://bmore.sharepoint.com/:f:/r/sites/DOP-CPR/Shared%20Documents/INSPIRE%20Program%20%F0%9F%8F%AB%F0%9F%9A%B8%F0%9F%8C%B3?csf=1&web=1&e=W5dbYz"
```

SharePoint uses many types of URLs and they don’t all work with this
package yet. Use
[`sp_url_parse()`](https://elipousson.github.io/sharepointr/reference/sp_url_parse.md)
to see how a URL is parsed into smaller parts:

``` r

sp_url_parse(dir_url)
#> $base_url
#> [1] "https://bmore.sharepoint.com"
#> 
#> $tenant
#> [1] "bmore"
#> 
#> $path
#> [1] "/:f:/r/sites/DOP-CPR/Shared Documents/INSPIRE Program 🏫🚸🌳"
#> 
#> $url_type
#> [1] "f"
#> 
#> $permissions
#> [1] "r"
#> 
#> $site_name
#> [1] "DOP-CPR"
#> 
#> $file_path
#> [1] "/INSPIRE Program 🏫🚸🌳"
#> 
#> $drive_name
#> [1] "Documents"
#> 
#> $item_id
#> NULL
#> 
#> $csf
#> [1] "1"
#> 
#> $web
#> [1] "1"
#> 
#> $e
#> [1] "W5dbYz"
#> 
#> $site_url
#> [1] "https://bmore.sharepoint.com/sites/DOP-CPR"
```

These parts are used to get the site, drive (document library), list, or
item from SharePoint:

``` r

get_sp_site(dir_url)
#> Loading Microsoft Graph login for default tenant
#> <Sharepoint site 'DOP-CPR'>
#>   directory id: bmore.sharepoint.com,67aec41a-38f7-471f-8409-a71c3bece3a0,f506465a-e433-42ae-a52b-cb7130b77d59 
#>   web link: https://bmore.sharepoint.com/sites/DOP-CPR 
#>   description:   
#> ---
#>   Methods:
#>     delete, do_operation, get_drive, get_group,
#>     get_list, get_list_pager, get_lists,
#>     list_drives, list_subsites, sync_fields,
#>     update

get_sp_drive(dir_url)
#> Loading Microsoft Graph login for default tenant
#> <Document library 'Documents'>
#>   directory id: b!GsSuZ_c4H0eECaccO-zjoFpGBvUz5K5CpSvLcTC3fVkj4DsIzWYXTaCOSKIsJAdy 
#>   web link: https://bmore.sharepoint.com/sites/DOP-CPR/Shared%20Documents 
#>   description:  
#> ---
#>   Methods:
#>     copy_item, create_folder, create_share_link,
#>     delete, delete_item, do_operation,
#>     download_file, download_folder, get_item,
#>     get_item_properties, get_list_pager,
#>     list_files, list_items, list_shared_files,
#>     list_shared_items, load_dataframe,
#>     load_rdata, load_rds, move_item, open_item,
#>     save_dataframe, save_rdata, save_rds,
#>     set_item_properties, sync_fields, update,
#>     upload_file, upload_folder
```

With a directory URL, you can get a list of files:

``` r

dir_info <- sp_dir_info(dir_url)
#> Loading Microsoft Graph login for default tenant

dir_info
#>                                                                                  name
#> 1                                INSPIRE Program 🏫🚸🌳/INSPIRE Plan Histories (CHAP)
#> 2                                     INSPIRE Program 🏫🚸🌳/INSPIRE Plans Adopted ✅
#> 3                                  INSPIRE Program 🏫🚸🌳/INSPIRE Plans In Progress ✏️
#> 4                                        INSPIRE Program 🏫🚸🌳/INSPIRE Program Admin
#> 5                                                       INSPIRE Program 🏫🚸🌳/Photos
#> 6                                                   INSPIRE Program 🏫🚸🌳/References
#> 7                               INSPIRE Program 🏫🚸🌳/_2021_Planner+School List.xlsx
#> 8  INSPIRE Program 🏫🚸🌳/2023-05-17-dhcd-code-enforcement_recommendation-review.docx
#> 9          INSPIRE Program 🏫🚸🌳/ACCE-and-Indepedence_2017-Recommendation-Table.xlsx
#> 10                                           INSPIRE Program 🏫🚸🌳/Budget scrap.xlsx
#> 11            INSPIRE Program 🏫🚸🌳/Dorothy-Height-ES_2017-Recommendation-Table.xlsx
#> 12                              INSPIRE Program 🏫🚸🌳/Historical Assessment Doc.docx
#> 13                  INSPIRE Program 🏫🚸🌳/INSPIRE Community Engagement Notebook.xlsx
#> 14                INSPIRE Program 🏫🚸🌳/INSPIRE Comprehensive Plan Contribution.docx
#> 15                               INSPIRE Program 🏫🚸🌳/INSPIRE DOP Website Copy.docx
#> 16                            INSPIRE Program 🏫🚸🌳/INSPIRE Master Contact List.xlsx
#> 17                              INSPIRE Program 🏫🚸🌳/INSPIRE Plan Folder Index.xlsx
#> 18                         INSPIRE Program 🏫🚸🌳/INSPIRE Plan Timelines 2021_08.docx
#> 19          INSPIRE Program 🏫🚸🌳/INSPIRE Planning and Program Management Guide.docx
#> 20                                             INSPIRE Program 🏫🚸🌳/INSPIRE Program
#> 21                               INSPIRE Program 🏫🚸🌳/INSPIRE Program Calendar.xlsx
#> 22                                INSPIRE Program 🏫🚸🌳/INSPIRE Rec tables 2023.xlsx
#> 23                                 INSPIRE Program 🏫🚸🌳/INSPIRE Workflow DRAFT.docx
#> 24              INSPIRE Program 🏫🚸🌳/inspire-area-plan-document-template Folder.zip
#> 25              INSPIRE Program 🏫🚸🌳/INSPIRE-Plan-Recommendation-Table-Tracker.xlsx
#> 26           INSPIRE Program 🏫🚸🌳/Middle Neighborhoods INSPIRE Assessment Plan.docx
#> 27           INSPIRE Program 🏫🚸🌳/Patterson-Building_2018-Recommendation-Table.xlsx
#> 28                         INSPIRE Program 🏫🚸🌳/Preparing for a Community Walk.docx
#> 29                                          INSPIRE Program 🏫🚸🌳/RampPrintouts.xlsx
#> 30                  INSPIRE Program 🏫🚸🌳/Stakeholder Outreach Spreadsheet 2025.xlsx
#> 31                                    INSPIRE Program 🏫🚸🌳/Test Planner Import.xlsx
#> 32                                    INSPIRE Program 🏫🚸🌳/USP Interview notes.docx
#>       size isdir                                 id      type
#> 1  427.88M  TRUE 01EK4O46W2BVSN34MWIJCZO45SX2RIMVRR directory
#> 2    6.64G  TRUE 01EK4O46TWHR6QA77FQRAK3TFSP5Z5WGUV directory
#> 3    2.81G  TRUE 01EK4O46XRFXKSJ4MSCVHIXD3E2JCCGZ4Y directory
#> 4    1.07G  TRUE 01EK4O46TNZAXB5BWALZEJF4Y5NCBZPPKB directory
#> 5  773.07M  TRUE 01EK4O46XP2EGVNL5XUNC2GGCWCXQOCBR6 directory
#> 6  150.88M  TRUE 01EK4O46S5WYIRFXP42ZBZ3XJBCAX5WRD2 directory
#> 7   43.01K FALSE 01EK4O46S42QAM2K6FSBAZPBQOS4VBT3YI      file
#> 8   29.88K FALSE 01EK4O46VKEMUM7LD3YNHJ5IA67DXT6K42      file
#> 9   62.83K FALSE 01EK4O46UBUWXFJVO64VG3MDJRBX5RGVJ6      file
#> 10   15.3K FALSE 01EK4O46XFZKGJN3S4AVBYMIEB5OQTG3K7      file
#> 11   71.9K FALSE 01EK4O46USJO2JCKOYU5BZX5M3FM57EBY6      file
#> 12  20.97K FALSE 01EK4O46RLN3E7BWYST5GIKRJAVB7VDI3N      file
#> 13   23.4K FALSE 01EK4O46TFJABPEPMTS5CINCRI7LRAN554      file
#> 14  29.06K FALSE 01EK4O46UOLVTZZANSPJHZ3ICJBFFGO7P5      file
#> 15  13.32M FALSE 01EK4O46VQJZ4S7SZ2EFB3N267A4U67XVG      file
#> 16  29.34K FALSE 01EK4O46VTPF5MRFPSYZHYQ2YJN5C3A4PP      file
#> 17  20.18K FALSE 01EK4O46Q3CZ4DDVT6XNFJA3T2XFDJESHZ      file
#> 18  45.69K FALSE 01EK4O46RKC2EBRPKIVRC34NZGU2XDUGXF      file
#> 19 103.41K FALSE 01EK4O46RYX55LJ6VAAZFINIOB2XF2UXLF      file
#> 20   2.03M  TRUE 01EK4O46XVR7PESI3HXZCJF2UDW6YZ53DD directory
#> 21  23.14K FALSE 01EK4O46QCKIPTO4QQG5AY3V422XIJYQHZ      file
#> 22  26.21K FALSE 01EK4O46S6CMHTD2335VFZS6VVEDMWRHJN      file
#> 23   24.2K FALSE 01EK4O46UK2YTRIADBPBEIKM5ODDWX76JO      file
#> 24   3.44M FALSE 01EK4O46WOYDIUE5PAFZA3RNIIEFOTXY36      file
#> 25  23.13K FALSE 01EK4O46X6F7CWA6MVINDLOP2FBXQOCB4F      file
#> 26  25.49K FALSE 01EK4O46TS3YMEYF4KTBF34FWZQ5ER7SF7      file
#> 27  52.58K FALSE 01EK4O46VKH4KFD6OVYFFKRO2JL5NPN6WC      file
#> 28  22.73K FALSE 01EK4O46W4HZJORDO57VBL6YIFK3VTDZST      file
#> 29  63.11K FALSE 01EK4O46UEGOBAINNSYVFI4WTHYS3CIEXD      file
#> 30 253.32K FALSE 01EK4O46WGCAEB4XIC5FCYLVWTYXIULWDY      file
#> 31  15.17K FALSE 01EK4O46XDUXMFXPTV4NAICXGZ2YGAYAJU      file
#> 32   21.4K FALSE 01EK4O46S7HDHRZEKDC5BK46RX76SMB2BJ      file
```

You can use the same URL to get a character vector of file names:

``` r

sp_dir_ls(dir_url)
#> Loading Microsoft Graph login for default tenant
#>  [1] "INSPIRE Plan Histories (CHAP)"                              
#>  [2] "INSPIRE Plans Adopted ✅"                                   
#>  [3] "INSPIRE Plans In Progress ✏️"                                
#>  [4] "INSPIRE Program Admin"                                      
#>  [5] "Photos"                                                     
#>  [6] "References"                                                 
#>  [7] "_2021_Planner+School List.xlsx"                             
#>  [8] "2023-05-17-dhcd-code-enforcement_recommendation-review.docx"
#>  [9] "ACCE-and-Indepedence_2017-Recommendation-Table.xlsx"        
#> [10] "Budget scrap.xlsx"                                          
#> [11] "Dorothy-Height-ES_2017-Recommendation-Table.xlsx"           
#> [12] "Historical Assessment Doc.docx"                             
#> [13] "INSPIRE Community Engagement Notebook.xlsx"                 
#> [14] "INSPIRE Comprehensive Plan Contribution.docx"               
#> [15] "INSPIRE DOP Website Copy.docx"                              
#> [16] "INSPIRE Master Contact List.xlsx"                           
#> [17] "INSPIRE Plan Folder Index.xlsx"                             
#> [18] "INSPIRE Plan Timelines 2021_08.docx"                        
#> [19] "INSPIRE Planning and Program Management Guide.docx"         
#> [20] "INSPIRE Program"                                            
#> [21] "INSPIRE Program Calendar.xlsx"                              
#> [22] "INSPIRE Rec tables 2023.xlsx"                               
#> [23] "INSPIRE Workflow DRAFT.docx"                                
#> [24] "inspire-area-plan-document-template Folder.zip"             
#> [25] "INSPIRE-Plan-Recommendation-Table-Tracker.xlsx"             
#> [26] "Middle Neighborhoods INSPIRE Assessment Plan.docx"          
#> [27] "Patterson-Building_2018-Recommendation-Table.xlsx"          
#> [28] "Preparing for a Community Walk.docx"                        
#> [29] "RampPrintouts.xlsx"                                         
#> [30] "Stakeholder Outreach Spreadsheet 2025.xlsx"                 
#> [31] "Test Planner Import.xlsx"                                   
#> [32] "USP Interview notes.docx"
```

But you can’t use that URL to get a list:

``` r

get_sp_list(dir_url)
#> Error:
#> ! `url` must be a URL with ":l:" or "/Lists/" to be a
#>   valid SharePoint list URL.
```

SharePoint list URLs come in a few different styles and they all work. A
shared link for a list includes `:l:`:

``` r

list_url <- "https://bmore.sharepoint.com/:l:/r/sites/MayorsOffice-DataGovernance/Lists/Data%20Governance%20Progress%20Tracker?e=0P1fFX"

get_sp_list(list_url)
#> Loading Microsoft Graph login for default tenant
#> <Sharepoint list 'Data Governance Progress Tracker'>
#>   directory id: 5c21d327-7016-4b69-ae0d-dc95059a876c 
#>   web link: https://bmore.sharepoint.com/sites/MayorsOffice-DataGovernance/Lists/Data%20Governance%20Progress%20Tracker 
#>   description:  
#> ---
#>   Methods:
#>     bulk_import, create_item, delete,
#>     delete_item, do_operation, get_column_info,
#>     get_item, get_list_pager, list_items,
#>     sync_fields, update, update_item
```

The URL in your browser address bar when viewing a list includes the
name of the list view page (e.g. `AllItems.aspx`) and may include the
query parameter `env=WebViewList`. A URL with the list name but no view
page also works:

``` r

list_view_url <- "https://bmore.sharepoint.com/sites/MayorsOffice-DataGovernance/Lists/Data%20Governance%20Progress%20Tracker/AllItems.aspx?env=WebViewList"

sp_url_parse(list_view_url)[c("site_url", "list_name")]
#> $site_url
#> [1] "https://bmore.sharepoint.com/sites/MayorsOffice-DataGovernance"
#> 
#> $list_name
#> [1] "Data Governance Progress Tracker"

sp_url_parse(
  "https://bmore.sharepoint.com/sites/MayorsOffice-DataGovernance/Lists/Data%20Governance%20Progress%20Tracker"
)[c("site_url", "list_name")]
#> $site_url
#> [1] "https://bmore.sharepoint.com/sites/"
#> 
#> $<NA>
#> NULL
```

Shared URLs for files work with
[`get_sp_item()`](https://elipousson.github.io/sharepointr/reference/get_sp_item.md)
and
[`get_sp_item_properties()`](https://elipousson.github.io/sharepointr/reference/get_sp_item.md):

``` r

file_url <- "https://bmore.sharepoint.com/:w:/r/sites/DOP-CPR/Shared%20Documents/INSPIRE%20Program%20%F0%9F%8F%AB%F0%9F%9A%B8%F0%9F%8C%B3/INSPIRE%20Plans%20Adopted%20%E2%9C%85/Govans%20ES/Govans%20Final%20Planning%20Document%20and%20related%20materials/Govans%20INSPIRE%20Plan%20-%20Final%20draft%20before%20layout.docx?d=w3408fbc67fa2462187409eb240eb4df2&csf=1&web=1&e=4dcgze"

get_sp_item(file_url)
#> Loading Microsoft Graph login for default tenant
#> <Drive item 'Govans INSPIRE Plan - Final draft before layout.docx'>
#>   directory id: 01EK4O46WG7MEDJIT7EFDIOQE6WJAOWTPS 
#>   web link: https://bmore.sharepoint.com/sites/DOP-CPR/_layouts/15/Doc.aspx?sourcedoc=%7B3408FBC6-7FA2-4621-8740-9EB240EB4DF2%7D&file=Govans%20INSPIRE%20Plan%20-%20Final%20draft%20before%20layout.docx&action=default&mobileredirect=true 
#>   type: file 
#> ---
#>   Methods:
#>     copy, create_folder, create_share_link,
#>     delete, do_operation, download, get_item,
#>     get_list_pager, get_parent_folder, get_path,
#>     is_folder, list_files, list_items,
#>     load_dataframe, load_rdata, load_rds, move,
#>     open, save_dataframe, save_rdata, save_rds,
#>     sync_fields, update, upload
```

A shared link like this one includes the path to the file, so it stops
working if the file is moved or renamed. A document URL (the URL in your
browser address bar when a file is open in Word, Excel, or PowerPoint
online) uses the item id instead, so it keeps working after a file is
moved. It works as long as the default library is set to match the
document library of the supplied URL:

``` r

document_url <- "https://bmore.sharepoint.com/:w:/r/sites/DOP-CPR/_layouts/15/Doc.aspx?sourcedoc=%7B3408FBC6-7FA2-4621-8740-9EB240EB4DF2%7D&file=Govans%20INSPIRE%20Plan%20-%20Final%20draft%20before%20layout.docx&action=default&mobileredirect=true"

get_sp_item(document_url)
#> Loading Microsoft Graph login for default tenant
#> <Drive item 'Govans INSPIRE Plan - Final draft before layout.docx'>
#>   directory id: 01EK4O46WG7MEDJIT7EFDIOQE6WJAOWTPS 
#>   web link: https://bmore.sharepoint.com/sites/DOP-CPR/_layouts/15/Doc.aspx?sourcedoc=%7B3408FBC6-7FA2-4621-8740-9EB240EB4DF2%7D&file=Govans%20INSPIRE%20Plan%20-%20Final%20draft%20before%20layout.docx&action=default&mobileredirect=true 
#>   type: file 
#> ---
#>   Methods:
#>     copy, create_folder, create_share_link,
#>     delete, do_operation, download, get_item,
#>     get_list_pager, get_parent_folder, get_path,
#>     is_folder, list_files, list_items,
#>     load_dataframe, load_rdata, load_rds, move,
#>     open, save_dataframe, save_rdata, save_rds,
#>     sync_fields, update, upload
```

The
[`is_sp_url()`](https://elipousson.github.io/sharepointr/reference/is_sp_url.md)
family of functions
(e.g. [`is_sp_folder_url()`](https://elipousson.github.io/sharepointr/reference/is_sp_url.md))
can be used to check what type of URL you have before using it.

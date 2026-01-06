# Parse a SharePoint URL using `httr2::url_parse`

`sp_url_parse()` parses a URL into a named list of parts.

`sp_url_parse_hostname()` parses the hostname into a tenant and
base_url.

`sp_url_parse_path()` parses the path into a URL type, permissions,
drive name, file path, and file name.

`sp_url_parse_query()` parses the item ID from a query.

## Usage

``` r
sp_url_parse(url, call = caller_env())

sp_url_parse_hostname(hostname, tenant = "[a-zA-Z0-9.-]+", scheme = "https")

sp_url_parse_path(
  path,
  url_type = "w|x|p|o|b|t|i|v|f|u|li",
  permissions = "r|s|t|u|g",
  drive_name_prefix = "Shared ",
  default_drive_name = "Documents"
)

sp_url_parse_query(query)
```

## Details

Types of SharePoint URLs

SharePoint site URL:

https://\[tenant\].sharepoint.com/sites/\[site name\]

SharePoint document editor URL:

https://\[tenant\].sharepoint.com/:\[url
type\]:/\[permissions\]/sites/\[site
name\]/\_layouts/15/Doc.aspx?sourcedoc={\[item id\]}&file=\[file
name\]&\[additional query parameters\]

SharePoint List URL:

https://\[tenant\].sharepoint.com/sites/\[site name\]/Lists/\[list
name\]/AllItems.aspx?env=WebViewList

https://\[tenant\].sharepoint.com/:l:/r/sites/\[site name\]/Lists/\[list
name\]

SharePoint folder URL:

https://\[tenant\].sharepoint.com/:\[url
type\]:/\[permissions\]/sites/\[site name\]/\[drive name (with possible
"Shared" prefix)\]/\[folder path\]/\[folder name\]/?\[additional query
parameters\]

SharePoint Planner URL:

https://tasks.office.com/\[tenant\].onmicrosoft.com/en-US/Home/Planner/#/plantaskboard?groupId=\[Group
ID\]&planId=\[Plan ID\]

SharePoint Document Library (or Drive) URL:

https://\[tenant\].sharepoint.com/sites/\[tenant\]/\[drive name (with
possible "Shared" prefix)\]/Forms/AllItems.aspx

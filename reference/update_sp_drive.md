# Update or delete a SharePoint document library

**\[experimental\]**

`update_sp_drive()` updates the display name or description of a
document library. Changing the display name changes the drive name but
not the library URL.

`delete_sp_drive()` deletes a document library and all of its files and
folders. It requires confirmation by default and can't delete the
default document library of a site (usually named "Documents").

Both functions get the library's list from the drive and use
[`update_sp_list()`](https://elipousson.github.io/sharepointr/reference/create_sp_list.md)
or
[`delete_sp_list()`](https://elipousson.github.io/sharepointr/reference/create_sp_list.md).

## Usage

``` r
update_sp_drive(
  drive_name = NULL,
  drive_id = NULL,
  drive_url = NULL,
  drive = NULL,
  display_name = NULL,
  description = NULL,
  ...,
  properties = FALSE,
  site_url = NULL,
  site = NULL,
  call = caller_env()
)

delete_sp_drive(
  drive_name = NULL,
  drive_id = NULL,
  drive_url = NULL,
  drive = NULL,
  confirm = TRUE,
  ...,
  site_url = NULL,
  site = NULL,
  call = caller_env()
)
```

## Arguments

- drive_name, drive_id:

  SharePoint Drive name or ID passed to `get_drive` method for
  SharePoint site object.

- drive_url:

  A SharePoint Drive URL to parse for a Drive name and other
  information. If `drive_name` is a URL, it is used as `drive_url`.

- drive:

  A `ms_drive` object. If `drive` is supplied, `drive_name`, `drive_id`,
  and `drive_url` are ignored.

- display_name:

  New display name for the library. Optional.

- description:

  New description for the library. Optional.

- ...:

  Additional parameters passed to
  [`get_sp_drive()`](https://elipousson.github.io/sharepointr/reference/sp_drive.md)
  if `drive` is `NULL`.

- properties:

  For `update_sp_drive()`, if `TRUE`, return the drive properties
  instead of the `ms_drive` object. Defaults to `FALSE`.

- site_url:

  A SharePoint site URL in the format "https://\[tenant
  name\].sharepoint.com/sites/\[site name\]". Any SharePoint item or
  document URL can also be parsed to build a site URL using the tenant
  and site name included in the URL.

- site:

  A `ms_site` object. If `site` is supplied, `site_url`, `site_name`,
  and `site_id` are ignored.

- call:

  The execution environment of a currently running function, e.g.
  `caller_env()`. The function will be mentioned in error messages as
  the source of the error. See the `call` argument of
  [`abort()`](https://rlang.r-lib.org/reference/abort.html) for more
  information.

- confirm:

  If `TRUE` (default), confirm deletion of the library before
  proceeding.

## Value

For `update_sp_drive()`, the updated `ms_drive` object or its properties
if `properties = TRUE`. For `delete_sp_drive()`, invisibly returns
`NULL`.

## See also

[`create_sp_drive()`](https://elipousson.github.io/sharepointr/reference/create_sp_drive.md)

## Examples

``` r
if (FALSE) { # \dontrun{
drive <- update_sp_drive(
  "Project Files",
  description = "Files for active projects",
  site_url = "<SharePoint site url>"
)

delete_sp_drive(drive = drive)
} # }
```

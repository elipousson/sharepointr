# Create a SharePoint document library

**\[experimental\]**

`create_sp_drive()` creates a document library on a SharePoint site and
returns the library's drive as a `ms_drive` object. A document library
is a SharePoint list created with the `"documentLibrary"` template, so
this function wraps
[`create_sp_list()`](https://elipousson.github.io/sharepointr/reference/create_sp_list.md).
Columns, views, and folders can be supplied with a list definition (see
[`read_sp_list_yaml()`](https://elipousson.github.io/sharepointr/reference/sp_list_definition.md)).

The library's list can be used with the list functions (e.g.
[`compare_sp_list()`](https://elipousson.github.io/sharepointr/reference/compare_sp_list.md)
or
[`sync_sp_list()`](https://elipousson.github.io/sharepointr/reference/compare_sp_list.md))
and the drive can be used with the file and folder functions (e.g.
[`sp_dir_create()`](https://elipousson.github.io/sharepointr/reference/sp_dir_create.md)
or
[`upload_sp_item()`](https://elipousson.github.io/sharepointr/reference/upload_sp_item.md)).

`create_sp_drive()` doesn't create a SharePoint Embedded container (a
Graph `fileStorageContainer`). Containers aren't part of a SharePoint
site and can only be created by an app that owns a registered container
type.

## Usage

``` r
create_sp_drive(
  drive_name = NULL,
  description = NULL,
  ...,
  folders = NULL,
  definition = NULL,
  properties = FALSE,
  site_url = NULL,
  site = NULL,
  call = caller_env()
)
```

## Arguments

- drive_name:

  Library name used as the `displayName` property. SharePoint sets the
  library URL from this name, so the drive name and URL can't be changed
  separately. Required unless `definition` is supplied.

- description:

  Optional description.

- ...:

  Additional parameters passed to
  [`create_sp_list()`](https://elipousson.github.io/sharepointr/reference/create_sp_list.md)
  (e.g. `columns`, `content_types`, or `hidden`) and to
  [`get_sp_site()`](https://elipousson.github.io/sharepointr/reference/sp_site.md)
  if `site` is `NULL`.

- folders:

  Optional. A character vector of folder paths to create, relative to
  the library root (e.g. `c("Reports/2026", "Data")`). Parent folders
  are created as needed. Replaces any `folders` in `definition`.

- definition:

  Optional. A list definition from
  [`read_sp_list_yaml()`](https://elipousson.github.io/sharepointr/reference/sp_list_definition.md)
  or a path to a YAML file. The definition `list.template` must be
  `documentLibrary` if it is set. See
  [`create_sp_list()`](https://elipousson.github.io/sharepointr/reference/create_sp_list.md)
  for how the definition is used.

- properties:

  If `TRUE`, return the drive properties instead of the `ms_drive`
  object. Defaults to `FALSE`.

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

## Value

A `ms_drive` object for the new library, or the drive properties as a
named list if `properties = TRUE`.

## See also

[`update_sp_drive()`](https://elipousson.github.io/sharepointr/reference/update_sp_drive.md),
[`delete_sp_drive()`](https://elipousson.github.io/sharepointr/reference/update_sp_drive.md),
[`create_sp_list()`](https://elipousson.github.io/sharepointr/reference/create_sp_list.md),
[`get_sp_drive()`](https://elipousson.github.io/sharepointr/reference/sp_drive.md)

## Examples

``` r
if (FALSE) { # \dontrun{
create_sp_drive(
  "Project Files",
  folders = c("Contracts", "Reports/2026"),
  site_url = "<SharePoint site url>"
)

create_sp_drive(
  definition = "library-fields/project-files.yaml",
  site_url = "<SharePoint site url>"
)
} # }
```

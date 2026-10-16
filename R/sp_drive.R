#' Get a SharePoint drive or set a default SharePoint drive
#'
#' @description
#' [get_sp_drive()] wraps the `get_drive` method returns a `ms_drive` object.
#'
#' [cache_sp_drive()] allows you to cache a default SharePoint drive for use by
#' other functions. Additional parameters in `...` are passed to
#' [get_sp_drive()].
#'
#' @name sp_drive
#' @seealso [Microsoft365R::ms_drive]
#' @returns For [get_sp_drive()], a `ms_drive` object, or the drive
#'   properties as a named list if `properties = TRUE`. For
#'   [cache_sp_drive()], invisibly returns `NULL`.
#' @keywords drives
NULL

#' @rdname sp_drive
#' @name get_sp_drive
#' @param drive_name,drive_id SharePoint Drive name or ID passed to `get_drive`
#'   method for SharePoint site object.
#' @param drive_url A SharePoint Drive URL to parse for a Drive name and other
#'   information. If `drive_name` is a URL, it is used as `drive_url`.
#' @param properties If `TRUE`, return the drive properties instead of the
#'   `ms_drive` object. Defaults to `FALSE`.
#' @inheritParams sp_site
#' @inheritDotParams get_sp_site
#' @param default_drive_name Drive name string used only if input is a document
#'   URL and drive name is not part of the URL. Defaults to
#'   `getOption("sharepointr.default_drive_name", "Documents")`
#' @param cache If `TRUE`, cache drive to a file using [cache_sp_drive()].
#' @param refresh If `TRUE`, get a new drive even if the existing drive is
#'   cached as a local option. If `FALSE`, use the cached `ms_drive` object if
#'   it exists.
#' @export
get_sp_drive <- function(
  drive_name = NULL,
  drive_id = NULL,
  drive_url = NULL,
  properties = FALSE,
  ...,
  site_url = NULL,
  site = NULL,
  default_drive_name = getOption(
    "sharepointr.default_drive_name",
    "Documents"
  ),
  cache = getOption("sharepointr.cache", FALSE),
  refresh = getOption("sharepointr.refresh", TRUE),
  overwrite = FALSE,
  cache_file = NULL,
  call = caller_env()
) {
  if (cache) {
    cache_exists <- file.exists(sp_cache_path(
      cache_file,
      what = "ms_drive",
      call = call
    ))
  }

  if (cache && cache_exists && !refresh) {
    drive <- get_cached_ms_obj(
      cache_file = cache_file,
      what = "ms_drive",
      call = call
    )

    if (is_ms_drive(drive)) {
      return(drive)
    } else {
      cache_exists <- FALSE
      overwrite <- TRUE
      # TODO: Add warning and set `refresh = TRUE` if cached file is not a
      # ms_site object
      # Set refresh to `TRUE`
      # refresh <- TRUE
    }
  }

  if (!is.null(drive_name) && is_sp_url(drive_name)) {
    drive_url <- drive_name
    drive_name <- NULL
  }

  if (!is.null(drive_url)) {
    if (!is.null(drive_name)) {
      cli::cli_bullets(
        c(
          "!" = "Any SharePoint Drive name contained in {.arg drive_url}
          is ignored if {.arg drive_name} is also supplied."
        )
      )
    }

    sp_url_parts <- sp_url_parse(drive_url, call = call)
    site_url <- site_url %||% sp_url_parts[["site_url"]]
    drive_name <- drive_name %||% sp_url_parts[["drive_name"]]
    drive_id <- drive_id %||% sp_url_parts[["drive_id"]]

    if (is.null(drive_id)) {
      drive_name <- drive_name %||% default_drive_name
    }

    # FIXME: This is a work-around for incomplete URL parsing
    if (identical(drive_name, "Lists")) {
      drive_name <- default_drive_name
    }
  }

  site <- site %||%
    get_sp_site(
      site_url = site_url,
      ...,
      refresh = refresh,
      overwrite = overwrite,
      call = call
    )

  check_ms_site(site, call = call)

  check_exclusive_strings(drive_name, drive_id, call = call)

  drive <- site$get_drive(drive_name = drive_name, drive_id = drive_id)

  if (cache && (refresh || !cache_exists)) {
    cache_sp_drive(
      drive = drive,
      cache_file = cache_file,
      overwrite = overwrite,
      call = call
    )
  }

  if (properties) {
    return(drive$properties)
  }

  drive
}

#' @rdname sp_drive
#' @name cache_sp_drive
#' @param drive A `ms_drive` object. If `drive` is supplied, `drive_name` and
#'   `drive_id` are ignored.
#' @inheritParams cache_sp_site
#' @export
cache_sp_drive <- function(
  ...,
  drive = NULL,
  cache_file = getOption(
    "sharepointr.cache_file_drive",
    "sp_drive.rds"
  ),
  overwrite = FALSE,
  call = caller_env()
) {
  drive <- drive %||% get_sp_drive(..., call = call)

  check_ms_drive(drive, call = call)

  cache_ms_obj(
    drive,
    cache_file = cache_file,
    overwrite = overwrite,
    what = "ms_drive",
    call = call
  )
}

#' List drives for a SharePoint site
#'
#' [list_sp_drives()] loads a SharePoint site uses the `list_drives` method to
#' returns a data frame with a list column or `ms_drive` objects or, if
#' `as_data_frame = FALSE`. This is helpful if a drive has been renamed and
#' can't easily be identified using a Drive URL alone.
#'
#' @seealso [Microsoft365R::ms_site]
#' @inheritDotParams get_sp_site
#' @param filter Filter to apply to query
#' @param n Max number of drives to return
#' @param as_data_frame If `TRUE` (default), return list as a data frame.
#' @inheritParams get_sp_site
#' @returns A data frame with a list column of `ms_drive` objects if
#'   `as_data_frame = TRUE` (default), or a list of `ms_drive` objects if
#'   `FALSE`.
#' @export
list_sp_drives <- function(
  ...,
  site = NULL,
  filter = NULL,
  n = NULL,
  as_data_frame = TRUE,
  call = caller_env()
) {
  sp_site <- site %||% get_sp_site(..., call = call)

  site_drives <- sp_site$list_drives(filter = filter, n = n %||% Inf)

  if (!as_data_frame) {
    return(site_drives)
  }

  # TODO: Move name column to the front
  ms_obj_list_as_data_frame(
    site_drives,
    obj_col = "ms_drive",
    keep_list_cols = c("lastModifiedBy", "createdBy"),
    .error_call = call
  )
}

#' Create a SharePoint document library
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' [create_sp_drive()] creates a document library on a SharePoint site and
#' returns the library's drive as a `ms_drive` object. A document library is a
#' SharePoint list created with the `"documentLibrary"` template, so this
#' function wraps [create_sp_list()]. Columns, views, and folders can be
#' supplied with a list definition (see [read_sp_list_yaml()]).
#'
#' The library's list can be used with the list functions (e.g.
#' [compare_sp_list()] or [sync_sp_list()]) and the drive can be used with the
#' file and folder functions (e.g. [sp_dir_create()] or [upload_sp_item()]).
#'
#' [create_sp_drive()] doesn't create a SharePoint Embedded container (a Graph
#' `fileStorageContainer`). Containers aren't part of a SharePoint site and can
#' only be created by an app that owns a registered container type.
#'
#' @param drive_name Library name used as the `displayName` property.
#'   SharePoint sets the library URL from this name, so the drive name and URL
#'   can't be changed separately. Required unless `definition` is supplied.
#' @param description Optional description.
#' @param ... Additional parameters passed to [create_sp_list()] (e.g.
#'   `columns`, `content_types`, or `hidden`) and to [get_sp_site()] if
#'   `site` is `NULL`.
#' @param folders Optional. A character vector of folder paths to create,
#'   relative to the library root (e.g. `c("Reports/2026", "Data")`). Parent
#'   folders are created as needed. Replaces any `folders` in `definition`.
#' @param definition Optional. A list definition from [read_sp_list_yaml()] or
#'   a path to a YAML file. The definition `list.template` must be
#'   `documentLibrary` if it is set. See [create_sp_list()] for how the
#'   definition is used.
#' @param properties If `TRUE`, return the drive properties instead of the
#'   `ms_drive` object. Defaults to `FALSE`.
#' @inheritParams get_sp_site
#' @returns A `ms_drive` object for the new library, or the drive properties
#'   as a named list if `properties = TRUE`.
#' @seealso [update_sp_drive()], [delete_sp_drive()], [create_sp_list()],
#'   [get_sp_drive()]
#' @keywords drives
#' @examples
#' \dontrun{
#' create_sp_drive(
#'   "Project Files",
#'   folders = c("Contracts", "Reports/2026"),
#'   site_url = "<SharePoint site url>"
#' )
#'
#' create_sp_drive(
#'   definition = "library-fields/project-files.yaml",
#'   site_url = "<SharePoint site url>"
#' )
#' }
#' @export
create_sp_drive <- function(
  drive_name = NULL,
  description = NULL,
  ...,
  folders = NULL,
  definition = NULL,
  properties = FALSE,
  site_url = NULL,
  site = NULL,
  call = caller_env()
) {
  check_bool(properties, call = call)

  if (has_name(list2(...), "template")) {
    cli_abort(
      "{.arg template} can't be set: a drive is always created with the
      {.val documentLibrary} template.",
      call = call
    )
  }

  if (!is.null(definition)) {
    if (is_string(definition)) {
      definition <- read_sp_list_yaml(definition, call = call)
    }

    definition <- as_sp_list_definition(definition, call = call)
    template <- definition[["list"]][["template"]]

    if (!is.null(template) && template != "documentLibrary") {
      cli_abort(
        c(
          "{.arg definition} must use the {.val documentLibrary} template,
          not {.val {template}}.",
          "i" = "Use {.fn create_sp_list} to create a list."
        ),
        call = call
      )
    }
  }

  if (!is.null(folders)) {
    folders <- check_sp_drive_folders(folders, arg = "folders", call = call)
  }

  sp_list <- create_sp_list(
    list_name = drive_name,
    ...,
    description = description,
    template = "documentLibrary",
    definition = definition,
    site_url = site_url,
    site = site,
    call = call
  )

  drive <- sp_list_drive(sp_list)

  if (length(folders) > 0) {
    create_sp_drive_folders(drive, folders, call = call)
  }

  if (properties) {
    return(drive[["properties"]])
  }

  drive
}

#' Update or delete a SharePoint document library
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' [update_sp_drive()] updates the display name or description of a document
#' library. Changing the display name changes the drive name but not the
#' library URL.
#'
#' [delete_sp_drive()] deletes a document library and all of its files and
#' folders. It requires confirmation by default and can't delete the default
#' document library of a site (usually named "Documents").
#'
#' Both functions get the library's list from the drive and use
#' [update_sp_list()] or [delete_sp_list()].
#'
#' @inheritParams get_sp_drive
#' @param drive A `ms_drive` object. If `drive` is supplied, `drive_name`,
#'   `drive_id`, and `drive_url` are ignored.
#' @param display_name New display name for the library. Optional.
#' @param description New description for the library. Optional.
#' @param ... Additional parameters passed to [get_sp_drive()] if `drive` is
#'   `NULL`.
#' @param properties For [update_sp_drive()], if `TRUE`, return the drive
#'   properties instead of the `ms_drive` object. Defaults to `FALSE`.
#' @param confirm If `TRUE` (default), confirm deletion of the library before
#'   proceeding.
#' @returns For [update_sp_drive()], the updated `ms_drive` object or its
#'   properties if `properties = TRUE`. For [delete_sp_drive()], invisibly
#'   returns `NULL`.
#' @seealso [create_sp_drive()]
#' @keywords drives
#' @examples
#' \dontrun{
#' drive <- update_sp_drive(
#'   "Project Files",
#'   description = "Files for active projects",
#'   site_url = "<SharePoint site url>"
#' )
#'
#' delete_sp_drive(drive = drive)
#' }
#' @export
update_sp_drive <- function(
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
) {
  check_string(display_name, allow_null = TRUE, call = call)
  check_string(description, allow_null = TRUE, call = call)
  check_bool(properties, call = call)

  if (is.null(display_name) && is.null(description)) {
    cli_abort(
      "{.arg display_name} or {.arg description} must be supplied.",
      call = call
    )
  }

  drive <- drive %||%
    get_sp_drive(
      drive_name = drive_name,
      drive_id = drive_id,
      drive_url = drive_url,
      ...,
      site_url = site_url,
      site = site,
      call = call
    )

  check_sp_library_drive(drive, call = call)

  update_sp_list(
    sp_list = sp_drive_list(drive),
    display_name = display_name,
    description = description,
    call = call
  )

  drive$sync_fields()

  if (properties) {
    return(drive[["properties"]])
  }

  drive
}

#' @rdname update_sp_drive
#' @export
delete_sp_drive <- function(
  drive_name = NULL,
  drive_id = NULL,
  drive_url = NULL,
  drive = NULL,
  confirm = TRUE,
  ...,
  site_url = NULL,
  site = NULL,
  call = caller_env()
) {
  check_bool(confirm, call = call)

  drive <- drive %||%
    get_sp_drive(
      drive_name = drive_name,
      drive_id = drive_id,
      drive_url = drive_url,
      ...,
      site_url = site_url,
      site = site,
      call = call
    )

  check_sp_library_drive(drive, call = call)

  sp_list <- sp_drive_list(drive)
  site_id <- sp_list[["properties"]][["parentReference"]][["siteId"]]
  nm <- drive[["properties"]][["name"]]

  if (identical(sp_site_default_drive_id(drive, site_id), drive[["properties"]][["id"]])) {
    cli_abort(
      "{.val {nm}} is the default document library of the site and can't be
      deleted.",
      call = call
    )
  }

  if (confirm) {
    n_items <- drive$get_item("/")[["properties"]][["folder"]][["childCount"]]

    check_yes(
      cli::format_inline(
        "Do you want to delete the library {.val {nm}} and all of its files
        and folders ({n_items %||% 0} top-level item{?s})?"
      ),
      call = call
    )
  }

  cli_progress_step("Deleting library {.val {nm}}")

  sp_list$delete(confirm = FALSE)

  invisible(NULL)
}

#' Check that a drive is a SharePoint document library
#' @noRd
check_sp_library_drive <- function(
  drive,
  arg = caller_arg(drive),
  call = caller_env()
) {
  check_ms_drive(drive, arg = arg, call = call)

  drive_type <- drive[["properties"]][["driveType"]]

  if (!identical(drive_type, "documentLibrary")) {
    cli_abort(
      "{.arg {arg}} must be a SharePoint document library, not a
      {.val {drive_type}} drive.",
      call = call
    )
  }

  invisible(NULL)
}

#' Get the list for a document library drive
#' @noRd
sp_drive_list <- function(drive) {
  Microsoft365R::ms_list$new(
    drive[["token"]],
    drive[["tenant"]],
    drive$do_operation("list")
  )
}

#' Get the id of the default drive of a site
#' @noRd
sp_site_default_drive_id <- function(drive, site_id) {
  AzureGraph::call_graph_endpoint(
    drive[["token"]],
    file.path("sites", site_id, "drive"),
    options = list(`$select` = "id")
  )[["id"]]
}

#' Get the drive for a document library list
#' @noRd
sp_list_drive <- function(sp_list) {
  Microsoft365R::ms_drive$new(
    sp_list[["token"]],
    sp_list[["tenant"]],
    sp_list$do_operation("drive")
  )
}

#' Check and normalize folder paths for a document library
#'
#' Removes leading and trailing slashes and errors for empty, duplicated, or
#' invalid paths.
#' @noRd
check_sp_drive_folders <- function(
  folders,
  arg = "folders",
  call = caller_env()
) {
  if (length(folders) == 0 && !is_named(folders)) {
    return(character(0))
  }

  if (is.list(folders) && !is_named(folders) && all(purrr::map_lgl(folders, is_string))) {
    folders <- unlist(folders)
  }

  if (!is.character(folders) || is_named(folders) || anyNA(folders)) {
    cli_abort(
      "{.field {arg}} must be a character vector of folder paths (a YAML
      sequence of strings).",
      call = call
    )
  }

  folders <- gsub("^/+|/+$", "", folders)
  segments <- strsplit(folders, "/", fixed = TRUE)

  is_invalid <- purrr::map_lgl(
    segments,
    \(x) {
      length(x) == 0 ||
        any(!nzchar(x)) ||
        any(grepl("[\"*:<>?\\\\|]", x)) ||
        any(x != trimws(x)) ||
        any(grepl("\\.$", x))
    }
  )

  if (any(is_invalid)) {
    cli_abort(
      c(
        "{.field {arg}} has invalid folder path{?s}: {.val {folders[is_invalid]}}.",
        "i" = "Separate folders with {.code /}. A folder name can't be empty,
        start or end with a space, end with a period, or include any of
        {.code \" * : < > ? \\ |}."
      ),
      call = call
    )
  }

  dupes <- unique(folders[duplicated(folders)])

  if (length(dupes) > 0) {
    cli_abort(
      "{.field {arg}} must be unique. Duplicated: {.val {dupes}}.",
      call = call
    )
  }

  folders
}

#' Create folders in a drive
#'
#' Parent folders are created as needed. A folder that already exists is a
#' warning.
#' @noRd
create_sp_drive_folders <- function(drive, folders, call = caller_env()) {
  cli_progress_step("Creating {length(folders)} folder{?s}.")

  for (folder in folders) {
    try_fetch(
      drive$create_folder(path = folder),
      error = function(cnd) {
        cli_warn(
          "Can't create folder {.val {folder}}.",
          parent = cnd,
          call = call
        )
      }
    )
  }

  invisible(drive)
}

#' List the folders in a drive
#'
#' Lists folders recursively and returns the paths of folders that have no
#' subfolders (creating these paths also creates their parent folders).
#' @noRd
list_sp_drive_folders <- function(drive, path = "") {
  files <- drive$list_files(path = path, info = "partial")
  dirs <- files[["name"]][files[["isdir"]]]

  if (length(dirs) == 0) {
    return(character(0))
  }

  dirs <- if (nzchar(path)) paste0(path, "/", dirs) else dirs

  unlist(
    purrr::map(
      dirs,
      \(dir) {
        subdirs <- list_sp_drive_folders(drive, dir)
        if (length(subdirs) == 0) dir else subdirs
      }
    )
  )
}

#' Find folder paths that don't exist in a drive
#'
#' Also returns paths that exist as a file.
#' @returns A named character vector with `"missing"` or `"file"` for each
#'   path that isn't a folder.
#' @noRd
sp_drive_missing_folders <- function(drive, folders) {
  status <- purrr::map_chr(
    folders,
    \(folder) {
      item <- tryCatch(drive$get_item(folder), error = function(cnd) NULL)

      if (is.null(item)) {
        "missing"
      } else if (item$is_folder()) {
        "exists"
      } else {
        "file"
      }
    }
  )

  set_names(status, folders)[status != "exists"]
}

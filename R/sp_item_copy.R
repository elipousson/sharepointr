#' Copy or move SharePoint files and folders
#'
#' @description
#' These functions copy or move items in a SharePoint document library. Their
#' interface is based on [fs::file_copy()], [fs::file_move()], and
#' [fs::dir_copy()]:
#'
#' - [sp_item_copy()] copies files. Use [sp_dir_copy()] to copy folders.
#' - [sp_item_move()] moves (or renames) files or folders.
#' - [sp_dir_copy()] and [sp_dir_move()] copy or move folders and their
#'   contents.
#'
#' As with `{fs}`, if `new_path` is an existing folder, each item is placed
#' inside that folder and keeps its name. Otherwise, `new_path` is the full
#' path for the new item and its parent folder must already exist. A `new_path`
#' that ends in `"/"` must be an existing folder.
#'
#' `new_path` can be a path relative to the drive that holds the item, or a
#' SharePoint folder or document library URL. Items can be copied to another
#' drive or site, but they can only be moved within the same drive.
#'
#' @details Copying is asynchronous
#'
#' Microsoft Graph copies items in the background. If `wait = TRUE` (the
#' default), [sp_item_copy()] and [sp_dir_copy()] check the status of each copy
#' until it is complete, so they can report an error if a copy fails. Large
#' folders can take a while to copy. If `wait = FALSE`, the copy may still be
#' running when the function returns, and a failed copy isn't reported.
#'
#' @param path A character vector of file or folder paths, or SharePoint file
#'   or folder URLs. A relative path must not include the drive name. `path`
#'   can also be a `ms_drive_item` object or a list of `ms_drive_item`
#'   objects.
#' @param new_path A character vector of new paths, or SharePoint folder or
#'   document library URLs. `new_path` must be length 1 or the same length as
#'   `path`. A relative `new_path` is in the same drive as the item it is
#'   paired with.
#' @param overwrite If `FALSE` (default), an error is returned if an item
#'   already exists at the new path. If `TRUE`, an existing file is replaced.
#'   SharePoint can't replace a folder, so [sp_dir_copy()] works like
#'   [fs::dir_copy()] instead: if `new_path` is an existing folder and
#'   `overwrite = TRUE`, the contents of `path` are copied into `new_path`
#'   (replacing any files with the same name). [sp_dir_move()] has no
#'   `overwrite` argument because a folder can't be moved to an existing
#'   folder.
#' @param wait If `TRUE` (default), wait until each copy is complete. See
#'   details.
#' @inheritDotParams get_sp_drive -drive_name -drive_id -properties
#' @inheritParams get_sp_item
#' @returns Invisibly returns a character vector with the new path of each
#'   item, relative to the drive it was copied or moved to.
#' @seealso [Microsoft365R::ms_drive_item]
#' @examples
#' dir_url <- "<link to SharePoint directory>"
#'
#' if (is_sp_url(dir_url)) {
#'   drive <- get_sp_drive(drive_name = dir_url)
#'
#'   # Copy a file into an existing folder
#'   sp_item_copy("Reports/report.docx", "Archive", drive = drive)
#'
#'   # Rename a file
#'   sp_item_move(
#'     "Reports/report.docx",
#'     "Reports/report-2026.docx",
#'     drive = drive
#'   )
#'
#'   # Copy a folder to a new folder named "Reports-backup"
#'   sp_dir_copy("Reports", "Reports-backup", drive = drive)
#'
#'   # Move a folder into the folder at a SharePoint URL
#'   sp_dir_move("Reports-backup", dir_url, drive = drive)
#' }
#'
#' @keywords files
#' @export
sp_item_copy <- function(
  path,
  new_path,
  ...,
  overwrite = FALSE,
  wait = TRUE,
  drive_name = NULL,
  drive_id = NULL,
  drive = NULL,
  site_url = NULL,
  call = caller_env()
) {
  sp_item_transfer(
    path = path,
    new_path = new_path,
    ...,
    method = "copy",
    type = "file",
    overwrite = overwrite,
    wait = wait,
    drive_name = drive_name,
    drive_id = drive_id,
    drive = drive,
    site_url = site_url,
    call = call
  )
}

#' @rdname sp_item_copy
#' @name sp_item_move
#' @export
sp_item_move <- function(
  path,
  new_path,
  ...,
  overwrite = FALSE,
  drive_name = NULL,
  drive_id = NULL,
  drive = NULL,
  site_url = NULL,
  call = caller_env()
) {
  sp_item_transfer(
    path = path,
    new_path = new_path,
    ...,
    method = "move",
    type = "any",
    overwrite = overwrite,
    drive_name = drive_name,
    drive_id = drive_id,
    drive = drive,
    site_url = site_url,
    call = call
  )
}

#' @rdname sp_item_copy
#' @name sp_dir_copy
#' @export
sp_dir_copy <- function(
  path,
  new_path,
  ...,
  overwrite = FALSE,
  wait = TRUE,
  drive_name = NULL,
  drive_id = NULL,
  drive = NULL,
  site_url = NULL,
  call = caller_env()
) {
  sp_item_transfer(
    path = path,
    new_path = new_path,
    ...,
    method = "copy",
    type = "directory",
    overwrite = overwrite,
    wait = wait,
    drive_name = drive_name,
    drive_id = drive_id,
    drive = drive,
    site_url = site_url,
    call = call
  )
}

#' @rdname sp_item_copy
#' @name sp_dir_move
#' @export
sp_dir_move <- function(
  path,
  new_path,
  ...,
  drive_name = NULL,
  drive_id = NULL,
  drive = NULL,
  site_url = NULL,
  call = caller_env()
) {
  sp_item_transfer(
    path = path,
    new_path = new_path,
    ...,
    method = "move",
    type = "directory",
    drive_name = drive_name,
    drive_id = drive_id,
    drive = drive,
    site_url = site_url,
    call = call
  )
}

#' Copy or move a set of drive items
#'
#' @param method "copy" or "move".
#' @param type The type of item that `path` must be: "file", "directory", or
#'   "any".
#' @returns Invisibly returns the new path of each item.
#' @noRd
sp_item_transfer <- function(
  path,
  new_path,
  ...,
  method = c("copy", "move"),
  type = c("file", "directory", "any"),
  overwrite = FALSE,
  wait = TRUE,
  drive_name = NULL,
  drive_id = NULL,
  drive = NULL,
  site_url = NULL,
  call = caller_env()
) {
  method <- arg_match(method, error_call = call)
  type <- arg_match(type, error_call = call)
  check_character(new_path, call = call)
  check_bool(overwrite, call = call)
  check_bool(wait, call = call)

  if (anyNA(new_path) || !all(nzchar(new_path))) {
    cli_abort(
      "{.arg new_path} can't contain missing or empty values.",
      call = call
    )
  }

  items <- sp_transfer_items(
    path,
    ...,
    drive_name = drive_name,
    drive_id = drive_id,
    drive = drive,
    site_url = site_url,
    call = call
  )

  new_path <- vctrs::vec_recycle(
    new_path,
    size = length(items),
    x_arg = "new_path",
    call = call
  )

  for (item in items) {
    check_sp_transfer_type(item, type, method, call = call)
  }

  new_paths <- character(length(items))

  for (i in seq_along(items)) {
    dest <- sp_transfer_dest(
      items[[i]],
      new_path[[i]],
      ...,
      replace_dir = overwrite && type == "directory",
      call = call
    )

    sp_transfer_item(
      items[[i]],
      dest,
      method = method,
      overwrite = overwrite,
      wait = wait,
      call = call
    )

    new_paths[[i]] <- dest[["path"]]
  }

  invisible(new_paths)
}

#' Copy or move one drive item to a destination from `sp_transfer_dest()`
#'
#' Graph can't replace a folder, so a folder copied to an existing folder (with
#' `overwrite = TRUE`) is merged into it, like `fs::dir_copy()`.
#' @noRd
sp_transfer_item <- function(
  item,
  dest,
  method = "copy",
  overwrite = FALSE,
  wait = TRUE,
  call = caller_env()
) {
  existing <- NULL

  if (item$is_folder()) {
    existing <- sp_drive_child_props(
      dest[["token"]],
      dest[["drive_id"]],
      dest[["parent_id"]],
      dest[["name"]]
    )
  }

  if (!is.null(existing)) {
    check_sp_folder_conflict(existing, dest, method, overwrite, call = call)
    sp_dir_copy_merge(item, existing, dest, wait = wait, call = call)
    return(invisible(item))
  }

  if (method == "copy") {
    sp_item_copy_to(item, dest, overwrite = overwrite, wait = wait, call = call)
  } else {
    sp_item_move_to(item, dest, overwrite = overwrite, call = call)
  }
}

#' Error if a folder can't be copied or moved to an existing item
#'
#' The only supported case is a copy with `overwrite = TRUE` to an existing
#' folder.
#' @noRd
check_sp_folder_conflict <- function(
  existing,
  dest,
  method = "copy",
  overwrite = FALSE,
  call = caller_env()
) {
  path <- dest[["path"]]

  if (is.null(existing[["folder"]])) {
    cli_abort(
      "Can't {method} a folder to {.val {path}}. A file with that name already
      exists.",
      call = call
    )
  }

  if (method == "move") {
    cli_abort(
      c(
        "Can't move a folder to {.val {path}}. A folder with that name already
        exists.",
        "i" = "SharePoint can't replace a folder with a move. Use a new path,
        or use {.code sp_dir_copy(overwrite = TRUE)} to copy the contents into
        the existing folder and then {.fn delete_sp_item} to delete the
        original folder."
      ),
      call = call
    )
  }

  if (!overwrite) {
    cli_abort(
      c(
        "Can't copy a folder to {.val {path}}. A folder with that name already
        exists.",
        "i" = "Set {.code overwrite = TRUE} to copy the contents into the
        existing folder."
      ),
      call = call
    )
  }

  invisible(NULL)
}

#' Copy the contents of a folder into an existing folder
#'
#' Files replace any files with the same name. Folders are merged with any
#' folders with the same name.
#'
#' @param target The properties of the existing folder.
#' @noRd
sp_dir_copy_merge <- function(
  item,
  target,
  dest,
  wait = TRUE,
  call = caller_env()
) {
  children <- item$list_items(info = "partial", full_names = FALSE)

  for (name in children[["name"]]) {
    child_dest <- list(
      token = dest[["token"]],
      drive_id = dest[["drive_id"]],
      parent_id = target[["id"]],
      name = name,
      path = str_c_path(dest[["path"]], name)
    )

    sp_transfer_item(
      item$get_item(name),
      child_dest,
      method = "copy",
      overwrite = TRUE,
      wait = wait,
      call = call
    )
  }

  invisible(item)
}

#' Get a list of drive items from paths, URLs, or items
#' @noRd
sp_transfer_items <- function(
  path,
  ...,
  drive_name = NULL,
  drive_id = NULL,
  drive = NULL,
  site_url = NULL,
  call = caller_env()
) {
  if (inherits(path, "ms_drive_item")) {
    return(list(path))
  }

  if (is.list(path) && !is.object(path)) {
    for (item in path) {
      check_ms_obj(item, "ms_drive_item", arg = "path", call = call)
    }

    return(path)
  }

  check_character(path, call = call)

  if (anyNA(path) || !all(nzchar(path))) {
    cli_abort("{.arg path} can't contain missing or empty values.", call = call)
  }

  is_path_url <- is_url(path)

  # Get the drive once for any relative paths
  if (!all(is_path_url)) {
    drive <- drive %||%
      get_sp_drive(
        drive_name = drive_name,
        drive_id = drive_id,
        ...,
        properties = FALSE,
        site_url = site_url,
        call = call
      )
  }

  purrr::map2(
    path,
    is_path_url,
    \(x, x_is_url) {
      if (x_is_url) {
        return(get_sp_item(path = x, ..., call = call))
      }

      get_sp_item(path = x, drive = drive, call = call)
    }
  )
}

#' Check that a drive item is a file or a folder
#' @noRd
check_sp_transfer_type <- function(
  item,
  type = "any",
  method = "copy",
  call = caller_env()
) {
  if (type == "any") {
    return(invisible(NULL))
  }

  is_folder <- item$is_folder()
  name <- item[["properties"]][["name"]]

  if (type == "file" && is_folder) {
    cli_abort(
      c(
        "{.arg path} must be a file, not a folder.",
        "i" = "{.val {name}} is a folder. Use {.fn sp_dir_{method}} instead."
      ),
      call = call
    )
  }

  if (type == "directory" && !is_folder) {
    cli_abort(
      c(
        "{.arg path} must be a folder, not a file.",
        "i" = "{.val {name}} is a file. Use {.fn sp_item_{method}} instead."
      ),
      call = call
    )
  }

  invisible(NULL)
}

#' Find the parent folder and name for a copied or moved item
#'
#' Follows the pattern used by `{fs}`: if `new_path` is an existing folder, the
#' item is placed inside it (unless `replace_dir = TRUE`). Otherwise, the
#' parent of `new_path` must be an existing folder.
#'
#' @param replace_dir If `TRUE`, an existing folder at `new_path` is the item
#'   to replace, not the parent folder.
#' @returns A list with `token`, `drive_id`, `parent_id`, `name`, and `path`
#'   (the new path relative to the destination drive).
#' @noRd
sp_transfer_dest <- function(
  item,
  new_path,
  ...,
  replace_dir = FALSE,
  call = caller_env()
) {
  token <- item[["token"]]
  name <- item[["properties"]][["name"]]
  drive_id <- item[["properties"]][["parentReference"]][["driveId"]]

  if (is_url(new_path)) {
    url_parts <- sp_url_parse(new_path, call = call)

    if (!is.null(url_parts[["item_id"]])) {
      cli_abort(
        c(
          "{.arg new_path} can't be a URL with an item ID.",
          "i" = "Use a folder or document library URL instead."
        ),
        call = call
      )
    }

    is_drive_url <- is_sp_drive_url(new_path)
    url_drive_name <- new_path
    if (is_drive_url) {
      url_drive_name <- url_parts[["drive_url"]]
    }

    dest_drive <- get_sp_drive(
      drive_name = url_drive_name,
      ...,
      properties = FALSE,
      call = call
    )

    token <- dest_drive[["token"]]
    drive_id <- dest_drive[["properties"]][["id"]]
    new_path <- url_parts[["file_path"]] %||% ""

    # A library URL or a URL ending in "/" is always the parent folder
    if (is_drive_url) {
      new_path <- paste0(new_path, "/")
    }
  }

  into_folder <- grepl("/$", new_path) || new_path %in% c("", ".", "/")
  new_path <- gsub("^/+|/+$", "", new_path)

  target <- sp_drive_item_props(token, drive_id, new_path)
  target_is_folder <- !is.null(target[["folder"]]) || !is.null(target[["root"]])

  if (into_folder || (target_is_folder && !replace_dir)) {
    if (!target_is_folder) {
      cli_abort(
        "{.arg new_path} must be an existing folder: {.val {new_path}}",
        call = call
      )
    }

    return(list(
      token = token,
      drive_id = drive_id,
      parent_id = target[["id"]],
      name = name,
      path = str_c_path(new_path, name)
    ))
  }

  parent_path <- dirname(new_path)
  if (parent_path == ".") {
    parent_path <- ""
  }

  parent <- sp_drive_item_props(token, drive_id, parent_path)

  if (is.null(parent[["folder"]]) && is.null(parent[["root"]])) {
    cli_abort(
      "The parent folder of {.arg new_path} must exist: {.val {parent_path}}",
      call = call
    )
  }

  list(
    token = token,
    drive_id = drive_id,
    parent_id = parent[["id"]],
    name = basename(new_path),
    path = new_path
  )
}

#' Combine a folder path and a name, dropping an empty folder path
#' @noRd
str_c_path <- function(dir, name) {
  if (!nzchar(dir)) {
    return(name)
  }

  str_c_url(dir, name)
}

#' Get the properties of a drive item by path
#'
#' @param path A path relative to the drive root. Use `""` for the root.
#' @returns A list of item properties, or `NULL` if no item exists at `path`.
#' @noRd
sp_drive_item_props <- function(token, drive_id, path = "") {
  op <- "root"
  if (nzchar(path)) {
    op <- paste0("root:/", utils::URLencode(path, reserved = TRUE))
  }

  tryCatch(
    AzureGraph::call_graph_endpoint(
      token,
      file.path("drives", drive_id, op)
    ),
    http_404 = function(cnd) NULL
  )
}

#' Get the properties of an item in a folder by name
#'
#' @returns A list of item properties, or `NULL` if no item named `name` is in
#'   the folder.
#' @noRd
sp_drive_child_props <- function(token, drive_id, parent_id, name) {
  tryCatch(
    AzureGraph::call_graph_endpoint(
      token,
      file.path(
        "drives",
        drive_id,
        "items",
        paste0(parent_id, ":/", utils::URLencode(name, reserved = TRUE))
      )
    ),
    http_404 = function(cnd) NULL
  )
}

#' Graph `@microsoft.graph.conflictBehavior` option
#' @noRd
sp_conflict_option <- function(overwrite = FALSE) {
  list(
    `@microsoft.graph.conflictBehavior` = if (overwrite) "replace" else "fail"
  )
}

#' Copy a drive item to a destination from `sp_transfer_dest()`
#' @noRd
sp_item_copy_to <- function(
  item,
  dest,
  overwrite = FALSE,
  wait = TRUE,
  call = caller_env()
) {
  resp <- item$do_operation(
    "copy",
    body = list(
      parentReference = list(
        driveId = dest[["drive_id"]],
        id = dest[["parent_id"]]
      ),
      name = dest[["name"]]
    ),
    encode = "json",
    http_verb = "POST",
    options = sp_conflict_option(overwrite),
    http_status_handler = "pass"
  )

  check_sp_transfer_response(resp, item, "copy", overwrite, call = call)

  monitor_url <- httr::headers(resp)[["location"]]

  if (wait && !is.null(monitor_url)) {
    sp_wait_for_copy(monitor_url, item, call = call)
  }

  invisible(item)
}

#' Move a drive item to a destination from `sp_transfer_dest()`
#' @noRd
sp_item_move_to <- function(
  item,
  dest,
  overwrite = FALSE,
  call = caller_env()
) {
  item_drive_id <- item[["properties"]][["parentReference"]][["driveId"]]

  if (!identical(item_drive_id, dest[["drive_id"]])) {
    cli_abort(
      c(
        "Items can only be moved within the same drive.",
        "i" = "Use {.fn sp_item_copy} or {.fn sp_dir_copy} to copy
        {.val {item[['properties']][['name']]}} to another drive instead."
      ),
      call = call
    )
  }

  resp <- item$do_operation(
    body = list(
      parentReference = list(id = dest[["parent_id"]]),
      name = dest[["name"]]
    ),
    encode = "json",
    http_verb = "PATCH",
    options = sp_conflict_option(overwrite),
    http_status_handler = "pass"
  )

  check_sp_transfer_response(resp, item, "move", overwrite, call = call)

  item[["properties"]] <- httr::content(resp)

  invisible(item)
}

#' Error for a failed copy or move request
#' @noRd
check_sp_transfer_response <- function(
  resp,
  item,
  method = "copy",
  overwrite = FALSE,
  call = caller_env()
) {
  if (!httr::http_error(resp)) {
    return(invisible(NULL))
  }

  message <- httr::content(resp)[["error"]][["message"]] %||%
    httr::http_status(resp)[["message"]]

  cli_abort(
    c(
      "Can't {method} {.val {item[['properties']][['name']]}}.",
      "x" = message,
      "i" = if (
        method %in% c("copy", "move") &&
          !overwrite &&
          httr::status_code(resp) == 409
      ) {
        "Set {.code overwrite = TRUE} to replace an existing item."
      }
    ),
    call = call
  )
}

#' Wait for an asynchronous copy to finish
#'
#' The monitor URL doesn't need authentication. It returns a status of
#' "notStarted", "inProgress", "completed", or "failed". Some services
#' redirect to the new item once the copy is complete, so redirects aren't
#' followed.
#'
#' @param timeout Maximum number of seconds to wait. Defaults to the
#'   "sharepointr.copy_timeout" option or 300.
#' @noRd
sp_wait_for_copy <- function(
  monitor_url,
  item,
  timeout = getOption("sharepointr.copy_timeout", 300),
  call = caller_env()
) {
  name <- item[["properties"]][["name"]]
  start <- Sys.time()
  delay <- 0.5

  repeat {
    resp <- httr::GET(monitor_url, httr::config(followlocation = 0L))

    if (httr::status_code(resp) %in% c(302, 303)) {
      return(invisible(TRUE))
    }

    status <- httr::content(resp)

    if (identical(status[["status"]], "completed")) {
      return(invisible(TRUE))
    }

    if (identical(status[["status"]], "failed") || httr::http_error(resp)) {
      is_conflict <- identical(status[["error"]][["code"]], "nameAlreadyExists")
      message <- status[["error"]][["message"]] %||%
        status[["errorCode"]] %||%
        httr::http_status(resp)[["message"]]

      cli_abort(
        c(
          "Can't copy {.val {name}}.",
          "x" = message,
          "i" = if (is_conflict) {
            "Set {.code overwrite = TRUE} to replace an existing item."
          }
        ),
        call = call
      )
    }

    elapsed <- as.numeric(difftime(Sys.time(), start, units = "secs"))

    if (elapsed > timeout) {
      cli_abort(
        c(
          "Copy of {.val {name}} didn't finish within {timeout} seconds.",
          "i" = "The copy may still be running. Set
          {.code options(sharepointr.copy_timeout)} to wait longer."
        ),
        call = call
      )
    }

    Sys.sleep(delay)
    delay <- min(delay * 2, 5)
  }
}

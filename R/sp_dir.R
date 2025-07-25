#' List SharePoint files and folders
#'
#' @description
#'
#' [sp_dir_info()] is a wrapper for the `list_files` method with some additional
#' features based on [fs::dir_info()]. [sp_dir_ls()] returns a character vector
#' and does not yet include support for the `recurse` argument.  If
#' `{fs}` is installed, the size column is formatted using [fs::as_fs_bytes()]
#' and an additional "type" factor column is added with values for directory and
#' file.
#'
#' @param path Path to directory or folder. SharePoint folder URLs are allowed.
#'   If `NULL`, path is set to default "/". `path` can be a string or a
#'   character vector. If a vector or path of URLs are supplied, provide a
#'   `drive` object to improve performance.
#' @param info The information to return: "partial", "name" or "all". If
#'   "partial", a data frame is returned containing the name, size, ID and
#'   whether the item is a file or folder. If "all", a data frame is returned
#'   containing all the properties for each item (this can be large).
#' @param full_names If `TRUE` (default), return the full file path as the name
#'   for each item.
#' @param pagesize Maximum number of items to return. Defaults to 1000. Decrease
#'   if you are experiencing timeouts.
#' @param recurse If `TRUE`, get info for each directory at the supplied path
#'   and combine this info with the item info for the supplied path.
#' @param type Type of item to return. Can be "any", "file", or "directory".
#'   "directory" is not a supported option for [sp_dir_ls()]
#' @param regexp Regular expression passed to `grep()` and used to filter the
#'   paths before they are returned.
#' @inheritDotParams get_sp_drive -drive_name -drive_id -properties
#' @inheritParams base::grep
#' @inheritParams get_sp_drive
#' @inheritParams get_sp_item
#' @examples
#' dir_url <- "<link to SharePoint directory or drive>"
#'
#' if (is_sp_url(dir_url)) {
#'   sp_dir_info(
#'     path = dir_url
#'   )
#'
#'   sp_dir_ls(
#'     path = dir_url
#'   )
#' }
#'
#' @export
#' @keywords files
#' @importFrom vctrs vec_slice vec_rbind
sp_dir_info <- function(
  path = NULL,
  ...,
  info = "partial",
  full_names = TRUE,
  pagesize = 1000,
  drive_name = NULL,
  drive_id = NULL,
  drive = NULL,
  recurse = FALSE,
  type = "any",
  regexp = NULL,
  invert = FALSE,
  perl = FALSE,
  call = caller_env()
) {
  # Handle a vector of paths
  if (is.character(path) && length(path) > 1) {
    dir_info_list <- purrr::map(
      path,
      \(x) {
        sp_dir_info(
          path = x,
          # TODO: Consider dropping ... to allow parallelization
          ...,
          info = info,
          full_names = full_names,
          pagesize = pagesize,
          drive_name = drive_name,
          drive_id = drive_id,
          # TODO: Add a warning re: performance issues if `drive = NULL`
          drive = drive,
          recurse = recurse,
          type = type,
          regexp = regexp,
          invert = invert,
          perl = perl,
          call = call
        )
      }
    )

    return(vctrs::vec_rbind(!!!dir_info_list, .error_call = call))
  }

  url_parts <- NULL
  if (!is.null(path) && is_sp_url(path)) {
    url <- path
    url_parts <- sp_url_parse(url, call = call)

    # Handle for drive URLs that end in "Forms/AllItems.aspx"
    if (is_sp_drive_url(path)) {
      drive_name <- url_parts[["drive_url"]]
    } else {
      drive_name <- path
    }

    path <- str_remove_slash(url_parts[["file_path"]], before = TRUE)
  }

  drive <- drive %||%
    get_sp_drive(
      drive_name = drive_name,
      drive_id = drive_id,
      ...,
      properties = FALSE,
      call = call
    )

  check_ms_drive(drive, call = call)

  if (path == "") {
    path <- NULL
  }

  path <- path %||% "/"

  info <- arg_match(info, values = c("partial", "name", "all"), call = call)

  type <- arg_match(type, c("any", "file", "directory"), error_call = call)

  return_type <- NULL

  if (recurse && (type == "file")) {
    cli::cli_alert_warning(
      "{.arg type} is always set to {.val {any}} if {.code recurse = TRUE}"
    )
    type <- "any"
  }

  if (type == "file") {
    item_list <- drive$list_files(
      path = path,
      info = info,
      full_names = full_names,
      pagesize = pagesize
    )
  } else {
    item_list <- drive$list_items(
      path = path,
      info = info,
      full_names = full_names,
      pagesize = pagesize
    )
  }

  if (!is.null(regexp)) {
    path_name <- item_list
    if (is.data.frame(item_list)) {
      path_name <- item_list[["name"]]
    }

    item_list <- vctrs::vec_slice(
      item_list,
      i = grep(regexp, path_name, perl = perl, invert = invert),
      error_call = call
    )
  }

  if (!is.data.frame(item_list)) {
    return(item_list)
  }

  item_list <- switch(
    type,
    any = item_list,
    file = item_list[!item_list[["isdir"]], ],
    directory = item_list[item_list[["isdir"]], ]
  )

  if (is_installed("fs")) {
    item_list[["size"]] <- vec_fmt_sp_item_size(item_list[["size"]])

    item_list[["type"]] <- factor(
      vapply(
        item_list[["isdir"]],
        function(x) {
          if (x) {
            return("directory")
          }
          "file"
        },
        NA_character_
      ),
      levels = c("directory", "file")
    )
  }

  if (full_names && FALSE) {
    # FIXME: This is disabled since the resulting item URL values do not match
    # the native item webURL values
    item_list <- vctrs::vec_cbind(
      item_list,
      data.frame(
        list(
          "item_url" = paste0(
            drive[["properties"]][["webUrl"]],
            item_list[["name"]]
          )
        )
      )
    )
  }

  if (!recurse || (type == "file") || !any(item_list[["isdir"]])) {
    return(item_list)
  }

  dir_list <- item_list[item_list[["isdir"]], ]

  dir_name <- dir_list[["name"]]

  if (full_names) {
    dir_name <- str_remove_slash(dir_name, before = TRUE)
  }

  dir_item_list <- purrr::map(
    cli::cli_progress_along(dir_name),
    function(i) {
      sp_dir_info(
        path = dir_name[[i]],
        drive = drive,
        info = info,
        full_names = full_names,
        pagesize = pagesize,
        recurse = recurse,
        type = type,
        regexp = regexp,
        call = call
      )
    }
  )

  dir_item_list <- c(list(item_list), dir_item_list)

  vctrs::vec_rbind(!!!dir_item_list, .error_call = call)
}

#' @noRd
vec_fmt_sp_item_size <- function(x) {
  fs::as_fs_bytes(as.double(x))
}

#' @noRd
fmt_sp_item_size <- function(data, size_col = "size") {
  data[[size_col]] <- vec_fmt_sp_item_size(data[[size_col]])

  data
}

#' @rdname sp_dir_info
#' @name sp_dir_ls
#' @export
sp_dir_ls <- function(
  path = NULL,
  ...,
  full_names = FALSE,
  pagesize = 1000,
  drive_name = NULL,
  drive_id = NULL,
  drive = NULL,
  type = "any",
  regexp = NULL,
  invert = FALSE,
  perl = FALSE,
  call = caller_env()
) {
  params <- rlang::list2(...)

  if (has_name(params, "info")) {
    cli_abort(
      c(
        "{.arg info} can't be used with {.fn sp_dir_ls}.",
        "*" = "Use {.fn sp_dir_info} instead to set the value for {.arg info}."
      ),
      call = call
    )
  }

  sp_dir_info(
    path = path,
    ...,
    info = "name",
    full_names = full_names,
    pagesize = pagesize,
    drive_name = drive_name,
    drive_id = drive_id,
    drive = drive,
    type = type,
    regexp = regexp,
    invert = invert,
    perl = perl,
    call = call
  )
}

#' Create SharePoint folders
#'
#' [sp_dir_create()] is a wrapper for the `create_folder` method that handles
#' character vectors. If `drive_name` is a folder URL and `relative` is `TRUE`,
#' the values for `path` are appended to the file path parsed from the url.
#'
#' @param path A character vector of one or more paths.
#' @inheritParams get_sp_drive
#' @inheritParams get_sp_item
#' @param relative If `TRUE` and `drive_name` is a folder URL, the values for
#'   `path` are appended to the file path parsed from the url. If `relative` is
#'   a character vector, it must be length 1 or the same length as path and
#'   appended to path as a vector of parent directories. The second option takes
#'   precedence over any file path parsed from the url.
#' @inheritDotParams get_sp_drive -drive_name -drive_id -properties
#' @examples
#' drive_url <- "<link to SharePoint drive>"
#'
#' if (is_sp_url(drive_url)) {
#'   sp_dir_create(
#'     path = "parent_folder/subfolder",
#'     drive_name = drive_url
#'   )
#'
#'   sp_dir_create(
#'     path = c("subfolder1", "subfolder2", "subfolder3"),
#'     relative = "parent_folder",
#'     drive_name = drive_url
#'   )
#' }
#'
#' dir_url <- "<link to SharePoint directory>"
#'
#' if (is_sp_url(dir_url)) {
#'   sp_dir_create(
#'     path = c("subfolder1", "subfolder2", "subfolder3"),
#'     drive_name = dir_url,
#'     relative = TRUE
#'   )
#' }
#'
#' @keywords files
#' @export
#' @importFrom vctrs vec_recycle
#' @importFrom cli cli_progress_along cli_warn cli_progress_done
sp_dir_create <- function(
  path,
  ...,
  drive_name = NULL,
  drive_id = NULL,
  drive = NULL,
  relative = FALSE,
  call = caller_env()
) {
  drive <- drive %||%
    get_sp_drive(
      drive_name = drive_name,
      drive_id = drive_id,
      ...,
      properties = FALSE,
      call = call
    )

  if (is_true(relative) || is_character(relative)) {
    if (!is_character(relative) && is_sp_folder_url(drive_name)) {
      relative <- str_remove_slash(sp_url_parse(drive_name)[["file_path"]])
    }

    relative <- vctrs::vec_recycle(
      relative,
      size = length(path),
      x_arg = "relative",
      call = call
    )

    path <- str_c_url(relative, path)
  }

  purrr::walk(
    cli::cli_progress_along(path),
    \(i) {
      withCallingHandlers(
        drive$create_folder(path = path[[i]]),
        error = function(cnd) {
          cli::cli_warn(
            cnd$message
          )
        }
      )
    }
  )

  cli::cli_progress_done()

  invisible(path)
}

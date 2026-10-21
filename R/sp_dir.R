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
#'   `drive` object to improve performance. If `path` is a SharePoint folder or
#'   document library URL and `drive_name`, `drive_id`, and `drive` aren't
#'   supplied, the drive and folder are found with the [Microsoft Graph shares
#'   API](https://learn.microsoft.com/en-us/graph/api/shares-get) (see
#'   [get_sp_item()]). If the request fails, the drive and folder path are
#'   parsed from the URL instead.
#' @param info The information to return: "partial", "name" or "all". If
#'   "partial", a data frame is returned containing the name, size, ID and
#'   whether the item is a file or folder. If "all", a data frame is returned
#'   containing all the properties for each item (this can be large).
#' @param full_names If `TRUE` (default), return the full file path as the name
#'   for each item.
#' @param pagesize Maximum number of items to return. Defaults to 1000. Decrease
#'   if you are experiencing timeouts.
#' @param recurse If `TRUE`, get info for each directory at the supplied path
#'   and combine this info with the item info for the supplied path. Directories
#'   are listed one level at a time and a single progress bar reports the
#'   number of directories listed and queued.
#' @param sort How to sort the result: "name-asc" (default), "name-desc",
#'   "size-asc", "size-desc", "created-asc", "created-desc", "modified-asc",
#'   "modified-desc", or "none" to keep the order that directories were listed
#'   in. Names are sorted in C-locale order so uppercase letters sort before
#'   lowercase letters. Sorting by "created" or "modified" requires
#'   `info = "all"` because the creation and modification times are not
#'   included in the "partial" info. `sort` is applied if `recurse = TRUE` or if
#'   `sort` is supplied; otherwise the order returned by SharePoint is kept.
#' @param type Type of item to return. Can be "any", "file", or "directory".
#'   "directory" is not a supported option for [sp_dir_ls()]. As with
#'   [fs::dir_info()], if `recurse = TRUE`, all directories are searched
#'   whatever the value of `type`, and `type` only filters the items returned.
#' @param regexp Regular expression passed to `grep()` and used to filter the
#'   items before they are returned. As with [fs::dir_info()], `regexp` is
#'   applied after all directories are listed, so directories that do not match
#'   are still searched if `recurse = TRUE`. If `full_names = TRUE`, `regexp`
#'   is matched against the full path. If `full_names = FALSE`, it is matched
#'   against the item name only (unlike [fs::dir_info()]).
#' @inheritDotParams get_sp_drive -drive_name -drive_id -properties
#' @inheritParams base::grep
#' @inheritParams get_sp_drive
#' @inheritParams get_sp_item
#' @returns For [sp_dir_info()], a data frame with one row per file or folder
#'   at `path`, with columns determined by `info` (`"partial"`, `"name"`, or
#'   `"all"`). For [sp_dir_ls()], a character vector of file and folder
#'   names or paths.
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
  sort = "name-asc",
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
          sort = sort,
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

  # Use the Graph shares API to get the drive and folder path from the URL. If
  # the request fails, fall back to the drive and path parsed from the URL.
  if (!is.null(path) && is_sp_url(path)) {
    folder <- sp_url_get_folder(
      path,
      ...,
      shares = is.null(c(drive_name, drive_id)) && is.null(drive),
      call = call
    )

    drive <- drive %||% folder[["drive"]]
    drive_name <- folder[["drive_name"]]
    path <- folder[["path"]]
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

  # TODO: Check if removing this and replacing "/" w/ "" breaks anything
  path <- path %||% ""

  info <- arg_match(
    info,
    values = c("partial", "name", "all"),
    error_call = call
  )

  type <- arg_match(type, c("any", "file", "directory"), error_call = call)

  sort_values <- c(
    "name-asc",
    "name-desc",
    "size-asc",
    "size-desc",
    "created-asc",
    "created-desc",
    "modified-asc",
    "modified-desc",
    "none"
  )
  # Sort the default order for recursive results but not for a single directory
  sort_items <- recurse || !missing(sort)
  sort <- arg_match(sort, sort_values, error_call = call)

  return_type <- NULL

  # TODO: Consider adding other fs::dir_info() arguments and options:
  # - `all` to include hidden files
  # - `glob` as an alternative to `regexp`
  # - `fail` to warn instead of error if a directory can't be listed
  # - more `type` values (e.g. "symlink") if they can be identified
  # - matching `regexp` against the full path if `full_names = FALSE`

  # Remove leading slash
  path <- str_remove_slash(path)

  # List directories level by level (breadth-first) so that a single progress
  # bar can track the whole tree
  pending <- path
  item_lists <- list()
  n_dirs <- 0L
  n_items <- 0L

  if (recurse) {
    cli::cli_progress_bar(
      format = paste0(
        "{cli::pb_spin} Listing directories: {n_dirs} listed, ",
        "{n_queued} queued, {n_items} items found"
      ),
      format_done = "Listed {n_dirs} directories ({n_items} items)",
      total = NA
    )
  }

  while (length(pending) > 0) {
    next_pending <- character()

    for (i in seq_along(pending)) {
      item_list <- sp_dir_list_items(
        path = pending[[i]],
        drive = drive,
        info = info,
        full_names = full_names,
        pagesize = pagesize
      )

      item_lists[[length(item_lists) + 1L]] <- item_list
      n_dirs <- n_dirs + 1L

      if (is.data.frame(item_list)) {
        n_items <- n_items + nrow(item_list)

        if (recurse && any(item_list[["isdir"]])) {
          next_pending <- c(
            next_pending,
            sp_dir_child_paths(
              item_list[item_list[["isdir"]], ][["name"]],
              parent = pending[[i]],
              full_names = full_names
            )
          )
        }
      }

      if (recurse) {
        n_queued <- length(pending) - i + length(next_pending)
        cli::cli_progress_update()
      }
    }

    pending <- next_pending
  }

  if (!is.data.frame(item_lists[[1]])) {
    item_list <- item_lists[[1]]
  } else {
    item_list <- vctrs::vec_rbind(!!!item_lists, .error_call = call)
  }

  # Filter after traversal so that directories that don't match `regexp` are
  # still searched for matching items
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

  if (sort_items && (sort != "none")) {
    item_list <- sp_dir_sort(item_list, sort, call = call)
  }

  if (is_installed("fs")) {
    item_list <- fmt_sp_item_size(item_list, "size")

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

  item_list
}

#' Sort a data frame of directory items
#'
#' @param sort A string with the sort column and direction, e.g. "name-asc".
#' @noRd
sp_dir_sort <- function(data, sort, call = caller_env()) {
  sort <- strsplit(sort, "-", fixed = TRUE)[[1]]

  col <- switch(
    sort[[1]],
    name = "name",
    size = "size",
    created = "createdDateTime",
    modified = "lastModifiedDateTime"
  )

  if (!has_name(data, col)) {
    cli_abort(
      c(
        "Can't sort by {.val {sort[[1]]}}.",
        "i" = "Use {.code info = \"all\"} to include {.field {col}}."
      ),
      call = call
    )
  }

  vctrs::vec_slice(
    data,
    vctrs::vec_order(as.vector(data[[col]]), direction = sort[[2]])
  )
}

#' List the items in a single directory
#'
#' @returns A data frame or, if `info = "name"`, a character vector.
#' @noRd
sp_dir_list_items <- function(path, drive, info, full_names, pagesize) {
  drive$list_items(
    path = path,
    info = info,
    full_names = full_names,
    pagesize = pagesize
  )
}

#' Get the paths to the subdirectories of `parent`
#'
#' If `full_names` is `FALSE`, `name` is relative to `parent`.
#' @noRd
sp_dir_child_paths <- function(name, parent, full_names) {
  if (full_names) {
    return(str_remove_slash(name, before = TRUE))
  }

  if (parent == "") {
    return(name)
  }

  paste(parent, name, sep = "/")
}

#' @returns An `fs_bytes` vector.
#' @noRd
vec_fmt_sp_item_size <- function(x) {
  fs::as_fs_bytes(as.double(x))
}

#' @returns `data` with `size_col` converted to an `fs_bytes` vector.
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
#' @returns Invisibly returns the input `path` (or `path` combined with
#'   `relative` if supplied).
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

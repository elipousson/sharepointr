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
#' @param select A character vector of [driveItem
#'   properties](https://learn.microsoft.com/en-us/graph/api/resources/driveitem)
#'   to return in addition to the name, size, ID, and `isdir` columns, e.g.
#'   `c("webUrl", "lastModifiedDateTime")`. Passed to the Graph API as the
#'   `$select` query parameter so only these properties are requested. If
#'   supplied, `info` must be "partial" (the default) or "all" and "all" is
#'   treated as "partial". Properties used by `sort` are always included.
#' @param full_names If `TRUE` (default), return the full file path as the name
#'   for each item.
#' @param pagesize Maximum number of items to return. Defaults to 1000. Decrease
#'   if you are experiencing timeouts.
#' @param recurse If `TRUE`, get info for each directory at the supplied path
#'   and combine this info with the item info for the supplied path. Directories
#'   are listed one level at a time and a single progress bar reports the
#'   number of directories listed and queued.
#' @param .batch If `TRUE` (default), the directories at each level of a
#'   recursive listing are requested with Microsoft Graph
#'   [$batch](https://learn.microsoft.com/en-us/graph/json-batching) requests
#'   (up to 20 directories per request), which is much faster than a request
#'   per directory. Use `.batch = FALSE` or `options(sharepointr.batch = FALSE)`
#'   to send a request per directory.
#' @param sort How to sort the result: "name-asc" (default), "name-desc",
#'   "size-asc", "size-desc", "created-asc", "created-desc", "modified-asc",
#'   "modified-desc", or "none" to keep the order that directories were listed
#'   in. Names are sorted in C-locale order so uppercase letters sort before
#'   lowercase letters. `sort` is ignored if `info = "name"`. The properties used by `sort` are added to the
#'   result if they are not already included. `sort` is applied if
#'   `recurse = TRUE` or if `sort` is supplied; otherwise the order returned by
#'   SharePoint is kept.
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
  select = NULL,
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
  .batch = getOption("sharepointr.batch", TRUE),
  call = caller_env()
) {
  check_bool(.batch, call = call)

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
          select = select,
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
          .batch = .batch,
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

  check_character(select, allow_null = TRUE, call = call)

  if (info == "name" && !is.null(select)) {
    cli_abort(
      "{.arg select} can't be used with {.code info = \"name\"}.",
      call = call
    )
  }

  # Request the properties needed to sort so the sort column can be returned
  sort_items <- sort_items && (sort != "none")
  if (sort_items && (info == "partial" || !is.null(select))) {
    select <- union(select, sp_dir_sort_cols(sort)[["select"]])
  }

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

    # Request up to 20 directories at a time if batching so the progress bar is
    # updated after each $batch request
    chunk_size <- if (.batch) sp_batch_size else 1L
    chunks <- unname(split(
      seq_along(pending),
      ceiling(seq_along(pending) / chunk_size)
    ))

    for (idx in chunks) {
      chunk_lists <- sp_dir_list_items_chunk(
        paths = pending[idx],
        drive = drive,
        info = info,
        select = select,
        full_names = full_names,
        pagesize = pagesize,
        call = call
      )

      for (j in seq_along(idx)) {
        item_list <- chunk_lists[[j]]
        item_lists[[length(item_lists) + 1L]] <- item_list
        n_dirs <- n_dirs + 1L

        if (is.data.frame(item_list)) {
          n_items <- n_items + nrow(item_list)

          if (recurse && any(item_list[["isdir"]])) {
            next_pending <- c(
              next_pending,
              sp_dir_child_paths(
                item_list[item_list[["isdir"]], ][["name"]],
                parent = pending[[idx[[j]]]],
                full_names = full_names
              )
            )
          }
        }
      }

      if (recurse) {
        n_queued <- length(pending) - max(idx) + length(next_pending)
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

  if (sort_items) {
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
  cols <- sp_dir_sort_cols(sort)

  if (!has_name(data, cols[["col"]])) {
    cli_abort(
      "Can't sort by {.val {cols[['col']]}}: the column is missing.",
      call = call
    )
  }

  vctrs::vec_slice(
    data,
    vctrs::vec_order(
      as.vector(data[[cols[["col"]]]]),
      direction = cols[["direction"]]
    )
  )
}

#' @returns A list with the sort column, the Graph property to `$select`
#'   (`NULL` for name and size, which are always requested), and the direction.
#' @noRd
sp_dir_sort_cols <- function(sort) {
  sort <- strsplit(sort, "-", fixed = TRUE)[[1]]

  col <- switch(
    sort[[1]],
    name = "name",
    size = "size",
    created = "createdDateTime",
    modified = "lastModifiedDateTime"
  )

  list(
    col = col,
    select = if (!(col %in% c("name", "size"))) col,
    direction = sort[[2]]
  )
}

#' List the items in a single directory
#'
#' Wraps the Graph API `children` endpoint directly (instead of the
#' Microsoft365R `list_items` method) so `select` can limit the properties
#' requested.
#'
#' Based on the `list_files` method of `Microsoft365R::ms_drive_item` (also
#' used by `ms_drive$list_items()`). The `isdir` column, empty result, and
#' `full_names` handling follow that method, except that names in the drive
#' root have no leading slash.
#'
#' @param select Additional driveItem properties to request. Ignored if `info`
#'   is "name". If `info = "all"` and `select` is `NULL`, all properties are
#'   requested.
#' @returns A data frame with name, size, isdir, and ID columns followed by any
#'   other columns or, if `info = "name"`, a character vector.
#' @noRd
sp_dir_list_items <- function(
  path,
  drive,
  info,
  select = NULL,
  full_names = FALSE,
  pagesize = 1000
) {
  items <- sp_dir_request_items(
    drive = drive,
    path = path,
    select = sp_dir_select_fields(info, select),
    pagesize = pagesize
  )

  sp_dir_shape_items(items, path, info, select, full_names)
}

#' @returns A character vector of properties to `$select` or `NULL` to request
#'   every property.
#' @noRd
sp_dir_select_fields <- function(info, select = NULL) {
  base_cols <- c("name", "size", "folder", "id")

  switch(
    info,
    name = "name",
    partial = union(base_cols, select),
    all = if (!is.null(select)) union(base_cols, select)
  )
}

#' Format the items returned for a directory
#' @param items A data frame of driveItem properties or `NULL`.
#' @inheritParams sp_dir_list_items
#' @noRd
sp_dir_shape_items <- function(items, path, info, select, full_names) {
  if (is.null(items) || nrow(items) == 0) {
    if (info == "name") {
      return(character())
    }

    items <- data.frame(
      name = character(),
      size = numeric(),
      folder = I(list()),
      id = character()
    )
  }

  if (full_names) {
    # Unlike Microsoft365R, names in the drive root have no leading slash
    path <- sub("^/", "", path)
    if (path != "") {
      items[["name"]] <- file.path(path, items[["name"]])
    }
  }

  if (info == "name") {
    return(items[["name"]])
  }

  items[["isdir"]] <- rep(FALSE, nrow(items))
  if (is.data.frame(items[["folder"]])) {
    items[["isdir"]] <- !is.na(items[["folder"]][["childCount"]])
  }

  if (!is.null(select) || info == "partial") {
    # Drop the `@odata` columns and `folder` unless requested
    items <- items[!startsWith(names(items), "@")]
    if (!("folder" %in% select)) {
      items[["folder"]] <- NULL
    }
  }

  first_cols <- c("name", "size", "isdir", "id")
  items[c(first_cols, setdiff(names(items), first_cols))]
}

#' List the items in one or more directories
#'
#' Lists a single directory with `sp_dir_list_items()`. Lists more than one
#' directory with a single Graph `$batch` request (see
#' `sp_graph_batch_requests()`).
#' @param paths A character vector of up to 20 paths.
#' @returns A list with one element for each path (see `sp_dir_list_items()`).
#' @noRd
sp_dir_list_items_chunk <- function(
  paths,
  drive,
  info,
  select = NULL,
  full_names = FALSE,
  pagesize = 1000,
  call = caller_env()
) {
  if (length(paths) == 1) {
    return(list(sp_dir_list_items(
      path = paths,
      drive = drive,
      info = info,
      select = select,
      full_names = full_names,
      pagesize = pagesize
    )))
  }

  fields <- sp_dir_select_fields(info, select)

  responses <- sp_graph_batch_requests(
    drive[["token"]],
    purrr::map(
      paths,
      \(x) sp_dir_children_request(drive, x, fields, pagesize)
    ),
    .progress = FALSE,
    call = call
  )

  purrr::map2(
    responses,
    paths,
    \(response, path) {
      items <- sp_dir_batch_items(response, drive[["token"]], path, call = call)
      sp_dir_shape_items(items, path, info, select, full_names)
    }
  )
}

#' Build a $batch request for the children of a drive folder
#'
#' Uses the same `$top` and `$select` options as `sp_dir_request_items()`.
#' @returns A request list with `method` and `url`.
#' @noRd
sp_dir_children_request <- function(drive, path, select = NULL, pagesize = 1000) {
  query <- paste0("$top=", pagesize)

  if (!is.null(select)) {
    query <- paste0(query, "&$select=", paste(select, collapse = ","))
  }

  list(
    method = "GET",
    url = paste0(
      "/drives/",
      drive[["properties"]][["id"]],
      "/",
      sp_dir_children_op(path),
      "?",
      query
    )
  )
}

#' Get the items from a $batch response for a folder
#'
#' Follows `@odata.nextLink` to request any remaining pages (if a folder has
#' more items than `pagesize`).
#' @param response A response from `sp_graph_batch_requests()`.
#' @returns A data frame of driveItem properties or `NULL` if there are no
#'   items.
#' @noRd
sp_dir_batch_items <- function(response, token, path, call = caller_env()) {
  status <- as.integer(response[["status"]])

  if (status >= 300) {
    cli_abort(
      c(
        "Can't list {.path {path}} (HTTP {status}).",
        "x" = response[["body"]][["error"]][["message"]]
      ),
      call = call
    )
  }

  body <- response[["body"]]
  items <- sp_dir_parse_items(body[["value"]])
  next_link <- body[["@odata.nextLink"]]

  while (is_string(next_link)) {
    page <- AzureGraph::call_graph_url(token, next_link, simplify = TRUE)
    items <- vctrs::vec_rbind(items, page[["value"]])
    next_link <- page[["@odata.nextLink"]]
  }

  items
}

#' Convert a list of driveItems to the data frame returned by
#' `simplify = TRUE`
#' @noRd
sp_dir_parse_items <- function(value) {
  if (length(value) == 0) {
    return(NULL)
  }

  jsonlite::fromJSON(
    jsonlite::toJSON(value, auto_unbox = TRUE, null = "null"),
    simplifyVector = TRUE
  )
}

#' Request the children of a drive folder
#'
#' This function is the only request made by `sp_dir_list_items()`.
#'
#' Based on the request and paging steps in the `list_files` method of
#' `Microsoft365R::ms_drive_item`, which uses `$select` and `$top` options with
#' `get_list_pager()` and `extract_list_values()`. Results are combined with
#' `.sp_extract_list_values()`.
#'
#' @param select Character vector of properties to request or `NULL` to request
#'   every property.
#' @returns A data frame of driveItem properties or `NULL` if there are no
#'   items.
#' @noRd
sp_dir_request_items <- function(drive, path, select = NULL, pagesize = 1000) {
  options <- list(`$top` = pagesize)

  if (!is.null(select)) {
    options[["$select"]] <- paste(select, collapse = ",")
  }

  # simplify = TRUE is required or the first page is skipped by the pager
  resp <- drive$do_operation(
    sp_dir_children_op(path),
    options = options,
    simplify = TRUE
  )

  .sp_extract_list_values(drive$get_list_pager(resp), n = Inf, simplify = TRUE)
}

#' Get the Graph operation for the children of a path relative to drive root
#'
#' Each path segment is URL-encoded (including reserved characters such as `#`
#' and `?`).
#'
#' Based on the `make_absolute_path_from_root()` private method of
#' `Microsoft365R::ms_drive_item`, which builds a `root:/path` operation with
#' `utils::URLencode()`. That method does not encode reserved characters, and
#' `list_files` appends `/children`.
#' @noRd
sp_dir_children_op <- function(path) {
  path <- gsub("^/+|/+$", "", path)

  if (path == "") {
    return("root/children")
  }

  segments <- strsplit(path, "/", fixed = TRUE)[[1]]
  segments <- vapply(
    segments,
    \(x) utils::URLencode(enc2utf8(x), reserved = TRUE),
    NA_character_,
    USE.NAMES = FALSE
  )

  paste0("root:/", paste(segments, collapse = "/"), ":/children")
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

  if (has_name(params, "select")) {
    cli_abort(
      "{.arg select} can't be used with {.fn sp_dir_ls}.",
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

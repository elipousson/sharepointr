#' List, get, and download versions of a SharePoint item
#'
#' [list_sp_item_versions()] lists the versions of a SharePoint file (a
#' `driveItem`) and when and by whom they were saved, which makes it possible to
#' check the recent edit history of a file such as an Excel workbook.
#' [get_sp_item_version()] returns a single version, and
#' [download_sp_item_version()] saves the content of a past version of the file.
#'
#' These functions use the `do_operation` method for a `ms_drive_item` object
#' directly. The intent is to add comparable methods back to the Microsoft365R
#' package which may include changes to the functionality and output of these
#' functions.
#'
#' Versions are only available if versioning is enabled for the document
#' library (the default for SharePoint). The Graph API doesn't document the order
#' it returns versions in. In testing with 60 files, it always returned
#' versions from newest to oldest, so `n` is sent to the API as `$top` to limit
#' the size of the response for files with many versions and returns the
#' newest versions. The versions that are returned are sorted by last modified
#' time. The API does not support filtering versions by date, so if
#' `modified_between` is used, all versions are requested and `n` is applied
#' afterward. SharePoint may combine edits made close together into a single
#' version.
#'
#' @section Version IDs:
#' Version IDs (e.g. `"3.0"`) are only unique within a single item. Use
#' `item_cols = "id"` (the default) to keep the item ID alongside the version
#' ID if you combine the results for more than one item.
#'
#' See the Microsoft Graph documentation for
#' [listing versions](https://learn.microsoft.com/en-us/graph/api/driveitem-list-versions)
#' and the
#' [driveItemVersion resource](https://learn.microsoft.com/en-us/graph/api/resources/driveitemversion).
#'
#' @inheritDotParams get_sp_item
#' @param sp_item A `ms_drive_item` object for a SharePoint file. Additional
#'   parameters passed to `...` are ignored if `sp_item` is supplied.
#' @param n Maximum number of versions to return, starting with the newest
#'   (latest). Defaults to `NULL` (all versions). Applied after
#'   `modified_between`.
#' @param modified_between A length 2 vector of dates or date-times with the
#'   start and end of the period to return versions for (inclusive, as in
#'   `dplyr::between()`). Use `NA` for an open start or end. A `Date` end
#'   includes that whole day. Character values are parsed as UTC. If the
#'   lubridate package is installed, a [lubridate::interval()] is also
#'   accepted.
#' @param item_cols Item columns to add to the returned data frame: `"id"`
#'   (default) adds `item_id` and `drive_id`, `"summary"` also adds `item_name`
#'   and `item_web_url`, and `"none"` adds no item columns.
#' @param version_cols Version columns to return: `"properties"` (default)
#'   returns `version_id`, `version`, `last_modified`, `last_modified_by`,
#'   `last_modified_by_email`, `last_modified_by_id`, and `size` and `"all"`
#'   also returns everything else the API provides, including `download_url`.
#'   The download URL includes a short-lived access token so is not returned
#'   by default. Column names use snake case (unlike the Graph API property
#'   names that [sp_dir_info()] returns).
#' @param as_data_frame If `TRUE` (default), return a data frame. If `FALSE`,
#'   return the response from the API as a list.
#' @inheritParams rlang::args_error_context
#' @keywords items
#' @returns For [list_sp_item_versions()], a data frame with one row for each
#'   version (newest first) if `as_data_frame = TRUE` or a list with the
#'   versions in `value` otherwise. For [get_sp_item_version()], a one row data
#'   frame or a list. For [download_sp_item_version()], the path to the
#'   downloaded file (invisibly).
#' @examples
#' \dontrun{
#' # List the five most recent versions of a file
#' list_sp_item_versions(item_url = "<SharePoint file URL>", n = 5)
#'
#' # Versions saved in October 2026
#' list_sp_item_versions(
#'   item_url = "<SharePoint file URL>",
#'   modified_between = c("2026-10-01", "2026-10-31")
#' )
#' }
#' @export
list_sp_item_versions <- function(
  ...,
  sp_item = NULL,
  n = NULL,
  modified_between = NULL,
  item_cols = c("id", "none", "summary"),
  version_cols = c("properties", "all"),
  as_data_frame = TRUE,
  call = caller_env()
) {
  item_cols <- arg_match(item_cols, error_call = call)
  version_cols <- arg_match(version_cols, error_call = call)
  check_number_whole(n, min = 1, allow_null = TRUE, call = call)
  check_bool(as_data_frame, call = call)
  modified_between <- as_modified_between(modified_between, call = call)

  sp_item <- sp_item %||% get_sp_item(..., call = call)
  check_ms_obj(sp_item, "ms_drive_item", call = call)

  # `n` is only passed to the API (to reduce the size of the response) when
  # versions aren't also filtered by date
  top <- if (is.null(modified_between)) n

  response <- sp_item_versions_request(sp_item, top = top)
  versions <- response[["value"]]

  if (!is.null(modified_between)) {
    versions <- vctrs::vec_slice(
      versions,
      is_within_bounds(version_modified_times(versions), modified_between)
    )
  }

  if (!is.null(n)) {
    versions <- utils::head(versions, n)
  }

  if (!as_data_frame) {
    response[["value"]] <- versions
    return(response)
  }

  sp_item_versions_as_data_frame(
    versions,
    sp_item = sp_item,
    item_cols = item_cols,
    version_cols = version_cols
  )
}

#' @rdname list_sp_item_versions
#' @param version_id Version ID, e.g. `"3.0"`, as returned by
#'   [list_sp_item_versions()].
#' @export
get_sp_item_version <- function(
  version_id,
  ...,
  sp_item = NULL,
  item_cols = c("id", "none", "summary"),
  version_cols = c("properties", "all"),
  as_data_frame = TRUE,
  call = caller_env()
) {
  check_string(version_id, call = call)
  item_cols <- arg_match(item_cols, error_call = call)
  version_cols <- arg_match(version_cols, error_call = call)
  check_bool(as_data_frame, call = call)

  sp_item <- sp_item %||% get_sp_item(..., call = call)
  check_ms_obj(sp_item, "ms_drive_item", call = call)

  version <- sp_item$do_operation(paste0("versions/", version_id))

  if (!as_data_frame) {
    return(version)
  }

  sp_item_versions_as_data_frame(
    list(version),
    sp_item = sp_item,
    item_cols = item_cols,
    version_cols = version_cols
  )
}

#' @rdname list_sp_item_versions
#' @param dest Path to save the file to. Defaults to the name of the item with
#'   the version ID added before the file extension (e.g. `"book_v3.0.xlsx"`)
#'   in the working directory.
#' @param overwrite If `TRUE`, overwrite an existing file at `dest`.
#' @export
download_sp_item_version <- function(
  version_id,
  ...,
  sp_item = NULL,
  dest = NULL,
  overwrite = FALSE,
  call = caller_env()
) {
  check_string(version_id, call = call)
  check_string(dest, allow_null = TRUE, call = call)
  check_bool(overwrite, call = call)

  sp_item <- sp_item %||% get_sp_item(..., call = call)
  check_ms_obj(sp_item, "ms_drive_item", call = call)

  dest <- dest %||% sp_item_version_filename(sp_item, version_id)

  if (file.exists(dest) && !overwrite) {
    cli_abort(
      c(
        "{.path {dest}} already exists.",
        "i" = "Use {.code overwrite = TRUE} to replace it."
      ),
      call = call
    )
  }

  # Download to a temporary file so a failed request can't leave an error
  # response (or a partial file) at `dest`
  tmp <- tempfile()
  on.exit(unlink(tmp), add = TRUE)

  response <- sp_item_version_content(sp_item, version_id, tmp)

  if (httr::status_code(response) >= 400) {
    httr::stop_for_status(
      response,
      task = paste0("download version ", version_id)
    )
  }

  if (!file.copy(tmp, dest, overwrite = TRUE)) {
    cli_abort("Can't write to {.path {dest}}.", call = call)
  }

  invisible(dest)
}

#' Download the content of a version to `path`
#'
#' The Graph API only serves the content of previous versions from the
#' versions endpoint. If that request fails for the current (newest) version,
#' the content of the item is requested instead.
#' @returns The `httr` response.
#' @noRd
sp_item_version_content <- function(sp_item, version_id, path) {
  request <- function(op) {
    sp_item$do_operation(
      op,
      config = httr::write_disk(path, overwrite = TRUE),
      http_status_handler = "pass"
    )
  }

  response <- request(paste0("versions/", version_id, "/content"))

  if (httr::status_code(response) < 400) {
    return(response)
  }

  newest <- sp_item_versions_request(sp_item, top = 1)[["value"]]
  newest_id <- purrr::pluck(newest, 1, "id")

  if (identical(newest_id, version_id)) {
    response <- request("content")
  }

  response
}

#' Request the versions for an item, following next links
#' @returns The first response with `value` replaced by all versions.
#' @noRd
sp_item_versions_request <- function(sp_item, top = NULL) {
  options <- if (!is.null(top)) list(`$top` = top) else list()

  response <- sp_item$do_operation("versions", options = options)
  versions <- response[["value"]]
  next_link <- response[["@odata.nextLink"]]

  # With `$top`, the API can still return a next link for the other versions
  while (is_string(next_link) && (is.null(top) || length(versions) < top)) {
    page <- AzureGraph::call_graph_url(sp_item[["token"]], next_link)
    versions <- c(versions, page[["value"]])
    next_link <- page[["@odata.nextLink"]]
  }

  response[["value"]] <- sort_versions_newest_first(versions)
  response[["@odata.nextLink"]] <- NULL
  response
}

#' Get the last modified time of driveItemVersion records
#' @returns A POSIXct vector (`NA` if a record has no time).
#' @noRd
version_modified_times <- function(versions) {
  versions |>
    purrr::map_chr("lastModifiedDateTime", .default = NA_character_) |>
    parse_graph_datetime()
}

#' Is a time within the (inclusive) bounds from `as_modified_between()`?
#' @noRd
is_within_bounds <- function(x, bounds) {
  !is.na(x) &
    (is.na(bounds[[1]]) | x >= bounds[[1]]) &
    (is.na(bounds[[2]]) | x <= bounds[[2]])
}

#' Sort driveItemVersion records by last modified time, newest first
#'
#' Ties (and missing times) keep the order returned by the API.
#' @noRd
sort_versions_newest_first <- function(versions) {
  order <- versions |>
    version_modified_times() |>
    vctrs::vec_order(direction = "desc", na_value = "smallest")

  vctrs::vec_slice(versions, order)
}

#' Build the default file name for a downloaded version
#' @noRd
sp_item_version_filename <- function(sp_item, version_id) {
  name <- sp_item[["properties"]][["name"]] %||% "item"
  ext <- tools::file_ext(name)
  stem <- tools::file_path_sans_ext(name)

  paste0(stem, "_v", version_id, if (nzchar(ext)) paste0(".", ext))
}

#' Convert a list of driveItemVersion records to a data frame
#' @noRd
sp_item_versions_as_data_frame <- function(
  versions,
  sp_item,
  item_cols = "id",
  version_cols = "properties"
) {
  data <- versions |>
    purrr::map(\(x) vctrs::new_data_frame(flatten_named_list(x), n = 1L)) |>
    purrr::list_rbind()

  # NOTE: Column names are converted to snake case, unlike sp_dir_info() and
  # Microsoft365R which keep the Graph API camelCase names (e.g.
  # `lastModifiedDateTime`). Several columns (`version_id`, `item_id`,
  # `drive_id`) are not Graph properties and `id` can't be used for the version
  # ID because it is the item ID in sp_dir_info(), so one style is used
  # throughout. Revisit if the data frame naming convention for the package
  # changes.
  names(data) <- names(data) |>
    stringr::str_remove("^@microsoft\\.graph\\.") |>
    stringr::str_to_snake() |>
    purrr::map_chr(\(nm) sp_item_versions_renames[[nm]] %||% nm)

  # Add any missing columns and put the columns that are always returned first
  data <- vctrs::vec_rbind(sp_item_versions_ptype, data) |>
    purrr::modify_at("last_modified", parse_graph_datetime)

  data[["version"]] <- suppressWarnings(as.numeric(data[["version_id"]]))

  if (is_installed("fs")) {
    data <- fmt_sp_item_size(data)
  }

  if (version_cols == "properties") {
    data <- data[names(sp_item_versions_ptype)]
  }

  item_data <- sp_item_info_columns(sp_item, item_cols)

  vctrs::vec_cbind(
    vctrs::data_frame(!!!item_data, .size = nrow(data)),
    data
  )
}

sp_item_versions_renames <- list(
  id = "version_id",
  last_modified_date_time = "last_modified",
  last_modified_by_user_display_name = "last_modified_by",
  last_modified_by_user_email = "last_modified_by_email",
  last_modified_by_user_id = "last_modified_by_id"
)

# Columns that are always returned (`last_modified` is parsed after binding)
sp_item_versions_ptype <- vctrs::data_frame(
  version_id = character(),
  version = double(),
  last_modified = character(),
  last_modified_by = character(),
  last_modified_by_email = character(),
  last_modified_by_id = character(),
  size = double()
)

#' Get item columns to add to a data frame of versions
#' @returns A named list of scalar values (possibly empty).
#' @noRd
sp_item_info_columns <- function(sp_item, item_cols = "id") {
  if (item_cols == "none") {
    return(list())
  }

  properties <- sp_item[["properties"]]
  summary <- item_cols == "summary"

  pluck_chr <- function(...) {
    purrr::pluck(properties, ..., .default = NA_character_)
  }

  purrr::compact(list(
    item_id = pluck_chr("id"),
    drive_id = pluck_chr("parentReference", "driveId"),
    item_name = if (summary) pluck_chr("name"),
    item_web_url = if (summary) pluck_chr("webUrl")
  ))
}

#' Parse a Graph date-time string (ISO 8601 in UTC) to POSIXct
#' @noRd
parse_graph_datetime <- function(x) {
  as.POSIXct(x, format = "%Y-%m-%dT%H:%M:%OSZ", tz = "UTC")
}

# Seconds in a day less a millisecond: the end of a day for an inclusive bound
sp_end_of_day <- 86400 - 0.001

#' Convert `modified_between` to a length 2 POSIXct vector (or NULL)
#' @noRd
as_modified_between <- function(
  x,
  arg = caller_arg(x),
  call = caller_env()
) {
  force(arg)

  if (is.null(x)) {
    return(NULL)
  }

  if (inherits(x, "Interval") && is_installed("lubridate")) {
    x <- c(lubridate::int_start(x), lubridate::int_end(x))
  }

  if (length(x) != 2) {
    cli_abort(
      "{.arg {arg}} must be a length 2 vector of dates or date-times, not
      length {length(x)}.",
      call = call
    )
  }

  if (!is.list(x)) {
    x <- vctrs::vec_chop(x)
  }

  bounds <- c(
    as_datetime_bound(x[[1]], arg = arg, call = call),
    as_datetime_bound(x[[2]], end = TRUE, arg = arg, call = call)
  )

  if (!anyNA(bounds) && bounds[[1]] > bounds[[2]]) {
    cli_abort(
      "The start of {.arg {arg}} must not be after the end.",
      call = call
    )
  }

  bounds
}

#' Convert one value from `modified_between` to a POSIXct bound
#'
#' A `Date` (or a date string) used as an end includes the whole day.
#' @noRd
as_datetime_bound <- function(value, end = FALSE, arg, call = caller_env()) {
  if (is.na(value)) {
    return(as.POSIXct(NA_real_, tz = "UTC"))
  }

  if (inherits(value, "Date")) {
    return(as.POSIXct(value, tz = "UTC") + if (end) sp_end_of_day else 0)
  }

  if (inherits(value, "POSIXt")) {
    return(as.POSIXct(value))
  }

  if (!is.character(value)) {
    cli_abort(
      "{.arg {arg}} must contain dates or date-times, not {.cls {class(value)}}.",
      call = call
    )
  }

  parsed <- as.POSIXct(
    value,
    tz = "UTC",
    tryFormats = c(
      "%Y-%m-%dT%H:%M:%OSZ",
      "%Y-%m-%d %H:%M:%OS",
      "%Y-%m-%d %H:%M",
      "%Y-%m-%d"
    ),
    optional = TRUE
  )

  if (is.na(parsed)) {
    cli_abort(
      "{.arg {arg}} can't be parsed as a date or date-time: {.val {value}}.",
      call = call
    )
  }

  if (end && stringr::str_detect(value, "^\\d{4}-\\d{2}-\\d{2}$")) {
    parsed <- parsed + sp_end_of_day
  }

  parsed
}

#' Flatten data frame columns of nested lists or data frames
#'
#' The design is based on [tidyr::unnest_wider()]: each element of a list
#' column becomes a column, in the position of the original column, and
#' `names_sep` and `names_repair` work the same way. Unlike `unnest_wider()`,
#' nested lists are flattened to any depth (e.g. `lastModifiedBy$user$email`),
#' unnamed lists (e.g. JSON arrays) are kept as list elements, columns in
#' `cols` that are not in `data` are skipped, and there is no support for
#' tidyselect, `ptype`, `transform`, `simplify`, or `strict`. Elements that are
#' `NULL` or missing a value become `NA`.
#'
#' @param data A data frame.
#' @param cols Names of list columns (of named lists) or data frame columns to
#'   flatten. Names that are not columns in `data` are skipped.
#' @param names_sep String used to join the column name and nested names, e.g.
#'   `"lastModifiedBy_user_email"`. If `NULL`, new columns are not prefixed with
#'   the column name (nested names are still joined with `"_"`).
#' @param names_repair Passed to `.name_repair` in [vctrs::vec_cbind()]. The
#'   default, `"check_unique"`, errors if a new column has the same name as an
#'   existing column.
#' @returns `data` with each column in `cols` replaced, in the same position,
#'   by one or more flattened columns.
#' @noRd
flatten_df_col <- function(
  data,
  cols,
  names_sep = "_",
  names_repair = "check_unique",
  call = caller_env()
) {
  check_data_frame(data, call = call)
  check_character(cols, call = call)
  check_string(names_sep, allow_null = TRUE, call = call)

  purrr::reduce(
    intersect(cols, names(data)),
    \(data, col) {
      flatten_one_df_col(data, col, names_sep, names_repair, call = call)
    },
    .init = data
  )
}

#' Flatten one column of `data` in place
#' @noRd
flatten_one_df_col <- function(
  data,
  col,
  names_sep,
  names_repair,
  call = caller_env()
) {
  values <- data[[col]]

  if (is.data.frame(values)) {
    values <- purrr::map(vctrs::vec_chop(values), as.list)
  }

  flat <- values |>
    purrr::map(\(x) {
      vctrs::new_data_frame(
        flatten_named_list(x, names_sep = names_sep %||% "_"),
        n = 1L
      )
    }) |>
    purrr::list_rbind()

  if (!is.null(names_sep)) {
    names(flat) <- paste(col, names(flat), sep = names_sep)
  }

  pos <- match(col, names(data))
  before <- names(data)[seq_len(pos - 1L)]
  after <- names(data)[seq_along(data) > pos]

  vctrs::vec_cbind(
    data[before],
    flat,
    data[after],
    .name_repair = names_repair,
    .error_call = call
  )
}

#' Flatten a nested named list to a single level list
#'
#' Unnamed lists (e.g. JSON arrays) are left as list elements. `NULL` and empty
#' values are dropped so they become missing values when rows are combined.
#' @noRd
flatten_named_list <- function(x, names_sep = "_") {
  if (is.null(x)) {
    return(list())
  }

  if (!is.list(x) || !is_named(x)) {
    return(x)
  }

  x |>
    purrr::compact() |>
    purrr::map(\(value) {
      if (is.list(value) && is_named(value)) {
        flatten_named_list(value, names_sep = names_sep)
      } else {
        # Wrap values so unnamed lists (e.g. arrays) stay one element
        list(value)
      }
    }) |>
    purrr::list_flatten(name_spec = paste0("{outer}", names_sep, "{inner}"))
}

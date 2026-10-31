#' Read and write the cells of an Excel workbook
#'
#' @description
#' These functions use the [Excel REST
#' API](https://learn.microsoft.com/en-us/graph/excel-write-to-workbook) to
#' work with a workbook stored in SharePoint or OneDrive without downloading and
#' uploading the whole file. Changes are made to the live workbook so edits by
#' other people are not overwritten. The workbook must be an `.xlsx` file.
#'
#' - [sp_workbook_sheets()] lists the worksheets in a workbook.
#' - [sp_workbook_range_read()] reads a range (or the used range) of a worksheet
#'   into a data frame.
#' - [sp_workbook_range_write()] writes a data frame, matrix, or vector to a
#'   range.
#'
#' Use [local_sp_workbook_session()] to make several requests in one workbook
#' session, or [sp_workbook_session_create()] and [sp_workbook_session_close()]
#' to manage the session yourself.
#'
#' @param x A SharePoint or OneDrive Excel workbook. Can be a `ms_drive_item`
#'   object, a SharePoint URL, or a path passed to [get_sp_item()].
#' @param ... Additional parameters passed to [get_sp_item()] if `x` is not a
#'   `ms_drive_item` object.
#' @param sheet Worksheet name or ID. If `NULL`, the first worksheet is used. A sheet name can also be included in `range`
#'   (e.g. `"Sheet1!A1:C3"`).
#' @param range A range in A1 notation (e.g. `"A1:C3"`). If `NULL`,
#'   [sp_workbook_range_read()] reads the used range of the worksheet. For
#'   [sp_workbook_range_write()], `range` can be a single cell, which is
#'   expanded to fit `values`.
#' @param header If `TRUE` (default), the first row of the range is used for
#'   column names.
#' @param session_id A workbook session ID from
#'   [sp_workbook_session_create()]. If `NULL` (default), the session for the
#'   workbook set by [local_sp_workbook_session()] or the
#'   `sharepointr.workbook_session` option is used, if any. Otherwise the request
#'   is sent without a session.
#' @returns
#' - [sp_workbook_sheets()]: A data frame with a row for each worksheet.
#' - [sp_workbook_range_read()]: A data frame.
#' - [sp_workbook_range_write()]: The address of the range written to, invisibly.
#' @name sp_workbook
#' @family workbooks
#' @keywords workbooks
#' @examples
#' sp_workbook_url <- "<SharePoint workbook url>"
#'
#' if (is_sp_url(sp_workbook_url)) {
#'   sp_workbook_sheets(sp_workbook_url)
#'
#'   sp_workbook_range_read(sp_workbook_url, "A1:C10")
#' }
NULL

#' List the worksheets in a workbook
#' @rdname sp_workbook
#' @export
sp_workbook_sheets <- function(
  x,
  ...,
  session_id = NULL,
  call = caller_env()
) {
  item <- sp_workbook_item(x, ..., call = call)

  resp <- sp_workbook_request(
    item,
    "worksheets",
    session_id = session_id,
    call = call
  )

  sheets <- resp[["value"]]

  data.frame(
    id = purrr::map_chr(sheets, \(x) x[["id"]] %||% NA_character_),
    name = purrr::map_chr(sheets, \(x) x[["name"]] %||% NA_character_),
    position = purrr::map_int(sheets, \(x) as.integer(x[["position"]] %||% NA)),
    visibility = purrr::map_chr(
      sheets,
      \(x) x[["visibility"]] %||% NA_character_
    )
  )
}

#' Read a range from a workbook
#' @rdname sp_workbook
#' @export
sp_workbook_range_read <- function(
  x,
  range = NULL,
  ...,
  sheet = NULL,
  header = TRUE,
  session_id = NULL,
  call = caller_env()
) {
  check_bool(header, call = call)

  item <- sp_workbook_item(x, ..., call = call)
  address <- sp_workbook_address(range, sheet, call = call)

  path <- if (is.null(address[["range"]])) {
    "usedRange(valuesOnly=true)"
  } else {
    sprintf("range(address='%s')", address[["range"]])
  }

  resp <- sp_workbook_request(
    item,
    paste0(
      sp_workbook_sheet_path(item, address[["sheet"]], session_id, call),
      path
    ),
    session_id = session_id,
    call = call
  )

  sp_workbook_values_as_df(resp[["values"]], header = header)
}

#' Write values to a range in a workbook
#'
#' @param values A data frame, matrix, or vector. A vector is written as a
#'   single column. `NA` values are written as empty cells.
#' @param col_names If `TRUE` (default), the column names of a data frame (or
#'   matrix with column names) are written as the first row.
#' @rdname sp_workbook
#' @export
sp_workbook_range_write <- function(
  x,
  values,
  range = "A1",
  ...,
  sheet = NULL,
  col_names = TRUE,
  session_id = NULL,
  call = caller_env()
) {
  check_bool(col_names, call = call)

  item <- sp_workbook_item(x, ..., call = call)
  address <- sp_workbook_address(range, sheet, call = call)

  if (is.null(address[["range"]])) {
    cli_abort(
      "{.arg range} must be a cell or range, not {.code NULL}.",
      call = call
    )
  }

  values <- sp_workbook_values_as_list(values, col_names, call = call)

  # A single starting cell is expanded to the size of values
  address[["range"]] <- sp_workbook_range_resize(
    address[["range"]],
    nrow = length(values),
    ncol = length(values[[1]]),
    call = call
  )

  resp <- sp_workbook_request(
    item,
    sprintf(
      "%srange(address='%s')",
      sp_workbook_sheet_path(item, address[["sheet"]], session_id, call),
      address[["range"]]
    ),
    body = list(values = values),
    http_verb = "PATCH",
    session_id = session_id,
    call = call
  )

  invisible(resp[["address"]] %||% address[["range"]])
}

#' Create or close a workbook session
#'
#' Use a session to make several requests to a workbook. Requests without a
#' session are sent in a new temporary session by the API. If
#' `persist_changes = FALSE`, changes made in the session are discarded when it
#' is closed. A session that isn't closed expires after a few minutes.
#'
#' @inheritParams sp_workbook
#' @param persist_changes If `TRUE` (default), changes made in the session are
#'   saved to the workbook.
#' @returns [sp_workbook_session_create()] returns a session ID.
#'   [sp_workbook_session_close()] returns `x` invisibly.
#' @family workbooks
#' @keywords workbooks
#' @export
sp_workbook_session_create <- function(
  x,
  ...,
  persist_changes = TRUE,
  call = caller_env()
) {
  check_bool(persist_changes, call = call)

  item <- sp_workbook_item(x, ..., call = call)

  resp <- sp_workbook_request(
    item,
    "createSession",
    body = list(persistChanges = persist_changes),
    http_verb = "POST",
    session_id = FALSE,
    call = call
  )

  resp[["id"]]
}

#' @rdname sp_workbook_session_create
#' @param session_id A workbook session ID from [sp_workbook_session_create()].
#' @export
sp_workbook_session_close <- function(
  x,
  session_id,
  ...,
  call = caller_env()
) {
  check_string(session_id, call = call)

  item <- sp_workbook_item(x, ..., call = call)

  sp_workbook_request(
    item,
    "closeSession",
    http_verb = "POST",
    session_id = session_id,
    call = call
  )

  invisible(x)
}

#' Use a workbook session until the calling function exits
#'
#' [local_sp_workbook_session()] creates a session and sets it as the session
#' for `x` so that it doesn't need to be passed to each function with
#' `session_id`. The session is closed, and the previous option value restored,
#' when the function it is called from exits. Wrap the code in [local()] to
#' limit the session when working interactively.
#'
#' The session is stored in the `sharepointr.workbook_session` option as a
#' character vector of session IDs named with the item ID of the workbook. Since
#' a session only works for one workbook, the session is only used for requests
#' to that workbook. An unnamed session ID in the option is used for all
#' workbooks.
#'
#' @inheritParams sp_workbook_session_create
#' @param .local_envir The environment to use for scoping.
#' @returns The session ID, invisibly.
#' @family workbooks
#' @keywords workbooks
#' @examples
#' sp_workbook_url <- "<SharePoint workbook url>"
#'
#' if (is_sp_url(sp_workbook_url)) {
#'   local({
#'     local_sp_workbook_session(sp_workbook_url)
#'     sp_workbook_range_write(sp_workbook_url, data.frame(a = 1), "A1")
#'     sp_workbook_range_write(sp_workbook_url, data.frame(b = 2), "C1")
#'   })
#' }
#' @export
local_sp_workbook_session <- function(
  x,
  ...,
  persist_changes = TRUE,
  .local_envir = caller_env(),
  call = caller_env()
) {
  item <- sp_workbook_item(x, ..., call = call)
  item_id <- item[["properties"]][["id"]]

  session_id <- sp_workbook_session_create(
    item,
    persist_changes = persist_changes,
    call = call
  )

  old <- getOption("sharepointr.workbook_session")
  new <- c(
    old[names(old) %||% character() != item_id],
    rlang::set_names(session_id, item_id)
  )
  options(sharepointr.workbook_session = new)

  # Run when the calling function exits (the base R equivalent of withr::defer)
  do.call(
    base::on.exit,
    list(
      substitute({
        options(sharepointr.workbook_session = old)
        try(sp_workbook_session_close(item, session_id), silent = TRUE)
      }),
      TRUE
    ),
    envir = .local_envir
  )

  invisible(session_id)
}

# ---- Internal helpers ----

#' Get the session ID set with the `sharepointr.workbook_session` option
#'
#' The option is a named character vector (session IDs named with item IDs) or
#' an unnamed session ID used for any workbook.
#' @noRd
sp_workbook_session_option <- function(item_id) {
  session <- getOption("sharepointr.workbook_session")

  if (length(session) == 0) {
    return(NULL)
  }

  if (is.null(names(session))) {
    return(session[[1]])
  }

  if (item_id %in% names(session)) {
    return(session[[item_id]])
  }

  NULL
}

#' Get the drive item for a workbook
#' @noRd
sp_workbook_item <- function(x, ..., call = caller_env()) {
  if (inherits(x, "ms_drive_item")) {
    return(x)
  }

  check_string(x, call = call)

  item <- get_sp_item(x, ..., call = call)

  if (item$is_folder()) {
    cli_abort("{.arg x} must be a workbook, not a folder.", call = call)
  }

  item
}

#' Send a request to the workbook API for a drive item
#'
#' `path` is relative to the workbook (e.g. `"worksheets"`).
#' @noRd
sp_workbook_request <- function(
  item,
  path,
  body = NULL,
  http_verb = "GET",
  session_id = NULL,
  call = caller_env()
) {
  drive_id <- item[["properties"]][["parentReference"]][["driveId"]]
  item_id <- item[["properties"]][["id"]]

  # `session_id = FALSE` sends the request without a session
  session_id <- if (isFALSE(session_id)) {
    NULL
  } else {
    session_id %||% sp_workbook_session_option(item_id)
  }

  args <- list(
    item[["token"]],
    file.path("drives", drive_id, "items", item_id, "workbook", path),
    body = body,
    encode = "json",
    http_verb = http_verb
  )

  if (!is.null(session_id)) {
    args <- c(args, list(httr::add_headers(`workbook-session-id` = session_id)))
  }

  args[["http_status_handler"]] <- "pass"

  resp <- do.call(AzureGraph::call_graph_endpoint, args)

  check_sp_workbook_response(resp, item, http_verb, call = call)

  httr::content(resp) %||% list()
}

# Hints for second-level error codes (lowercase since codes are case
# insensitive). See
# <https://learn.microsoft.com/en-us/graph/workbook-error-handling>
sp_workbook_error_hints <- c(
  accessconflict = "Another user may have the workbook locked for editing.
    Try again after they close it.",
  invalidsessionaccessconflict = "Another user may have the workbook locked for
    editing. Try again after they close it.",
  invalidsessionrecreatable = "The workbook session doesn't exist or has
    expired. Create a new session with {.fn sp_workbook_session_create}.",
  rangeexceedslimit = "The range has too many cells. Use a smaller range.",
  payloadtoolargeuncategorized = "The request is too large. Use a smaller
    range.",
  unsupportedworkbook = "The workbook has unsupported features or is too large
    for the Excel API.",
  invalidsessionunsupportedworkbook = "The workbook has unsupported features or
    is too large for the Excel API.",
  itemnotfound = "Check the worksheet name and range.",
  notfounduncategorized = "Check the worksheet name and range."
)

#' Check a workbook API response and abort with a hint for known error codes
#'
#' The Excel API returns a top-level error code and, nested in `innerError`, a
#' more specific code that Microsoft recommends handling first.
#' @noRd
check_sp_workbook_response <- function(
  resp,
  item,
  http_verb,
  call = caller_env()
) {
  if (!httr::http_error(resp)) {
    return(invisible(NULL))
  }

  error <- httr::content(resp)[["error"]]
  codes <- stringr::str_to_lower(sp_workbook_error_codes(error))
  hints <- sp_workbook_error_hints[codes]
  hint <- purrr::detect(hints, \(x) !is.na(x))

  cli_abort(
    c(
      "Can't send a {.val {http_verb}} request to the workbook
      {.val {item[['properties']][['name']]}}.",
      "x" = error[["message"]] %||% httr::http_status(resp)[["message"]],
      "i" = hint
    ),
    call = call
  )
}

#' Get the error codes from an error and its nested `innerError`, outermost
#' first
#' @noRd
sp_workbook_error_codes <- function(error) {
  if (is.null(error)) {
    return(character())
  }

  c(error[["code"]], sp_workbook_error_codes(error[["innerError"]]))
}

#' Split a range like "Sheet1!A1:C3" into the sheet and range
#' @noRd
sp_workbook_address <- function(range, sheet, call = caller_env()) {
  check_string(range, allow_null = TRUE, call = call)
  check_string(sheet, allow_null = TRUE, call = call)

  if (!is.null(range) && stringr::str_detect(range, stringr::fixed("!"))) {
    range_sheet <- stringr::str_remove(range, "!.*$")
    range <- stringr::str_remove(range, "^.*!")

    # Sheet names with spaces are quoted in A1 references
    sheet <- sheet %||% stringr::str_remove_all(range_sheet, "^'|'$")
    sheet <- stringr::str_replace_all(sheet, stringr::fixed("''"), "'")
  }

  list(sheet = sheet, range = range)
}

#' Build the worksheet part of a workbook path
#'
#' If `sheet` is `NULL`, the first worksheet is used.
#' @noRd
sp_workbook_sheet_path <- function(
  item,
  sheet,
  session_id = NULL,
  call = caller_env()
) {
  if (is.null(sheet)) {
    sheets <- sp_workbook_sheets(item, session_id = session_id, call = call)
    sheet <- sheets[["id"]][which.min(sheets[["position"]])]
  }

  paste0("worksheets/", utils::URLencode(sheet, reserved = TRUE), "/")
}

#' Expand a single cell like "B2" to a range like "B2:D5"
#' @noRd
sp_workbook_range_resize <- function(range, nrow, ncol, call = caller_env()) {
  if (stringr::str_detect(range, stringr::fixed(":"))) {
    return(range)
  }

  match <- stringr::str_match(range, "^\\$?([A-Za-z]+)\\$?([0-9]+)$")

  if (anyNA(match)) {
    cli_abort(
      "{.arg range} must be a cell like {.val A1}, not {.val {range}}.",
      call = call
    )
  }

  col <- sp_workbook_col_to_number(match[1, 2])
  row <- as.integer(match[1, 3])

  paste0(
    range,
    ":",
    sp_workbook_number_to_col(col + ncol - 1L),
    row + nrow - 1L
  )
}

sp_workbook_col_to_number <- function(col) {
  chars <- utf8ToInt(toupper(col)) - utf8ToInt("A") + 1L
  as.integer(sum(chars * 26^(rev(seq_along(chars)) - 1L)))
}

sp_workbook_number_to_col <- function(n) {
  col <- character()

  while (n > 0) {
    n <- n - 1L
    col <- c(intToUtf8(utf8ToInt("A") + n %% 26L), col)
    n <- n %/% 26L
  }

  paste(col, collapse = "")
}

#' Convert the `values` of a range (a list of rows) to a data frame
#'
#' The API returns empty cells as `""`. These are converted to `NA`.
#' @noRd
sp_workbook_values_as_df <- function(values, header = TRUE) {
  if (length(values) == 0) {
    return(data.frame())
  }

  ncol <- length(values[[1]])
  columns <- purrr::list_transpose(values, simplify = FALSE)

  if (header) {
    col_names <- purrr::map_chr(columns, \(x) as.character(x[[1]]))
    columns <- purrr::map(columns, \(x) x[-1])
  } else {
    col_names <- paste0("V", seq_len(ncol))
  }

  columns <- purrr::map(columns, sp_workbook_simplify_column)
  names(columns) <- vctrs::vec_as_names(
    col_names,
    repair = "unique",
    quiet = TRUE
  )

  as.data.frame(columns, check.names = FALSE, stringsAsFactors = FALSE)
}

#' Convert a list of cell values to a vector
#'
#' Values of different types in one column (e.g. a number and text) are
#' converted to character.
#' @noRd
sp_workbook_simplify_column <- function(x) {
  x <- purrr::map(x, \(value) {
    if (is.null(value) || identical(value, "")) NA else value
  })

  types <- x |>
    purrr::discard(is.na) |>
    purrr::map_chr(\(value) {
      if (is.numeric(value)) "numeric" else typeof(value)
    }) |>
    unique()

  if (length(types) > 1) {
    return(purrr::map_chr(x, as.character))
  }

  unlist(x)
}

#' Convert a data frame, matrix, or vector to a list of rows
#' @noRd
sp_workbook_values_as_list <- function(
  values,
  col_names = TRUE,
  call = caller_env()
) {
  if (is.atomic(values) && is.null(dim(values))) {
    values <- matrix(values, ncol = 1)
  }

  if (!is.data.frame(values) && !is.matrix(values)) {
    cli_abort(
      "{.arg values} must be a data frame, matrix, or vector, not
      {.obj_type_friendly {values}}.",
      call = call
    )
  }

  if (nrow(values) == 0 || ncol(values) == 0) {
    cli_abort(
      "{.arg values} must have at least 1 row and 1 column.",
      call = call
    )
  }

  has_names <- !is.null(colnames(values))
  values <- as.data.frame(values, stringsAsFactors = FALSE)

  rows <- purrr::map(seq_len(nrow(values)), \(i) {
    values |>
      purrr::map(\(col) sp_workbook_cell(col[[i]])) |>
      unname()
  })

  if (col_names && has_names) {
    rows <- c(list(as.list(names(values))), rows)
  }

  rows
}

#' Convert one value to JSON for a cell
#'
#' `NA` is written as `""` to clear the cell. Dates are written as text
#' since the API expects Excel serial numbers for dates.
#' @noRd
sp_workbook_cell <- function(x) {
  if (is.na(x)) {
    return("")
  }

  if (inherits(x, c("Date", "POSIXt", "factor"))) {
    return(as.character(x))
  }

  x
}

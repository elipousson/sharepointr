#' Get, list, update, and delete SharePoint list items
#'
#' [list_sp_list_items()] lists `sp_list` items. This function uses a modified
#' version of the `list_items` method for `Microsoft365R::ms_list` objects that
#' adds the `order_by` and `order_dir` arguments.
#' @name sp_list_item
#' @returns For [list_sp_list_items()] and [get_sp_list_items()], a data
#'   frame of list items if `as_data_frame = TRUE` (default), or a list of
#'   item fields otherwise. For [get_sp_list_item()], a `ms_list_item`
#'   object.
#' @keywords lists
NULL

#' @rdname sp_list_item
#' @name list_sp_list_items
#' @inheritParams ms_graph_arg_terms
#' @inheritParams get_sp_list
#' @inheritDotParams get_sp_list -as_data_frame
#' @param select A character vector of column names to include in the returned
#'   data frame of list items. If `NULL`, the data frame includes all columns
#'   from the list.
#' @param all_metadata If `TRUE`, the returned data frame will contain extended
#'   metadata as separate columns, while the data fields will be in a nested
#'   data frame named fields. This is always set to `FALSE` if `n = NULL` or
#'   `as_data_frame = FALSE`. The `"@odata.etag"` value the Graph API returns
#'   with the fields of each item is only included if `all_metadata = TRUE`.
#' @param pagesize Number of list items to return. Reduce from default of 5000
#'   is experiencing timeouts.
#' @param order_by Optional. Field name to order by.
#' @param order_dir Direction to order results if `order_by` is provided.
#' @param display_nm Option of "drop" (default), "label", or "replace". If
#'   "drop", display names are not accessed or used. If "label", display names
#'   are used to label matching columns in the returned data frame. If
#'   "replace", display names replace column names in the returned data frame.
#'   When working with the last option, the `name_repair` argument is required
#'   since there is no requirement on SharePoint for lists to use unique display
#'   names and invalid data frames can result.
#' @param col_formatting "asis" (default) or "date". If "date", use the list
#' column metadata and convert date columns to Date class and datetime
#' columns to POSIXct class vectors (latter is not yet tested).
#' @param select_type Type of columns to select. Ignored if `select` is supplied.
#' "asis" (default) returns all available columns. "editable" returns ID and all
#' non-read-only columns and "external" returns ID and all non-internal columns.
#' @param tz Time zone to use in reformatting date/time columns if
#' `col_formatting = "date"`. Defaults to `Sys.timezone()`.
#' @param name_repair Passed to repair argument of [vctrs::vec_as_names()]
#' @export
list_sp_list_items <- function(
  list_name = NULL,
  list_id = NULL,
  sp_list = NULL,
  ...,
  filter = NULL,
  select = NULL,
  order_by = NULL,
  order_dir = "desc",
  all_metadata = FALSE,
  as_data_frame = TRUE,
  col_formatting = c("asis", "date"),
  display_nm = c("drop", "label", "replace"),
  select_type = c("asis", "editable", "external"),
  n = NULL,
  tz = Sys.timezone(),
  name_repair = "unique",
  pagesize = 5000,
  site_url = NULL,
  site = NULL,
  drive_name = NULL,
  drive_id = NULL,
  drive = NULL,
  call = caller_env()
) {
  col_formatting <- arg_match(col_formatting, error_call = call)
  display_nm <- arg_match(display_nm, error_call = call)
  select_type <- arg_match(select_type, error_call = call)

  sp_list <- sp_list %||%
    get_sp_list(
      list_name = list_name,
      list_id = list_id,
      as_data_frame = FALSE,
      metadata = FALSE,
      ...,
      site_url = site_url,
      site = site,
      drive_name = drive_name,
      drive_id = drive_id,
      drive = drive,
      call = call
    )

  if (is.character(select) && select_type != "asis") {
    cli::cli_bullets(
      c("!" = "{.arg select_type} is ignored if {.arg select} is provided.")
    )
    select_type <- "asis"
  }

  # Fetch list column metadata once for selecting columns, formatting dates,
  # and display names (also reused to build the ptype in .ms365_list_items())
  col_metadata <- NULL

  if (select_type != "asis" || col_formatting != "asis" || display_nm != "drop") {
    col_metadata <- get_sp_list_metadata(
      sp_list = sp_list,
      as_data_frame = FALSE,
      call = call
    )
  }

  # FIXME: I think this is not necessary since Microsoft365R already does the
  # same thing
  if (select_type != "asis") {
    # Get editable or visible columns
    select <- c(
      "ID",
      names(pull_sp_list_cols(col_metadata, col_type = select_type, call = call))
    )
  }

  cli::cli_progress_step(
    "Getting list items from SharePoint"
  )

  # List items
  # FIXME: Is Title not returned when no values are in place for Title?
  sp_list_items <- .ms365_list_items(
    sp_list = sp_list,
    filter = filter,
    select = select,
    order_by = order_by,
    order_dir = order_dir,
    all_metadata = all_metadata,
    simplify = as_data_frame,
    n = n,
    pagesize = pagesize,
    col_metadata = col_metadata
  )

  if (all_metadata && !as_data_frame) {
    cli::cli_warn(
      "{.arg col_formatting} and {.arg display_nm} are not supported when
      {.arg all_metadata = TRUE} and {.code as_data_frame = FALSE}"
    )

    return(sp_list_items)
  }

  #  FIXME: Return an empty data frame with an alert if there are no results
  # if (is.null(sp_list_items)) {
  #   sp_list_items <-
  # }

  if (col_formatting != "asis") {
    sp_list_items <- format_sp_list_date_cols(
      sp_list_items,
      col_metadata = col_metadata,
      tz = tz
    )

    # TODO: Implement support for formatting choice columns as factor
  }

  # FIXME: Implement some way to reorder columns
  # Reorder columns to put "id", "ContentType", "Modified", and "Created" first
  # nm <- union(
  #   c("id", "ContentType", "Modified", "Created"), names(sp_list_items)
  # )
  #
  # sp_list_items <- vctrs::vec_slice(
  #   sp_list_items,
  #   i = nm,
  #   error_call = call
  # )

  if (display_nm == "drop") {
    return(sp_list_items)
  }

  # Pull display names
  values <- pull_sp_list_display_names(col_metadata = col_metadata)

  # Use display names as labels
  if (display_nm == "label") {
    sp_list_items <- label_cols(
      sp_list_items,
      values = values
    )

    return(sp_list_items)
  }

  # Replace matching names with display names
  # NOTE: Column info includes fields that are not returned by the list_items
  # method
  nm <- names(sp_list_items)
  values_i <- match(names(values), nm)
  nm[values_i[!is.na(values_i)]] <- values[!is.na(values_i)]

  # Repair names since display names may not be unique
  .set_as_names(sp_list_items, nm, repair = name_repair)
}

#' [get_sp_list_items()] is a wrapper for [list_sp_list_items()].
#'
#' @rdname sp_list_item
#' @export
get_sp_list_items <- function(
  list_name = NULL,
  list_id = NULL,
  sp_list = NULL,
  ...,
  filter = NULL,
  select = NULL,
  order_by = NULL,
  order_dir = "desc",
  all_metadata = FALSE,
  as_data_frame = TRUE,
  col_formatting = c("asis", "date"),
  display_nm = c("drop", "label", "replace"),
  n = NULL,
  tz = Sys.timezone(),
  name_repair = "unique",
  pagesize = 5000,
  site_url = NULL,
  site = NULL,
  drive_name = NULL,
  drive_id = NULL,
  drive = NULL,
  call = caller_env()
) {
  list_sp_list_items(
    list_name = list_name,
    list_id = list_id,
    sp_list = sp_list,
    ...,
    filter = filter,
    select = select,
    order_by = order_by,
    order_dir = order_dir,
    all_metadata = all_metadata,
    as_data_frame = as_data_frame,
    col_formatting = col_formatting,
    display_nm = display_nm,
    n = n,
    tz = tz,
    name_repair = name_repair,
    pagesize = pagesize,
    site_url = site_url,
    site = site,
    drive_name = drive_name,
    drive_id = drive_id,
    drive = drive,
    call = call
  )
}

#' Format date time values
#' @returns A `POSIXct` vector parsed from `x` as UTC, with `tzone` set to
#'   `tz`.
#' @noRd
.ms365_dttm <- function(
  x,
  format = "%Y-%m-%dT%H:%M:%SZ",
  tz = Sys.timezone()
) {
  x <- as.POSIXct(x, format = format, tz = "UTC")
  attr(x, "tzone") <- tz
  x
}

#' Format a POSIXct or Date value as an unambiguous UTC string for the Graph
#' API
#'
#' The Graph API body is ultimately serialized with `jsonlite::toJSON()`,
#' whose default handling of POSIXct values (`format()`/`as.character()`)
#' respects the object's `tzone` attribute but appends no offset or "Z"
#' suffix. That ambiguous, offset-less string is then resolved by the Graph
#' API using something other than UTC (apparently the SharePoint site's
#' regional settings), silently shifting the stored instant. Converting to an
#' explicit `"%Y-%m-%dT%H:%M:%SZ"` UTC string before serialization avoids the
#' ambiguity entirely. This is the write-side mirror of `.ms365_dttm()`.
#' @returns If `x` is a `POSIXt` or `Date`, a string formatted as
#'   `"%Y-%m-%dT%H:%M:%SZ"` in UTC. Otherwise, `x` unmodified.
#' @noRd
.sp_dttm_to_graph <- function(x) {
  if (!inherits(x, c("POSIXt", "Date"))) {
    return(x)
  }

  strftime(x, format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
}

#' Adapted from the list_items method for `Microsoft365R::ms_list` objects
#' <https://github.com/Azure/Microsoft365R/blob/master/R/ms_list.R>
#' @returns If `simplify = FALSE` or `all_metadata = TRUE`, the raw paged list
#'   of item values. Otherwise, a data frame of item fields with every list
#'   column present (even if empty for all items).
#' @param ptype If "metadata" (default), blank columns are typed using the list
#'   column metadata (requested if `col_metadata` is `NULL`). If "select",
#'   blank columns named in `select` are filled with `NA` without requesting
#'   list metadata (for internal callers that only need a few columns).
#' @noRd
.ms365_list_items <- function(
  sp_list,
  filter = NULL,
  select = NULL,
  n = NULL,
  pagesize = 5000,
  order_by = NULL,
  order_dir = "desc",
  simplify = TRUE,
  all_metadata = FALSE,
  time_cols = c("Created", "Modified"),
  col_metadata = NULL,
  ptype = c("metadata", "select"),
  call = caller_env()
) {
  check_string(filter, allow_null = TRUE, call = call)
  ptype <- arg_match(ptype, error_call = call)

  # Preserve the "id" naming convention used by list metadata (see
  # sp_list_ptype_col_metadata()) for the ptype built below, independent of
  # the "ID" naming the Graph API query requires
  select_ptype <- select
  if (!is.null(select_ptype) && "ID" %in% select_ptype) {
    select_ptype[select_ptype == "ID"] <- "id"
  }

  options <- list(
    expand = "fields",
    `$filter` = filter,
    `$top` = pagesize
  )

  if (!is.null(select)) {
    check_character(select, call = call)

    if ("id" %in% select) {
      select[select == "id"] <- "ID"
    }

    options[["expand"]] <- paste0(
      "fields(select=",
      paste0(select, collapse = ","),
      ")"
    )
  }

  if (!is.null(order_by)) {
    options <- opt_order_by(
      options,
      order_by,
      order_dir,
      call
    )
  }

  headers <- httr::add_headers(
    Prefer = "HonorNonIndexedQueriesWarningMayFailRandomly"
  )

  check_ms_obj(sp_list, "ms_list", call = call)

  resp <- sp_list$do_operation(
    "items",
    options = options,
    headers,
    simplify = simplify
  )

  pager <- sp_list$get_list_pager(
    resp,
    site_id = sp_list$properties$parentReference$siteId,
    list_id = sp_list$properties$id
  )

  n <- n %||% Inf

  # get item list
  list_values <- .sp_extract_list_values(pager, n = n, simplify = simplify)

  # return the raw values if simplify is FALSE or all_metadata is TRUE
  if (!simplify || all_metadata) {
    return(list_values)
  }

  # format date/time columns using graph_dttm
  # for (nm in intersect(time_cols, names(list_values$fields))) {
  #   list_values$fields[, nm] <- .ms365_dttm(list_values$fields[, nm])
  # }

  # Guarantee every list column is present, in list order, even when a field
  # is empty for every returned item (and so is otherwise dropped entirely by
  # the Graph API)
  if (ptype == "select" && !is.null(select_ptype)) {
    # Untyped columns in select order, without requesting list metadata
    ptype_df <- vctrs::data_frame(
      !!!rep_named(select_ptype, list(vctrs::unspecified())),
      .name_repair = "minimal"
    )
  } else {
    ptype_df <- sp_list_as_ptype_data_frame(
      sp_list = sp_list,
      col_metadata = col_metadata,
      select = select_ptype
    )
  }

  list_items <- vctrs::vec_rbind(ptype_df, list_values$fields)

  # Graph returns an "@odata.etag" annotation with the fields for each item.
  # It isn't used, so it is only kept in the raw values (all_metadata = TRUE).
  list_items[names(list_items) != "@odata.etag"]
}

#' Extract list item values from a pager
#'
#' Wraps `AzureGraph::extract_list_values()`. `AzureGraph::ms_graph_pager`
#' sets its output type from the first page only. A filtered query on a list
#' with more items than the list view threshold (5,000) is evaluated in
#' batches, so the first pages can be empty. An empty page is parsed as
#' `list()` rather than a data frame, so the pager returns the remaining items
#' as `ms_list_item` objects and the item fields are lost. When `simplify =
#' TRUE`, this sets the pager output type to `"data.frame"` and skips empty
#' pages.
#' @param pager A `ms_graph_pager` object.
#' @param n Maximum number of items to return.
#' @param simplify If `TRUE`, return a data frame. If `FALSE`, return the
#'   output of `AzureGraph::extract_list_values()`.
#' @returns If `simplify = TRUE`, a data frame of item values or `NULL` if no
#'   items are returned.
#' @noRd
.sp_extract_list_values <- function(pager, n = Inf, simplify = TRUE) {
  if (!simplify) {
    return(AzureGraph::extract_list_values(pager, n))
  }

  pager$output <- "data.frame"

  pages <- list()
  n_items <- 0

  while (pager$has_data() && n_items < n) {
    page <- pager$value

    if (is.data.frame(page) && nrow(page) > 0) {
      pages <- c(pages, list(page))
      n_items <- n_items + nrow(page)
    }
  }

  if (length(pages) == 0) {
    return(NULL)
  }

  values <- vctrs::vec_rbind(!!!pages)

  if (nrow(values) > n) {
    values <- vctrs::vec_slice(values, seq_len(n))
  }

  values
}

#' Add orderby to options
#' @returns `opt` with a `"$orderby"` element appended.
#' @noRd
opt_order_by <- function(
  opt,
  order_by,
  order_dir = c("desc", "asc"),
  call = caller_env()
) {
  check_string(order_by, call = call)
  order_dir <- arg_match(order_dir, error_call = call)
  order_by <- paste0("fields/", order_by, " ", order_dir)

  c(
    opt,
    list(
      `$orderby` = order_by
    )
  )
}

#' Pull a vector of display names named with corresponding column names
#' @returns A named character vector of column display names, named with the
#'   corresponding column names.
#' @noRd
pull_sp_list_display_names <- function(sp_list = NULL, col_metadata = NULL) {
  col_metadata <- col_metadata %||% sp_list$get_column_info()

  set_names(
    pluck_sp_list_meta(col_metadata, "displayName"),
    pluck_sp_list_meta(col_metadata, "name")
  )
}

#' Format date and dateTime list columns as Date and POSIXct vectors
#' @param col_metadata List column metadata (a list of column definitions).
#' @returns `sp_list_items` with any "dateOnly" columns converted to Date and
#'   "dateTime" columns converted to POSIXct (in time zone `tz`).
#' @noRd
format_sp_list_date_cols <- function(
  sp_list_items,
  col_metadata,
  tz = Sys.timezone()
) {
  for (col in col_metadata) {
    nm <- col[["name"]]
    date_format <- col[["dateTime"]][["format"]]

    if (is.null(date_format) || !has_name(sp_list_items, nm)) {
      next
    }

    if (date_format == "dateOnly") {
      sp_list_items[[nm]] <- as.Date(.ms365_dttm(sp_list_items[[nm]], tz = tz))
    } else if (date_format == "dateTime") {
      # TODO: This option is not tested.
      sp_list_items[[nm]] <- .ms365_dttm(sp_list_items[[nm]], tz = tz)
    }
  }

  sp_list_items
}

#' @returns A named vector of item id values, named with the values of
#'   `column`.
#' @noRd
pull_sp_list_item_id <- function(
  sp_list = NULL,
  column = NULL,
  ...,
  .id = "id"
) {
  pull_sp_list_items_index(
    sp_list = sp_list,
    var = column,
    name = .id %||% column
  )
}

#' @returns A named vector with the values of `var`, named with the
#'   corresponding values of `name`.
#' @noRd
pull_sp_list_items_index <- function(
  sp_list_items = NULL,
  sp_list = NULL,
  var = NULL,
  ...,
  name = var
) {
  var_name_pair <- sp_list_items %||%
    list_sp_list_items(
      sp_list = sp_list,
      ...,
      select = c(var, name)
    )

  set_names(var_name_pair[[var]], var_name_pair[[name]])
}

#' @rdname sp_list_item
#' @name get_sp_list_item
#' @param id Required. A SharePoint list item ID typically an integer for the
#'   record number starting from 1 with the first record.
#' @export
get_sp_list_item <- function(
  id,
  list_name = NULL,
  list_id = NULL,
  sp_list = NULL,
  ...,
  site_url = NULL,
  site = NULL,
  drive_name = NULL,
  drive_id = NULL,
  drive = NULL,
  call = caller_env()
) {
  sp_list <- sp_list %||%
    get_sp_list(
      list_name = list_name,
      list_id = list_id,
      as_data_frame = FALSE,
      metadata = FALSE,
      ...,
      site_url = site_url,
      site = site,
      drive_name = drive_name,
      drive_id = drive_id,
      drive = drive,
      call = call
    )

  check_ms_obj(sp_list, "ms_list", call = call)

  check_required(id, call = call)
  id <- as.character(id)
  check_string(id, allow_empty = FALSE, call = call)

  cli::cli_progress_step(
    "Getting item {.val {id}}"
  )

  sp_list$get_item(id)
}

#' Create or update list items
#'
#' @details Validation of data with with `create_sp_list_items()`
#'
#' The handling of item creation when column names in `data` do not match the
#' fields names in the supplied list includes a few options:
#'
#' - If no names in data match fields in the list, the function errors and lists
#'   the field names.
#' - If all names in data match fields in the list the records are created. Any
#'   fields that do not have corresponding names in data remain blank.
#' - If any names in data do not match fields in the list, by default, those
#'   columns are dropped before adding items to the list.
#' - If `strict = TRUE` and any names in data to not match fields, the function
#'   errors.
#'
#' @aliases import_sp_list_items
#' @param data Required. A data frame or a list of named lists (one record per
#'   item) to import as items to the supplied or identified SharePoint list. If
#'   data is an sf object, the geometry column is coerced to text using
#'   [sf::st_as_text()]. For [update_sp_list_items()], each record must include
#'   an `.id` element and `data` can also be a single named list record for one
#'   item. Unlike a data frame, any field missing from a record is left
#'   unchanged, even when `na_fields = "replace"`. For
#'   [create_sp_list_items()], wrap a single record in a list (e.g.
#'   `list(record)`) and `data` must be a data frame if `create_list = TRUE`.
#' @param strict If `TRUE`, all column names in a data frame (or field names
#'   in a list of records) must match field names in the supplied SharePoint
#'   list. If `FALSE` (default), unmatched names are dropped with a message.
#'   Only used if `check_fields = TRUE`.
#' @param check_fields If `TRUE` (default), column names (or record field
#'   names) for the input data are matched to the fields of the list object.
#'   If `FALSE`, names aren't checked and the Graph API errors for any name
#'   that isn't a list field.
#' @inheritParams ms_graph_arg_terms
#' @inheritParams get_sp_list
#' @param allow_display_nm If `TRUE`, allow data to use list field display names
#'   instead of standard names. Note this requires a separate API call so may
#'   result in a slower request. Default `FALSE`.
#' @param .id Name of the column in `data` (or the element in each record if
#'   `data` is a list) with item ID values. Defaults to `"id"`. Item IDs must be
#'   whole numbers or non-empty strings and are checked before any items are
#'   updated. For [create_sp_list_items()], `.id` is only used to keep the ID
#'   column name from being replaced when `allow_display_nm = TRUE`. For
#'   [update_sp_list_item()], `.id` is used to get `item_id` from `.data` if
#'   `item_id` isn't supplied.
#' @param create_list If `TRUE` and `list_name` is supplied, a new list is
#' created using [data_as_column_definition_list()] to set the column
#' definitions for the list.
#' @param .batch If `TRUE` (default), items are sent with Microsoft Graph
#'   `$batch` requests (up to 20 items per request), which is much faster than
#'   a separate request for each item. Requests throttled by the Graph API are
#'   retried after the requested delay. If any items fail, the remaining items
#'   are still sent and the error lists the failed items. If `FALSE`, a
#'   separate request is sent for each item and the first failed item is an
#'   error. Use `options(sharepointr.batch = FALSE)` to change the default for
#'   the session. In either case, requests are sent in parallel if
#'   `mirai::daemons()` are set (see [purrr::in_parallel()]). For
#'   [create_sp_list_items()], items sent in a `$batch` request (or in
#'   parallel) may be created in a different order than `data`, so new item IDs
#'   may not follow the order of `data`. Use `.batch = FALSE` (without daemons)
#'   if item IDs must follow the order of `data`.
#' @inheritParams purrr::map
#' @examples
#' sp_list_url <- "<SharePoint List URL with a Name field>"
#'
#' if (is_sp_url(sp_list_url)) {
#'   create_sp_list_items(
#'     data = data.frame(
#'       Name = c("Jim", "Jane", "Jayden")
#'     ),
#'     list_name = sp_list_url
#'   )
#' }
#' @returns [create_sp_list_items()] and [update_sp_list_items()] invisibly
#'   return the input `data`, unmodified (even if `data` is empty).
#' @keywords lists
#' @export
create_sp_list_items <- function(
  data,
  list_name = NULL,
  list_id = NULL,
  sp_list = NULL,
  ...,
  allow_display_nm = FALSE,
  .id = "id",
  site_url = NULL,
  site = NULL,
  drive_name = NULL,
  drive_id = NULL,
  drive = NULL,
  check_fields = TRUE,
  sync_fields = FALSE,
  create_list = FALSE,
  strict = FALSE,
  .batch = getOption("sharepointr.batch", TRUE),
  .progress = TRUE,
  call = caller_env()
) {
  check_bool(.batch, call = call)
  input <- data

  # Check the input before any API calls (or creating a list)
  if (!is.data.frame(data)) {
    data <- as_sp_item_records(data, .id = NULL, call = call)

    if (create_list) {
      cli_abort(
        "{.arg data} must be a data frame when {.code create_list = TRUE}.",
        call = call
      )
    }
  }

  if (vctrs::vec_size(data) == 0) {
    cli::cli_bullets(
      c("!" = "List items can't be created when {.arg data} is empty.")
    )

    return(invisible(input))
  }

  if (create_list) {
    check_string(list_name, call = call)

    if (is_url(list_name)) {
      cli_abort(
        "{.arg list_name} must be the name of a new list and not a URL for an
        existing list when `create_list = TRUE`.",
        call = call
      )
    }

    sp_list <- create_sp_list(
      list_name = list_name,
      columns = data_as_column_definition_list(data),
      ...,
      site = site,
      site_url = site_url,
      call = call
    )
  }

  sp_list <- sp_list %||%
    get_sp_list(
      list_name = list_name,
      list_id = list_id,
      metadata = FALSE,
      as_data_frame = FALSE,
      ...,
      site_url = site_url,
      site = site,
      drive_name = drive_name,
      drive_id = drive_id,
      drive = drive,
      call = call
    )

  # Get column definitions once to validate fields, use display names, and find
  # multi-value fields
  col_metadata <- get_sp_list_metadata(
    sp_list = sp_list,
    sync_fields = sync_fields,
    as_data_frame = FALSE,
    call = call
  )

  display_nm <- NULL

  if (allow_display_nm) {
    display_nm <- pull_sp_list_display_names(col_metadata = col_metadata)
  }

  field_nm <- names(pull_sp_list_cols(col_metadata, col_type = "editable"))

  if (is.data.frame(data)) {
    # Coerce sf column to WKT
    data <- sfc_cols_as_wkt(data)

    if (allow_display_nm) {
      data <- replace_with_sp_list_display_names(
        data,
        .id = .id,
        values = display_nm,
        call = call
      )
    }

    if (check_fields) {
      data <- validate_sp_list_data_fields(
        data,
        values = field_nm,
        strict = strict,
        call = call
      )
    }

    records <- vctrs::vec_chop(data)
  } else {
    records <- purrr::map(
      data,
      \(x) {
        if (allow_display_nm) {
          x <- replace_with_sp_list_display_names(
            x,
            .id = .id,
            values = display_nm,
            call = call
          )
        }

        sfc_cols_as_wkt(x)
      }
    )

    if (check_fields) {
      records <- validate_sp_item_record_fields(
        records,
        values = field_nm,
        strict = strict,
        call = call
      )
    }
  }

  # Multi-value (Collection) columns need an "@odata.type" annotation even when
  # a single value is selected
  multi_fields <- pull_sp_list_multi_cols(col_metadata = col_metadata)

  cli_progress_step(
    "Importing {.arg data} into list"
  )

  if (.batch) {
    fields <- purrr::map(
      records,
      \(record) {
        prep_sp_list_item_create_fields(record, multi_fields = multi_fields)
      }
    )

    # Records without any values aren't created (as with create_sp_list_item())
    has_fields <- !purrr::map_lgl(fields, is_empty)

    responses <- sp_graph_batch_requests(
      sp_list[["token"]],
      purrr::map(
        fields[has_fields],
        \(x) sp_list_item_request(sp_list, "POST", fields = x)
      ),
      .progress = .progress,
      call = call
    )

    check_sp_batch_responses(
      responses,
      labels = paste("Record", which(has_fields)),
      action = "be created",
      call = call
    )

    return(invisible(input))
  }

  purrr::map(
    records,
    purrr::in_parallel(
      \(record) {
        fn(
          .sp_list = .sp_list,
          .fields = record,
          .multi_fields = .multi_fields
        )
      },
      fn = create_sp_list_item,
      .sp_list = sp_list,
      .multi_fields = multi_fields
    ),
    .progress = .progress
  )

  invisible(input)
}

#' @returns `data` unmodified if every column name matches a list field name.
#'   If only some names match, `data` with unmatched columns dropped (with a
#'   message), unless `strict = TRUE`, in which case it errors. Errors if no
#'   column names match.
#' @noRd
validate_sp_list_data_fields <- function(
  data,
  sp_list = NULL,
  values = NULL,
  sync_fields = FALSE,
  keep = "editable",
  strict = FALSE,
  values_from = "name",
  drop_fields = c("ContentType", "Attachments"),
  call = caller_env()
) {
  if (is.null(values)) {
    sp_list_meta <- get_sp_list_metadata(
      sp_list = sp_list,
      sync_fields = sync_fields,
      keep = keep,
      call = call
    )

    values <- sp_list_meta[[values_from]]

    # TODO: Use sp_list_meta to append LookupId suffix to person or lookup
    # column types
  }

  nm_match <- match_sp_list_field_names(
    names(data),
    values = values,
    drop_fields = drop_fields,
    strict = strict,
    what = if (is.data.frame(data)) "column" else "field",
    call = call
  )

  if (all(nm_match)) {
    return(data)
  }

  if (is.data.frame(data)) {
    return(data[, nm_match, drop = FALSE])
  }

  data[nm_match]
}

#' Match names in list item data to list field names
#'
#' @param nm Names from a data frame or from list item records.
#' @param values List field names.
#' @param what Word used for the names in messages (e.g. `"column"` for a data
#'   frame or `"field"` for list records).
#' @returns A logical vector the same length as `nm` that is `TRUE` for names
#'   to keep. Names that don't match are dropped with a message, unless `strict
#'   = TRUE`, in which case it errors. Errors if no names match.
#' @noRd
match_sp_list_field_names <- function(
  nm,
  values,
  drop_fields = c("ContentType", "Attachments"),
  strict = FALSE,
  what = "column",
  arg = "data",
  call = caller_env()
) {
  # Drop fields that are not typically user-editable
  if (!is.null(drop_fields)) {
    values <- setdiff(values, drop_fields)
  }

  nm_match <- (nm %in% values) |
    # Always allow names that end in LookupId
    stringr::str_detect(nm, "LookupId")

  # FIXME: If strict is `TRUE` should this require that all values are also
  # present in nm?
  if (all(nm_match)) {
    return(nm_match)
  }

  allowed_nm_msg <- "Field name{?s} from list are {.val {values}}"

  if (!any(nm_match)) {
    cli_abort(
      c(
        "At least one {what} in {.arg {arg}} must match field names in the
        supplied list.",
        "i" = allowed_nm_msg
      ),
      call = call
    )
  }

  msg <- "All {what} names in {.arg {arg}} must match field names in the
  supplied list."

  if (strict) {
    cli_abort(
      c(
        msg,
        "i" = allowed_nm_msg
      ),
      call = call
    )
  }

  what_title <- paste0(toupper(substr(what, 1, 1)), substring(what, 2))
  dropped <- nm[!nm_match]

  cli::cli_inform(
    c(
      "!" = msg,
      "i" = "{what_title}{cli::qty(length(dropped))}{?s} {.val {dropped}}
      dropped from {.arg {arg}}"
    )
  )

  nm_match
}

#' @rdname create_sp_list_items
#' @name update_sp_list_items
#' @param drop_fields Column names to drop from `data` even if they are listed
#' as editable fields. Defaults to `c("ContentType", "Attachments")`
#' @export
update_sp_list_items <- function(
  data,
  list_name = NULL,
  list_id = NULL,
  sp_list = NULL,
  ...,
  .id = "id",
  allow_display_nm = FALSE,
  check_fields = TRUE,
  strict = FALSE,
  na_fields = c("drop", "replace"),
  drop_fields = c("ContentType", "Attachments"),
  .batch = getOption("sharepointr.batch", TRUE),
  .progress = TRUE,
  call = caller_env()
) {
  check_bool(.batch, call = call)
  input <- data

  if (is.data.frame(data) && nrow(data) == 0) {
    data <- list()
  }

  # Check the input and item ids before any API calls
  if (!is.data.frame(data)) {
    data <- as_sp_item_records(data, .id = .id, call = call)
  }

  item_ids <- as_sp_item_ids(data, .id = .id, arg = "data", call = call)

  if (has_length(item_ids, 0)) {
    cli::cli_bullets(
      c("!" = "List items can't be updated when {.arg data} is empty.")
    )

    return(invisible(input))
  }

  sp_list <- sp_list %||%
    get_sp_list(
      list_name = list_name,
      as_data_frame = FALSE,
      list_id = list_id,
      ...,
      call = call
    )

  check_ms_obj(sp_list, "ms_list", call = call)

  # Get column definitions once to validate fields and find multi-value fields
  col_metadata <- get_sp_list_metadata(
    sp_list = sp_list,
    as_data_frame = FALSE,
    call = call
  )

  field_nm <- NULL

  if (check_fields) {
    field_nm <- names(pull_sp_list_cols(col_metadata, col_type = "editable"))
  }

  display_nm <- NULL

  if (allow_display_nm) {
    display_nm <- pull_sp_list_display_names(col_metadata = col_metadata)
  }

  if (is.data.frame(data)) {
    if (allow_display_nm) {
      data <- replace_with_sp_list_display_names(
        data,
        .id = .id,
        values = display_nm,
        call = call
      )
    }

    # Coerce sf column to WKT (consistent with create_sp_list_items())
    update_data <- sfc_cols_as_wkt(data)
    update_data[[.id]] <- NULL

    if (check_fields) {
      update_data <- validate_sp_list_data_fields(
        update_data,
        values = field_nm,
        drop_fields = drop_fields,
        strict = strict,
        call = call
      )
    }

    records <- vctrs::vec_chop(update_data)
  } else {
    records <- purrr::map(
      data,
      \(x) {
        if (allow_display_nm) {
          x <- replace_with_sp_list_display_names(
            x,
            .id = .id,
            values = display_nm,
            call = call
          )
        }

        x <- sfc_cols_as_wkt(x)
        x[names(x) != .id]
      }
    )

    if (check_fields) {
      records <- validate_sp_item_record_fields(
        records,
        values = field_nm,
        drop_fields = drop_fields,
        strict = strict,
        call = call
      )
    }
  }

  # Multi-value (Collection) columns need an "@odata.type" annotation even when
  # a single value is selected
  multi_fields <- pull_sp_list_multi_cols(col_metadata = col_metadata)

  if (.batch) {
    na_fields <- arg_match(na_fields, error_call = call)

    fields <- purrr::map(
      records,
      \(record) {
        prep_sp_list_item_update_fields(
          record,
          na_fields = na_fields,
          multi_fields = multi_fields
        )
      }
    )

    # Items without any values after dropping NA values aren't updated (as
    # with update_sp_list_item())
    has_fields <- !purrr::map_lgl(fields, is.null)

    if (!all(has_fields)) {
      skipped_ids <- item_ids[!has_fields]

      cli::cli_bullets(
        c(
          "!" = "{length(skipped_ids)} item{?s} {?is/are} empty after dropping
          `NA` and empty values.",
          "Item{?s} {.val {skipped_ids}} can't be updated."
        )
      )
    }

    cli_progress_step(
      "Updating {sum(has_fields)} list item{?s}"
    )

    responses <- sp_graph_batch_requests(
      sp_list[["token"]],
      purrr::map2(
        fields[has_fields],
        item_ids[has_fields],
        \(x, item_id) {
          sp_list_item_request(sp_list, "PATCH", item_id = item_id, fields = x)
        }
      ),
      .progress = .progress,
      call = call
    )

    check_sp_batch_responses(
      responses,
      labels = paste("Item", item_ids[has_fields]),
      action = "be updated",
      call = call
    )

    return(invisible(input))
  }

  purrr::map2(
    records,
    item_ids,
    purrr::in_parallel(
      \(record, item_id) {
        fn(
          .data = record,
          na_fields = na_fields,
          item_id = item_id,
          sp_list = sp_list,
          # Fields are already validated (or skipped) for all items
          check_fields = FALSE,
          .multi_fields = .multi_fields,
          call = call
        )
      },
      fn = update_sp_list_item,
      na_fields = na_fields,
      sp_list = sp_list,
      .multi_fields = multi_fields,
      call = call
    ),
    .progress = .progress
  )

  invisible(input)
}

#' Is `x` a list of list item records?
#' @returns `TRUE` if `x` is an unnamed list where every element is a named
#'   list (and not a data frame), `FALSE` otherwise.
#' @noRd
is_list_of_records <- function(x) {
  is.list(x) &&
    !is.data.frame(x) &&
    !is_named(x) &&
    all(
      purrr::map_lgl(
        x,
        \(record) {
          is.list(record) && !is.data.frame(record) && is_named(record)
        }
      )
    )
}

#' Convert a single record or a named list of records to a list of records
#' @param .id Name of the id element used to recognize a single record. If
#'   `NULL`, a single record isn't recognized (e.g. for new items without ids).
#' @returns If `x` is a single record (a named list with a length 1, non-list
#'   `.id` element), a list containing `x`. If `x` is a named list of records,
#'   `x` with names removed. Otherwise, `x` unmodified.
#' @noRd
as_list_of_records <- function(x, .id = "id") {
  if (!is.list(x) || is.data.frame(x) || !is_named(x)) {
    return(x)
  }

  if (
    !is.null(.id) &&
      has_name(x, .id) &&
      !is.list(x[[.id]]) &&
      has_length(x[[.id]], 1)
  ) {
    return(list(x))
  }

  records <- unname(x)

  if (is_list_of_records(records)) {
    return(records)
  }

  x
}

#' Convert list item input to a list of records
#'
#' Used for list (not data frame) input to the create, update, and delete list
#' item functions and the lookup item functions so they accept the same
#' inputs.
#' @inheritParams as_list_of_records
#' @returns An unnamed list of records (named lists). Errors if `data` is not a
#'   single record (if `.id` is supplied) or a named or unnamed list of
#'   records.
#' @noRd
as_sp_item_records <- function(
  data,
  .id = "id",
  arg = caller_arg(data),
  call = caller_env()
) {
  records <- as_list_of_records(data, .id = .id)

  if (is_list_of_records(records)) {
    return(records)
  }

  if (is.null(.id)) {
    cli_abort(
      c(
        "{.arg {arg}} must be a data frame or a list of named lists (one per
        item), not {.obj_type_friendly {data}}.",
        "i" = "Use {.code list(record)} for a single item."
      ),
      call = call
    )
  }

  cli_abort(
    c(
      "{.arg {arg}} must be a data frame, a named list for a single item, or
      a list of named lists, not {.obj_type_friendly {data}}.",
      "i" = "Each named list must include a single {.val {(.id)}} value."
    ),
    call = call
  )
}

#' Get item id values from a vector, data frame, or list of records
#'
#' Ids are validated before any items are changed so a missing or invalid id
#' doesn't stop a batch of updates or deletions partway through.
#' @param x A vector or unnamed list of id values, a data frame with a `.id`
#'   column, or a single record or list of records with a `.id` element.
#' @returns A character vector of item ids. Errors if any id isn't a single
#'   non-missing whole number or non-empty string.
#' @noRd
as_sp_item_ids <- function(
  x,
  .id = "id",
  arg = caller_arg(x),
  call = caller_env()
) {
  if (is.data.frame(x)) {
    if (!has_name(x, .id)) {
      cli_abort(
        "{.arg {arg}} must have a column named {.val {(.id)}}.",
        call = call
      )
    }

    ids <- as.list(x[[.id]])
  } else if (is.list(x) && !is_named(x) && !any(purrr::map_lgl(x, is.list))) {
    # An unnamed list of id values
    ids <- x
  } else if (is.list(x)) {
    records <- as_sp_item_records(x, .id = .id, arg = arg, call = call)
    ids <- purrr::map(records, \(record) record[[.id]])
  } else {
    ids <- as.list(x)
  }

  is_valid <- purrr::map_lgl(ids, is_sp_item_id)

  if (!all(is_valid)) {
    invalid_i <- which(!is_valid)

    cli_abort(
      c(
        "Each item id in {.arg {arg}} must be a whole number or a non-empty
        string.",
        "x" = "{cli::qty(length(invalid_i))}Item{?s} with a missing or invalid
        {.val {(.id)}} value: {invalid_i}."
      ),
      call = call
    )
  }

  purrr::map_chr(
    ids,
    \(id) if (is.numeric(id)) sprintf("%.0f", id) else id
  )
}

#' Is `x` a valid list item id?
#' @noRd
is_sp_item_id <- function(x) {
  (is_string(x) && nzchar(x)) ||
    (is_scalar_integerish(x) && !is.na(x))
}

#' Validate the field names of a list of records
#'
#' Validates the names from all records at once so any unmatched names are
#' reported in a single message, then drops unmatched names from each record.
#' @noRd
validate_sp_item_record_fields <- function(
  records,
  values,
  drop_fields = c("ContentType", "Attachments"),
  strict = FALSE,
  call = caller_env()
) {
  record_nm <- unique(unlist(purrr::map(records, names))) %||% character(0)

  nm_match <- match_sp_list_field_names(
    record_nm,
    values = values,
    drop_fields = drop_fields,
    strict = strict,
    what = "field",
    call = call
  )

  valid_nm <- record_nm[nm_match]

  purrr::map(records, \(x) x[names(x) %in% valid_nm])
}

#' Replace names for a data frame or list with display names
#' @returns `data` with any names matching a display name in `values`
#'   replaced by the corresponding column name.
#' @noRd
replace_with_sp_list_display_names <- function(
  data,
  .id = "id",
  sp_list = NULL,
  values = NULL,
  ...,
  call = caller_env()
) {
  nm <- names(data)
  list_display_nm <- values %||% pull_sp_list_display_names(sp_list)
  nm_i <- match(nm, list_display_nm, incomparables = .id)
  nm_match <- !is.na(nm_i)
  nm[nm_match] <- names(list_display_nm)[nm_i[nm_match]]

  .set_as_names(data, nm, repair = "check_unique", call = call)
}

#' @rdname create_sp_list_items
#' @name update_sp_list_item
#' @param sp_list_item Optional. A SharePoint list item object to update.
#' @param item_id A SharePoint list item id. Either `item_id` or `sp_list_item`
#' must be provided but not both.
#' @param .data A list or data frame with fields to update.
#' @param na_fields How to handle `NA` fields in input data. One of `"drop"`
#'   (remove `NA` and empty fields, e.g. a multi-select value of
#'   `character(0)`, before updating list items, leaving existing values in
#'   place) or `"replace"` (overwrite existing list values with new replacement
#'   NA values or, for multi-value fields, an empty selection).
#' @param .multi_fields Optional. Names of multi-value (Collection) fields, such
#'   as multi-select choice columns, that should always be sent as an array with
#'   an `"@odata.type"` annotation. If `NULL` and `sp_list` is available, field
#'   names are found from the list column definitions. Otherwise, only fields
#'   with a length other than 1 are treated as multi-value fields.
#' @keywords lists
#' @export
update_sp_list_item <- function(
  ...,
  .data = NULL,
  item_id = NULL,
  sp_list_item = NULL,
  .id = "id",
  check_fields = TRUE,
  na_fields = c("drop", "replace"),
  drop_fields = c("ContentType", "Attachments"),
  list_name = NULL,
  list_id = NULL,
  sp_list = NULL,
  site_url = NULL,
  site = NULL,
  drive_name = NULL,
  drive_id = NULL,
  drive = NULL,
  .multi_fields = NULL,
  call = caller_env()
) {
  # TODO: Allow option to get id from .data
  .data <- .data %||% list2(...)

  # Check for a data frame provided with the ... argument
  if (has_length(.data, 1) && is.data.frame(.data[[1]])) {
    cli_abort(
      "You must use {.arg .data} to update a list item with a data frame.",
      call = call
    )
  }

  # Coerce sf column to WKT (consistent with create_sp_list_items())
  .data <- sfc_cols_as_wkt(.data)

  # NOTE: This is not type stable since the output will be converted to a list
  # and drop or replace NA values
  if (is.data.frame(.data)) {
    # FIXME: is it OK that .data supports both lists and data frames?
    n_row_data <- nrow(.data)

    if (nrow(.data) > 1) {
      cli_abort(
        c(
          "{.arg data} must be a single row, not {n_row_data}.",
          "i" = "Use {.fn update_sp_list_items} to update a list
          with a multi-row data frame."
        ),
        call = call
      )
    }

    # Convert data frame to list
    # FIXME: Double-check if this creates any issue when specifying values for
    # more complex list field types
    .data <- as.list(.data)
  }

  # Unwrap list-column values (e.g. multi-select choice values) so each field
  # is a vector instead of a length 1 list
  .data <- unwrap_list_fields(.data)

  # Drop or replace NA fields
  na_fields <- arg_match(na_fields, error_call = call)
  .data <- prep_sp_list_item_na_fields(.data, na_fields = na_fields)

  # Only the item id (or nothing) is left
  if (na_fields == "drop" && all(names(.data) %in% .id)) {
    cli::cli_bullets(
      c(
        "!" = "{.arg .data} is empty after dropping `NA` and empty values.",
        "Item can't be updated."
      )
    )

    return(invisible(.data))
  }

  # Fill item id value from input list or data frame
  item_id <- item_id %||% .data[[.id]]
  # Drop .id column from .data (if present)
  update_data <- .data
  update_data[[.id]] <- NULL

  check_exclusive_args(item_id, sp_list_item, call = call)

  if (is.null(sp_list_item) && !is.null(item_id)) {
    sp_list <- sp_list %||%
      get_sp_list(
        list_name = list_name,
        as_data_frame = FALSE,
        list_id = list_id,
        site_url = site_url,
        site = site,
        drive_name = drive_name,
        drive_id = drive_id,
        drive = drive,
        call = call
      )

    check_ms_obj(sp_list, "ms_list", call = call)

    # Get column definitions once to validate fields and find multi-value fields
    if (is.null(.multi_fields) || check_fields) {
      col_metadata <- get_sp_list_metadata(
        sp_list = sp_list,
        as_data_frame = FALSE,
        call = call
      )

      .multi_fields <- .multi_fields %||%
        pull_sp_list_multi_cols(col_metadata = col_metadata)
    }

    if (check_fields) {
      update_data <- suppressMessages(
        validate_sp_list_data_fields(
          update_data,
          values = names(
            pull_sp_list_cols(col_metadata, col_type = "editable", call = call)
          ),
          drop_fields = c(.id, drop_fields)
        )
      )
    }
  } else {
    # TODO: Implement check_fields if `sp_list_item` is supplied
  }

  update_data <- as_graph_item_fields(update_data, multi_fields = .multi_fields)

  if (!is.null(sp_list)) {
    cli_progress_step(
      "Updating item {.val {item_id}}"
    )

    # The update_item method gets the item before the update and again after
    # https://learn.microsoft.com/en-us/graph/api/listitem-update?view=graph-rest-1.0&tabs=http
    withCallingHandlers(
      sp_list$do_operation(
        paste0("items/", item_id),
        body = list(fields = update_data),
        encode = "json",
        http_verb = "PATCH"
      ),
      error = function(cnd) {
        cli_abort(
          cnd$message,
          call = call
        )
      }
    )
  } else if (!is.null(sp_list_item)) {
    check_ms_obj(sp_list_item, "ms_list_item", call = call)

    item_id <- sp_list_item[["properties"]][["id"]]

    cli_progress_step(
      "Updating item {.val {item_id}}"
    )

    # The update method gets the item again after the update
    withCallingHandlers(
      sp_list_item$do_operation(
        body = list(fields = update_data),
        encode = "json",
        http_verb = "PATCH"
      ),
      error = function(cnd) {
        cli_abort(
          cnd$message,
          call = call
        )
      }
    )
  }

  invisible(.data)
}

#' Append "@odata.type" fields for multi-value (Collection) fields
#'
#' Adds a sibling `"{name}@odata.type"` entry for any field named in
#' `multi_fields` or with a value of length other than 1 so the Graph API
#' recognizes the field as a Collection instead of a scalar. Multi-value field
#' values are converted to lists so they are serialized as JSON arrays (even
#' with a single value) when the request body is created with `auto_unbox =
#' TRUE`.
#' <https://learn.microsoft.com/en-us/rest/api/searchservice/supported-data-types#edm-data-types-for-nonvector-fields>
#' @param multi_fields Optional. Names of fields to always treat as multi-value
#'   fields.
#' @returns `fields` unmodified if no element is a multi-value field.
#'   Otherwise, `fields` with multi-value field values converted to lists and a
#'   `"{name}@odata.type"` element appended for each multi-value field.
#' @noRd
append_field_odata_types <- function(fields, multi_fields = NULL) {
  is_multi <- (names(fields) %in% multi_fields) |
    purrr::map_lgl(
      fields,
      \(x) {
        !is.null(x) && !has_length(x, 1)
      }
    )

  if (!any(is_multi)) {
    return(fields)
  }

  # NA values can't be included in a Collection so all NA values (e.g. from
  # `na_fields = "replace"`) are replaced with an empty Collection
  multi_values <- purrr::imap(
    fields[is_multi],
    \(x, name) {
      if (is.null(x) || all(is.na(x))) {
        x <- character(0)
      }

      x <- x[!is.na(x)]

      # Lookup ID values (often returned as strings) must be sent as a
      # Collection of integers
      if (endsWith(name, "LookupId")) {
        x <- as_lookup_id_integer(x, name)
      }

      x
    }
  )

  odata_types <- purrr::map(
    multi_values,
    \(x) {
      # TODO: Add support for additional Collection types
      if (is.character(x) || is.factor(x)) {
        "Collection(Edm.String)"
      } else if (is.numeric(x)) {
        "Collection(Edm.Int32)"
      } else if (is.logical(x)) {
        "Collection(Edm.Boolean)"
      }
    }
  )

  fields[is_multi] <- purrr::map(multi_values, as.list)

  c(
    fields,
    set_names(
      odata_types,
      paste0(
        names(multi_values),
        "@odata.type"
      )
    )
  )
}

#' Drop `NA` and empty fields
#'
#' Used by [update_sp_list_item()] when `na_fields = "drop"` so existing list
#' values are left in place for fields that are `NULL`, `NA`, all `NA` (for
#' multi-value fields), or empty (e.g. a multi-select value of `character(0)`).
#' @returns `fields` with any `NULL`, empty, or all `NA` elements removed.
#' @noRd
drop_na_fields <- function(fields) {
  purrr::discard(
    fields,
    \(x) {
      is.null(x) || all(is.na(x))
    }
  )
}

#' Drop or replace `NA` fields for a list item update
#' @param na_fields If "drop", drop `NA` and empty fields with
#'   `drop_na_fields()`. If "replace", replace any `NA` values (e.g.
#'   `NA_integer_` or `NA_real_`) with `NA` so the field is cleared.
#' @returns `fields` with `NA` fields dropped or replaced.
#' @noRd
prep_sp_list_item_na_fields <- function(fields, na_fields = "drop") {
  if (na_fields == "drop") {
    return(drop_na_fields(fields))
  }

  vctrs::vec_assign(fields, i = is.na(fields), value = NA)
}

#' Prepare fields to create a list item
#'
#' Used by [create_sp_list_item()] and [create_sp_list_items()] (for $batch
#' requests).
#' @param fields A named list or single row data frame.
#' @param keep_na If `FALSE`, drop fields with all `NA` values (required for
#'   number fields).
#' @returns A named list of fields for the Graph API request body (possibly
#'   empty).
#' @noRd
prep_sp_list_item_create_fields <- function(
  fields,
  keep_na = FALSE,
  multi_fields = NULL
) {
  if (is.data.frame(fields)) {
    stopifnot(nrow(fields) == 1)
    fields <- as.list(fields)
  }

  # Coerce sf column to WKT (consistent with create_sp_list_items())
  fields <- sfc_cols_as_wkt(fields)

  # Unwrap list-column values (e.g. multi-select choice values) so each field
  # is a vector instead of a length 1 list
  fields <- unwrap_list_fields(fields)

  if (!keep_na) {
    fields <- purrr::discard(fields, \(x) all(is.na(x)))
  }

  # Drop NULL values
  fields <- purrr::compact(fields)

  if (is_empty(fields)) {
    return(fields)
  }

  as_graph_item_fields(fields, multi_fields = multi_fields)
}

#' Prepare fields to update a list item
#'
#' Used by [update_sp_list_items()] (for $batch requests) with the same steps
#' as [update_sp_list_item()].
#' @param fields A named list or single row data frame without the item id.
#' @returns A named list of fields for the Graph API request body or `NULL` if
#'   no fields are left after dropping `NA` fields.
#' @noRd
prep_sp_list_item_update_fields <- function(
  fields,
  na_fields = "drop",
  multi_fields = NULL
) {
  if (is.data.frame(fields)) {
    fields <- as.list(fields)
  }

  fields <- unwrap_list_fields(fields)
  fields <- prep_sp_list_item_na_fields(fields, na_fields = na_fields)

  if (na_fields == "drop" && is_empty(fields)) {
    return(NULL)
  }

  as_graph_item_fields(fields, multi_fields = multi_fields)
}

#' Convert fields to the values sent to the Graph API
#'
#' Converts POSIXct/Date fields to unambiguous UTC strings (before the request
#' body is serialized) and appends "@odata.type" fields so multi-value
#' (Collection) columns are recognized by the Graph API.
#' @returns `fields` with converted date fields and any "@odata.type" fields.
#' @noRd
as_graph_item_fields <- function(fields, multi_fields = NULL) {
  fields <- purrr::map(fields, .sp_dttm_to_graph)
  append_field_odata_types(fields, multi_fields = multi_fields)
}

#' Convert lookup ID values to integers
#' @returns `x` as an integer vector. Errors if any value can't be converted to
#'   a whole number.
#' @noRd
as_lookup_id_integer <- function(x, name, call = caller_env()) {
  if (is.integer(x)) {
    return(x)
  }

  int_x <- suppressWarnings(as.integer(x))

  if (any(is.na(int_x)) || any(int_x != as.numeric(x))) {
    cli_abort(
      "{.field {name}} values must be whole numbers.",
      call = call
    )
  }

  int_x
}

#' Unwrap list-column values from a single row data frame
#'
#' Converting a single row of a data frame with a list-column to a list returns
#' each list-column value as a length 1 list (e.g. `list(c("A", "B"))`). This
#' unwraps those values (e.g. to `c("A", "B")`) so they can be recognized as
#' multi-value fields and serialized as a JSON array instead of a nested array.
#' `sfc` columns are not unwrapped and should be converted with
#' `sfc_cols_as_wkt()` first.
#' @returns `fields` with any length 1 list values replaced by their contents.
#' @noRd
unwrap_list_fields <- function(fields) {
  is_wrapped <- purrr::map_lgl(
    fields,
    \(x) {
      is.list(x) &&
        !is.data.frame(x) &&
        !inherits(x, "sfc") &&
        has_length(x, 1)
    }
  )

  if (!any(is_wrapped)) {
    return(fields)
  }

  fields[is_wrapped] <- purrr::map(fields[is_wrapped], \(x) x[[1]])
  fields
}

#' Convert sfc columns to well-known text
#'
#' Converts any `sfc` column (including the active geometry column of an `sf`
#' object) in a data frame or list to a character vector of well-known text
#' (WKT) so geometry can be written to a SharePoint text column.
#' @returns `data` with any `sfc` columns converted to character vectors and
#'   the `sf` class dropped.
#' @noRd
sfc_cols_as_wkt <- function(data) {
  is_sfc <- purrr::map_lgl(data, \(x) inherits(x, "sfc"))

  if (!any(is_sfc)) {
    return(data)
  }

  check_installed("sf")

  wkt <- purrr::map(data[is_sfc], sf::st_as_text)

  if (inherits(data, "sf")) {
    data <- sf::st_drop_geometry(data)
  }

  data[names(wkt)] <- wkt
  data
}

#' Get the names of multi-value (Collection) columns for a SharePoint list
#'
#' Names use the same convention as list item data (e.g. "{name}LookupId" for
#' lookup and personOrGroup columns).
#' @returns A character vector of column names for columns that allow multiple
#'   values.
#' @noRd
pull_sp_list_multi_cols <- function(sp_list = NULL, col_metadata = NULL) {
  col_metadata <- sp_list_ptype_col_metadata(
    sp_list = sp_list,
    col_metadata = col_metadata
  )

  names(purrr::keep(col_metadata, sp_list_col_is_multi)) %||% character(0)
}

#' Alternate syntax for create list item
#'
#' [create_sp_list_item()] is an alternative to the `create_item` method for
#' `Microsoft365R::ms_list` objects. This is used by [create_sp_list_items()]
#' (instead of the `bulk_import` method) to better handle NA values that broken
#' for number columns.
#'
#' @param .sp_list A `ms_list` object.
#' @param .fields A named list or single row data frame.
#' @param ... Ignored if .fields is supplied.
#' @param .multi_fields Optional. Names of multi-value (Collection) fields, such
#'   as multi-select choice columns, that should always be sent as an array with
#'   an `"@odata.type"` annotation. If `NULL`, only fields with a length other
#'   than 1 are treated as multi-value fields.
#' @keywords internal
#' @export
create_sp_list_item <- function(
  ...,
  .sp_list = NULL,
  .fields = NULL,
  .keep_na = FALSE,
  .multi_fields = NULL
) {
  .fields <- .fields %||% rlang::list2(...)

  .fields <- prep_sp_list_item_create_fields(
    .fields,
    keep_na = .keep_na,
    multi_fields = .multi_fields
  )

  if (is_empty(.fields)) {
    # FIXME: Add warning if .fields has no valid input
    return(invisible(.fields))
  }

  # TODO: Add check if data in .fields matches schema from list

  resp <- .sp_list$do_operation(
    "items",
    body = list(
      fields = .fields
    ),
    http_verb = "POST"
  )

  # TODO: Add printing for resp info
  invisible(.fields)
}

#' Delete SharePoint list item or items
#'
#' [delete_sp_list_item()] deletes a single SharePoint list item and
#' [delete_sp_list_items()] deletes multiple SharePoint list items. Set
#' `confirm = FALSE` to use without interactive confirmation.
#'
#' @param item_id ID value for list item or items to delete. `item_id` can also
#'   be a data frame with a column named with the `.id` value, a single named
#'   list record, or (for [delete_sp_list_items()]) a list of named lists (one
#'   per item) where each record includes an element named with the `.id`
#'   value. Item IDs must be whole numbers or non-empty strings and are checked
#'   before any items are deleted. [delete_sp_list_item()] requires a single
#'   item ID.
#' @param .id Name of column (if `item_id` is a data frame) or element (if
#'   `item_id` is a list of records) to use for item ID values. Defaults to
#'   "id".
#' @param ... For [delete_sp_list_item()], must be empty. For
#'   [delete_sp_list_items()], additional parameters passed to [get_sp_list()]
#'   if `sp_list` is `NULL`.
#' @param sp_list_item Optional. A SharePoint list item object to delete.
#' @inheritParams get_sp_list_item
#' @param confirm If `TRUE` (default), user confirmation is required to delete
#' items.
#' @returns For [delete_sp_list_item()], invisibly returns an empty list with
#'   a `"status"` attribute giving the HTTP response status code. For
#'   [delete_sp_list_items()], invisibly returns a list of these responses,
#'   one per deleted item.
#' @keywords lists
#' @export
delete_sp_list_item <- function(
  item_id = NULL,
  sp_list_item = NULL,
  ...,
  .id = "id",
  list_name = NULL,
  list_id = NULL,
  sp_list = NULL,
  site_url = NULL,
  site = NULL,
  confirm = TRUE,
  call = caller_env()
) {
  check_dots_empty(call = call)

  # Get the id from a data frame or record before checking arguments
  if (!is.null(item_id)) {
    item_id <- as_sp_item_ids(item_id, .id = .id, call = call)

    if (!has_length(item_id, 1)) {
      cli_abort(
        c(
          "{.arg item_id} must be a single item id, not {length(item_id)}.",
          "i" = "Use {.fn delete_sp_list_items} to delete multiple items."
        ),
        call = call
      )
    }
  }

  check_exclusive_args(item_id, sp_list_item, call = call)

  sp_list_item <- sp_list_item %||%
    get_sp_list_item(
      id = item_id,
      list_name = list_name,
      list_id = list_id,
      sp_list = sp_list,
      site_url = site_url,
      site = site,
      call = call
    )

  item_id <- item_id %||% sp_list_item[["properties"]][["id"]]

  if (confirm) {
    check_yes(
      cli::format_inline("Do you want to delete list item {.val {item_id}}?"),
      call = call
    )
  }

  cli_progress_step(
    "Deleting item {.val {item_id}}"
  )

  check_ms_obj(sp_list_item, "ms_list_item", call = call)

  # https://learn.microsoft.com/en-us/graph/api/listitem-delete?view=graph-rest-1.0&tabs=http
  resp <- sp_list_item$do_operation(
    http_verb = "DELETE"
  )

  invisible(resp)
}

#' @rdname delete_sp_list_item
#' @inheritParams list_sp_list_items
#' @inheritParams create_sp_list_items
#' @param filter Optional. A string with an OData filter expression used to
#'   find the items to delete if `item_id` is `NULL`. Can't be supplied with
#'   `item_id`. See [list_sp_list_items()].
#' @inheritParams purrr::map
#' @export
delete_sp_list_items <- function(
  item_id = NULL,
  ...,
  .id = "id",
  sp_list = NULL,
  filter = NULL,
  confirm = TRUE,
  .batch = getOption("sharepointr.batch", TRUE),
  .progress = TRUE,
  call = caller_env()
) {
  check_bool(.batch, call = call)

  if (!is.null(item_id) && !is.null(filter)) {
    cli_abort(
      "Supply {.arg item_id} or {.arg filter}, not both.",
      call = call
    )
  }

  # Check the item ids before any API calls
  if (!is.null(item_id)) {
    item_id <- as_sp_item_ids(item_id, .id = .id, call = call)
  }

  sp_list <- sp_list %||% get_sp_list(..., call = call)

  if (is.null(item_id)) {
    sp_list_items <- .ms365_list_items(
      sp_list = sp_list,
      filter = filter,
      select = "id",
      ptype = "select",
      call = call
    )

    item_id <- sp_list_items[["id"]]
  }

  if (rlang::has_length(item_id, 0)) {
    cli::cli_abort(
      "List items can't be deleted when {.arg item_id} is length 0.",
      call = call
    )
  }

  if (confirm) {
    check_yes(
      cli::format_inline(
        "Do you want to delete {length(item_id)} list item{?s}?"
      ),
      call = call
    )
  }

  # https://learn.microsoft.com/en-us/graph/api/listitem-delete?view=graph-rest-1.0&tabs=http
  if (.batch) {
    cli_progress_step("Deleting {length(item_id)} list item{?s}")

    responses <- sp_graph_batch_requests(
      sp_list[["token"]],
      purrr::map(
        item_id,
        \(i) sp_list_item_request(sp_list, "DELETE", item_id = i)
      ),
      .progress = .progress,
      call = call
    )

    check_sp_batch_responses(
      responses,
      labels = paste("Item", item_id),
      action = "be deleted",
      call = call
    )

    # Match the response for a single DELETE request
    resp_list <- purrr::map(
      responses,
      \(x) structure(list(), status = as.integer(x[["status"]]))
    )

    return(invisible(resp_list))
  }

  resp_list <- purrr::map(
    item_id,
    purrr::in_parallel(
      \(i) {
        sp_list$do_operation(
          op = paste0("items/", i),
          http_verb = "DELETE"
        )
      },
      sp_list = sp_list
    ),
    .progress = .progress
  )

  invisible(resp_list)
}

#' Get list column metadata renamed and ordered to match the data frame
#' returned for list items (ID -> id, lookup/personOrGroup columns -> "{name}LookupId")
#' @returns `col_metadata` (or list metadata fetched for `sp_list`) with
#'   names renamed to match the item data frame naming convention.
#' @noRd
sp_list_ptype_col_metadata <- function(
  sp_list = NULL,
  col_metadata = NULL
) {
  col_metadata <- col_metadata %||%
    get_sp_list_metadata(
      sp_list = sp_list,
      as_data_frame = FALSE
    )

  col_nm <- purrr::map_chr(col_metadata, "name")

  # Lookup (and equivalent) columns are returned as "{name}LookupId"
  is_lookup <- purrr::map_lgl(
    col_metadata,
    \(x) any(has_name(x, c("lookup", "personOrGroup")))
  ) &
    !(col_nm %in% sp_list_lookup_exempt_colnames)

  col_nm[is_lookup] <- paste0(col_nm[is_lookup], "LookupId")
  col_nm[col_nm == "ID"] <- "id"

  set_names(col_metadata, col_nm)
}

#' Does a column definition allow multiple values (a Collection field)?
#'
#' Checks the `allowMultipleValues`/`allowMultipleSelection` properties used
#' by lookup, personOrGroup, and term columns. Choice columns don't
#' consistently return `allowMultipleValues`, so `displayAs = "checkBoxes"`
#' (the only multi-select display option) is also treated as multi-valued.
#' @returns `TRUE` if the column definition `x` allows multiple values,
#'   `FALSE` otherwise.
#' @noRd
sp_list_col_is_multi <- function(x) {
  if (
    has_name(x, "choice") &&
      identical(x[["choice"]][["displayAs"]], "checkBoxes")
  ) {
    return(TRUE)
  }

  any(
    purrr::map_lgl(
      x,
      \(sub) {
        if (!is.list(sub)) {
          return(FALSE)
        }

        is_true(sub[["allowMultipleValues"]]) ||
          is_true(sub[["allowMultipleSelection"]])
      }
    )
  )
}

#' Ptype for a single list column, matching the type the Graph API returns
#' before any `col_formatting` is applied
#'
#' Multi-value (Collection) columns are represented as list-columns. A bare
#' `list()` is used instead of `vctrs::list_of()` since a `list_of` ptype
#' combined with the bare list-column from the Graph API is a bare list
#' anyway.
#' @returns A zero-length ptype vector (`double()`, `logical()`,
#'   `character()`, `list()` for multi-value columns, or
#'   `vctrs::unspecified()`) for column definition `x`.
#' @noRd
sp_list_col_ptype <- function(x) {
  # Internal/system fields have inconsistent or missing type metadata (e.g.
  # "Attachments" has no declared type and "ItemChildCount" is modeled as a
  # pseudo-lookup column) so they are left flexible rather than guessed at
  if (x[["name"]] %in% sp_list_internal_colnames) {
    return(vctrs::unspecified())
  }

  if (any(has_name(x, c("number", "currency")))) {
    ptype <- double()
  } else if (has_name(x, "boolean")) {
    ptype <- logical()
  } else if (
    any(has_name(x, c("text", "choice", "dateTime", "lookup", "personOrGroup")))
  ) {
    ptype <- character()
  } else {
    # Column types that can return complex/nested values (hyperlinkOrPicture,
    # thumbnail, geolocation, calculated, term, ...) are left flexible
    return(vctrs::unspecified())
  }

  if (sp_list_col_is_multi(x)) {
    return(list())
  }

  ptype
}

#' Build a ptype (prototype) data frame with a column for every field in a
#' SharePoint list, in list order. Used to guarantee that
#' [list_sp_list_items()] always returns every column, even when a field is
#' empty for every returned item (and so is otherwise dropped entirely by the
#' Graph API).
#' @param select Optional. Column names passed to the Graph API. Lookup and
#'   personOrGroup columns match by either "{name}" or "{name}LookupId". Names
#'   that don't match a list column are ignored.
#' @returns A 0 row data frame with one column per SharePoint list field, each
#'   with the ptype for that column.
#' @noRd
sp_list_as_ptype_data_frame <- function(
  ...,
  sp_list = NULL,
  col_metadata = NULL,
  select = NULL
) {
  col_metadata <- sp_list_ptype_col_metadata(
    sp_list = sp_list,
    col_metadata = col_metadata
  )

  if (!is.null(select)) {
    col_metadata <- col_metadata[
      names(col_metadata) %in% c(select, paste0(select, "LookupId"))
    ]
  }

  vctrs::data_frame(
    !!!purrr::map(col_metadata, sp_list_col_ptype),
    .name_repair = "minimal"
  )
}

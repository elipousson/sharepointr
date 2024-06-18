#' Get, list, update, and delete SharePoint list items
#'
#' [list_sp_list_items()] lists `sp_list` items. Additional functions should be
#' completed for the `get_item`, `create_item`, `update_item`, and `delete_item`
#' methods documented in [Microsoft365R::ms_list].
#' @name sp_list_item
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
#'   `as_data_frame = FALSE`.
#' @param pagesize Number of list items to return. Reduce from default of 5000
#'   is experiencing timeouts.
#' @param names_from Source for column names. Must be `"displayName"` (default)
#'   or `"name"`. Defaults value `"displayName"` uses display name values from
#'   list metadata for visible, non-read only columns.
#' @param name_repair Defaults to  Passed to `repair` argument of [vctrs::vec_as_names()]
#' @export
list_sp_list_items <- function(list_name = NULL,
                               list_id = NULL,
                               sp_list = NULL,
                               ...,
                               filter = NULL,
                               select = NULL,
                               all_metadata = FALSE,
                               as_data_frame = TRUE,
                               pagesize = 5000,
                               names_from = "displayName",
                               name_repair = "unique",
                               site_url = NULL,
                               site = NULL,
                               drive_name = NULL,
                               drive_id = NULL,
                               drive = NULL,
                               call = caller_env()) {
  sp_list <- sp_list %||% get_sp_list(
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

  if (is.character(select)) {
    select <- paste0(select, collapse = ",")
  }

  if (all_metadata && !as_data_frame) {
    cli::cli_warn(
      "{.arg all_metadata} can't be {.code TRUE} if
      {.code as_data_frame = FALSE}"
    )

    all_metadata <- FALSE
  }

  cli::cli_progress_step(
    "Getting list items from SharePoint"
  )

  sp_list_items <- sp_list$list_items(
    filter = filter,
    select = select,
    all_metadata = all_metadata,
    as_data_frame = as_data_frame,
    pagesize = pagesize
  )

  names_from <- arg_match0(
    names_from,
    c("name", "displayName"),
    error_call = call
  )

  # TODO: Add labels_from support
  # if (!is.null(labels_from)) {
  #   labels_from <- arg_match0(
  #     labels_from,
  #     c("name", "displayName"),
  #     error_call = call
  #   )
  # }

  if (names_from == "name") {
    return(set_sp_data_names(sp_list_items, name_repair = name_repair, call = call))
  }

  # Get list item names
  items_nm <- names(sp_list_items)

  # Match names from items to list names
  sp_list_meta <- get_sp_list_metadata(sp_list = sp_list, call = call)
  sp_list_meta <- sp_list_meta[!sp_list_meta[["readOnly"]], ]
  sp_list_names <- sp_list_meta[["name"]]
  items_nm_match <- match(items_nm, sp_list_names)

  # Drop unmatched and read only names
  is_nm_match <- !is.na(items_nm_match)

  # Insert display names into name vector
  if (any(is_nm_match)) {
    display_names <- sp_list_meta[["displayName"]]
    items_nm[is_nm_match] <- display_names[items_nm_match[is_nm_match]]
  }

  set_sp_data_names(
    sp_list_items,
    nm = items_nm,
    name_repair = name_repair,
    call = call
  )
}

#' @noRd
set_sp_data_names <- function(data,
                              nm = NULL,
                              name_repair = "unique",
                              repair_arg = "name_repair",
                              call = caller_env()) {
  if (is.null(name_repair)) {
    return(data)
  }

  nm <- nm %||% names(data)

  nm <- vctrs::vec_as_names(
    nm,
    repair = name_repair,
    repair_arg = repair_arg,
    call = call
  )

  set_names(data, nm = nm)
}


#' @rdname sp_list_item
#' @name get_sp_list_item
#' @param id Required. A SharePoint list item ID typically an integer for the
#'   record number starting from 1 with the first record.
#' @export
get_sp_list_item <- function(id,
                             list_name = NULL,
                             list_id = NULL,
                             sp_list = NULL,
                             ...,
                             site_url = NULL,
                             site = NULL,
                             drive_name = NULL,
                             drive_id = NULL,
                             drive = NULL,
                             call = caller_env()) {
  sp_list <- sp_list %||% get_sp_list(
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

#' @rdname sp_list_item
#' @name create_sp_list_items
#' @details Creating new list items with `create_sp_list_items()`
#'
#' The handling of item creation when column names in `data` do not match the
#' fields names in the supplied list includes a few options:
#'
#' - If no names in data match fields in the list, the function errors and lists the field names.
#' - If all names in data match fields in the list the records are created. Any fields that do not have corresponding names in data remain blank.
#' - If any names in data do not match fields in the list, by default, those columns are dropped before adding items to the list.
#' - If `strict = TRUE` and any names in data to not match fields, the function errors.
#'
#' @aliases import_sp_list_items
#' @param data Required. A data frame to import as items to the supplied or
#'   identified SharePoint list.
#' @param strict If `TRUE`, all column names in data must be matched to field
#'   names in the supplied SharePoint list. If `FALSE` (default), unmatched
#'   columns will be dropped with a warning.
#' @param sync_fields If `TRUE`, use the `sync_fields` method to sync the fields
#'   of the local sp_list object with the fields of the SharePoint List source.
#' @param check_fields If `TRUE` (default), column names for the input data are
#'   matched to the fields of the list object. If `FALSE`, the function will
#'   error if any column names can't be matched to a field in the supplied
#'   SharePoint list.
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
#' @export
create_sp_list_items <- function(data,
                                 list_name = NULL,
                                 list_id = NULL,
                                 sp_list = NULL,
                                 ...,
                                 site_url = NULL,
                                 site = NULL,
                                 drive_name = NULL,
                                 drive_id = NULL,
                                 drive = NULL,
                                 check_fields = TRUE,
                                 sync_fields = FALSE,
                                 strict = FALSE,
                                 call = caller_env()) {
  sp_list <- sp_list %||% get_sp_list(
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

  if (check_fields) {
    data <- validate_sp_list_data_fields(
      data,
      sp_list = sp_list,
      sync_fields = sync_fields,
      strict = strict,
      call = call
    )
  }

  cli_progress_step(
    "Importing {.arg data} into list"
  )

  withCallingHandlers(
    sp_list$bulk_import(data),
    error = function(cnd) {
      cli_abort(
        cnd$message,
        call = call
      )
    }
  )

  invisible(data)
}

#' @noRd
validate_sp_list_data_fields <- function(data,
                                         sp_list = NULL,
                                         sync_fields = FALSE,
                                         strict = FALSE,
                                         call = caller_env()) {
  check_data_frame(data, call = call)

  if (sync_fields) {
    sp_list <- sp_list$sync_fields()
  }

  sp_list_meta <- get_sp_list_metadata(sp_list = sp_list, call = call)

  nm <- names(data)

  allowed_nm <- sp_list_meta[!sp_list_meta[["readOnly"]], ][["name"]]

  nm_match <- nm %in% allowed_nm

  allowed_nm_msg <- "Field name{?s} from list are {.val {allowed_nm}}"

  if (all(nm_match)) {
    return(data)
    # FIXME: If strict is `TRUE` should this required that all allowed_nm values
    # are also present in nm? The following code does this but I'm unsure if it is
    # a good approach.
    #   if (!strict) return(data)
    #
    #   if (!all(allowed_nm %in% nm)) {
    #     cli_abort(
    #       c("{.arg data} must include all writable field names.",
    #       "i" = allowed_nm_msg),
    #       call = call
    #     )
    #   }
  }

  if (all(!nm_match)) {
    cli_abort(
      c(
        "At least one column in {.arg data} must match field names from the supplied list.",
        "i" = allowed_nm_msg
      ),
      call = call
    )
  }

  if (any(!nm_match)) {
    msg <- "All column names in {.arg data} must match field names from the supplied list."

    if (strict) {
      cli_abort(
        c(
          msg,
          "i" = allowed_nm_msg
        ),
        call = call
      )
    }

    cli_warn(
      c(msg,
        "i" = "Column{?s} {.val {nm[!nm_match]}} dropped from {.arg data}"
      )
    )

    return(data[, nm_match, drop = FALSE])
  }
}

#' @rdname sp_list_item
#' @name update_sp_list_item
#' @export
update_sp_list_item <- function(id,
                                list_name = NULL,
                                list_id = NULL,
                                sp_list = NULL,
                                ...,
                                .fields = NULL,
                                site_url = NULL,
                                site = NULL,
                                drive_name = NULL,
                                drive_id = NULL,
                                drive = NULL,
                                call = caller_env()) {
  sp_list <- sp_list %||% get_sp_list(
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

  cli::cli_progress_step(
    "Updating item {.val {id}}"
  )

  sp_list_item <- get_sp_list_item(id = id, sp_list = sp_list)

  .fields <- .fields %||% list2(...)

  sp_list_item$update(fields = .fields)

  invisible(id)
}

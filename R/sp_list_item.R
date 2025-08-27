#' Get, list, update, and delete SharePoint list items
#'
#' [list_sp_list_items()] lists `sp_list` items. Additional functions should be
#' completed for the `get_item`, `create_item`, `update_item`, and `delete_item`
#' methods documented in [Microsoft365R::ms_list].
#' @name sp_list_item
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
#'   `as_data_frame = FALSE`.
#' @param pagesize Number of list items to return. Reduce from default of 5000
#'   is experiencing timeouts.
#' @param display_nm Option of "drop" (default), "label", or "replace". If
#'   "drop", display names are not accessed or used. If "label", display names
#'   are used to label matching columns in the returned data frame. If
#'   "replace", display names replace column names in the returned data frame.
#'   When working with the last option, the `name_repair` argument is required
#'   since there is no requirement on SharePoint for lists to use unique display
#'   names and invalid data frames can result.
#' @param name_repair Passed to repair argument of [vctrs::vec_as_names()]
#' @export
list_sp_list_items <- function(
  list_name = NULL,
  list_id = NULL,
  sp_list = NULL,
  ...,
  filter = NULL,
  select = NULL,
  all_metadata = FALSE,
  as_data_frame = TRUE,
  display_nm = c("drop", "label", "replace"),
  name_repair = "unique",
  pagesize = 5000,
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

  # FIXME: I think this is not necessary since Microsoft365R already does the
  # same thing
  if (is.character(select)) {
    if ("id" %in% select) {
      select[select == "id"] <- "ID"
    }

    select <- paste0(select, collapse = ",")
  }

  if (all_metadata && !as_data_frame) {
    cli::cli_warn(
      "{.arg all_metadata} can't be {.code TRUE} if
      {.code as_data_frame = FALSE}"
    )
  }

  cli::cli_progress_step(
    "Getting list items from SharePoint"
  )

  # List items
  # FIXME: Is Title not returned when no values are in place for Title?
  sp_list_items <- sp_list$list_items(
    filter = filter,
    select = select,
    all_metadata = all_metadata,
    as_data_frame = as_data_frame,
    pagesize = pagesize
  )

  display_nm <- arg_match(display_nm, error_call = call)

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
  values <- pull_sp_list_display_names(sp_list)

  # Use display names as labels
  if (display_nm == "label") {
    sp_list_items <- label_cols(
      sp_list_items,
      values = values
    )

    return(sp_list_items)
  }

  # Replace matching names with display names
  # NOTE: Column info includes fields that are not returned by the list_items method
  nm <- names(sp_list_items)
  values_i <- match(names(values), nm)
  nm[values_i[!is.na(values_i)]] <- values[!is.na(values_i)]

  # Repair names since display names may not be unique
  .set_as_names(sp_list_items, nm, repair = name_repair)
}

#' Pull a vector of display names named with corresponding column names
#' @noRd
pull_sp_list_display_names <- function(sp_list) {
  sp_list_cols <- sp_list$get_column_info()
  set_names(sp_list_cols$displayName, sp_list_cols$name)
}

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
#' - If no names in data match fields in the list, the function errors and lists the field names.
#' - If all names in data match fields in the list the records are created. Any fields that do not have corresponding names in data remain blank.
#' - If any names in data do not match fields in the list, by default, those columns are dropped before adding items to the list.
#' - If `strict = TRUE` and any names in data to not match fields, the function errors.
#'
#' @aliases import_sp_list_items
#' @param data Required. A data frame to import as items to the supplied or
#'   identified SharePoint list.
#' @param strict Not yet implemented as of 2024-08-12. If `TRUE`, all column
#'   names in data must be matched to field names in the supplied SharePoint
#'   list. If `FALSE` (default), unmatched columns will be dropped with a
#'   warning.
#' @param check_fields If `TRUE` (default), column names for the input data are
#'   matched to the fields of the list object. If `FALSE`, the function will
#'   error if any column names can't be matched to a field in the supplied
#'   SharePoint list.
#' @inheritParams ms_graph_arg_terms
#' @inheritParams get_sp_list
#' @param allow_display_nm If `TRUE`, allow data to use list field display names
#'   instead of standard names. Note this requires a separate API call so may
#'   result in a slower request. Default `FALSE`.
#' @param .id Name of column in used for item ID values. Typically this should
#'   not be changed and is only used if `allow_display_nm = TRUE`
#' @param create_list If `TRUE` and `list_name` is supplied, a new list is
#' created using [data_as_column_definition_list()] to set the column
#' definitions for the list.
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
  .progress = TRUE,
  call = caller_env()
) {
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

  if (allow_display_nm) {
    # FIXME: Figure out why this errors for some input data
    data <- replace_with_sp_list_display_names(
      data = data,
      .id = .id,
      sp_list = sp_list,
      call = call
    )
  }

  if (check_fields) {
    data <- validate_sp_list_data_fields(
      data,
      sp_list = sp_list,
      sync_fields = sync_fields,
      strict = strict,
      call = call
    )
  }

  check_data_frame(data, call = call)

  cli_progress_step(
    "Importing {.arg data} into list"
  )

  purrr::map(
    seq_len(nrow(data)),
    purrr::in_parallel(
      \(i) {
        fn(
          .sp_list = .sp_list,
          .fields = .fields[i, , drop = FALSE],
          call = call
        )
      },
      fn = create_sp_list_item,
      .sp_list = sp_list,
      .fields = data,
      call = call
    ),
    .progress = .progress
  )

  invisible(data)
}

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
  }

  nm <- names(data)

  # Drop fields that are not typically user-editable
  if (!is.null(drop_fields)) {
    values <- setdiff(values, drop_fields)
  }

  nm_match <- nm %in% values

  allowed_nm_msg <- "Field name{?s} from list are {.val {values}}"

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

  # FIXME: Use element instead of column for messages if function supports lists
  #  and data frames
  if (!any(nm_match)) {
    cli_abort(
      c(
        "At least one column in {.arg data} must match field names
        in the supplied list.",
        "i" = allowed_nm_msg
      ),
      call = call
    )
  }

  if (!all(nm_match)) {
    msg <- "All column names in {.arg data} must match field names
    in the supplied list."

    if (strict) {
      cli_abort(
        c(
          msg,
          "i" = allowed_nm_msg
        ),
        call = call
      )
    }

    cli::cli_inform(
      c(
        "!" = msg,
        "i" = "Column{?s} {.val {nm[!nm_match]}} dropped from {.arg data}"
      )
    )

    if (is.data.frame(data)) {
      data <- data[, nm_match, drop = FALSE]
    } else {
      data <- data[nm_match]
    }

    return(data)
  }
}

#' @rdname create_sp_list_items
#' @name update_sp_list_items
#' @param .id Name of column in data to use for item ID values. Defaults to
#'   "id".
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
  drop_fields = c("ContentType", "Attachments"),
  .progress = TRUE,
  call = caller_env()
) {
  sp_list <- sp_list %||%
    get_sp_list(
      list_name = list_name,
      as_data_frame = FALSE,
      list_id = list_id,
      ...,
      call = call
    )

  check_ms_obj(sp_list, "ms_list", call = call)

  stopifnot(has_name(data, .id))

  if (allow_display_nm) {
    data <- replace_with_sp_list_display_names(
      data,
      .id = .id,
      sp_list = sp_list,
      call = call
    )
  }

  update_data <- data
  item_ids <- data[[.id]]
  update_data[[.id]] <- NULL

  if (check_fields) {
    update_data <- validate_sp_list_data_fields(
      update_data,
      sp_list = sp_list,
      drop_fields = drop_fields
    )
  }

  purrr::map(
    seq_along(item_ids),
    purrr::in_parallel(
      \(i) {
        fn(
          .data = vctrs::vec_slice(
            x = x,
            i = i
          ),
          item_id = item_id[[i]],
          sp_list = sp_list,
          call = call
        )
      },
      fn = update_sp_list_item,
      item_id = item_ids,
      x = update_data,
      sp_list = sp_list,
      call = call
    ),
    .progress = .progress
  )

  invisible(data)
}

#' Replace names for a data frame or list with display names
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
#' @param sp_list_item Optional. A SharePoint list item object to use.
#' @param item_id A SharePoint list item id. Either `item_id` or `sp_list_item`
#' must be provided but not both.
#' @param .data A list or data frame with fields to update.
#' @param na_fields How to handle `NA` fields in input data. One of "drop"
#'   (remove NA fields before updating list items, leaving existing values in
#'   place) or "replace" (overwrite existing list values with new replacement NA
#'   values).
#' @param .id Column or element name with `item_item` value in `data`. Allows
#' users to pass a modified version of the list item data with the id column and
#'  any updated columns.
#' @keywords lists
#' @export
update_sp_list_item <- function(
  ...,
  .data = NULL,
  item_id = NULL,
  sp_list_item = NULL,
  na_fields = c("drop", "replace"),
  .id = "id",
  list_name = NULL,
  list_id = NULL,
  sp_list = NULL,
  site_url = NULL,
  site = NULL,
  drive_name = NULL,
  drive_id = NULL,
  drive = NULL,
  call = caller_env()
) {
  # TODO: Allow option to get id from .data
  .data <- .data %||% list2(...)

  # Check for a data frame provided with the ... argument
  if (is.data.frame(.data[[1]]) && has_length(.data, 1)) {
    cli_abort(
      "You must use {.arg .data} to update a list item with a data frame.",
      call = call
    )
  }

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

  # Fill item id value from input list or data frame
  item_id <- item_id %||% .data[[.id]]

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

    .data <- suppressMessages(
      validate_sp_list_data_fields(
        .data,
        sp_list = sp_list,
        drop_fields = c(.id, "ContentType", "Attachments")
      )
    )
  }

  na_fields <- arg_match(na_fields, error_call = call)

  if (na_fields == "drop") {
    .data <- vctrs::vec_slice(
      .data,
      i = !is.na(.data)
    )
  }

  if (!is.null(sp_list)) {
    cli_progress_step(
      "Updating item {.val {item_id}}"
    )

    withCallingHandlers(
      inject(sp_list$update_item(item_id, !!!.data)),
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

    withCallingHandlers(
      inject(sp_list_item$update(fields = list(!!!.data))),
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
#' @keywords internal
#' @export
create_sp_list_item <- function(
  ...,
  .sp_list = NULL,
  .fields = NULL,
  .keep_na = FALSE
) {
  if (!is.null(.fields) && is.data.frame(.fields)) {
    stopifnot(nrow(.fields) == 1)
    .fields <- as.list(.fields)
  }

  .fields <- .fields %||% rlang::list2(...)

  if (!.keep_na) {
    # Required for numeric fields
    .fields <- purrr::discard(.fields, is.na)
  }

  # Drop NULL values
  .fields <- purrr::compact(.fields)

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
#' @param item_id ID value for list item or items to delete.
#' @inheritParams get_sp_list_item
#' @param confirm If `TRUE` (default), user confirmation is required to delete
#' items.
#' @keywords lists
#' @export
delete_sp_list_item <- function(
  item_id = NULL,
  sp_list_item = NULL,
  ...,
  list_name = NULL,
  list_id = NULL,
  sp_list = NULL,
  site_url = NULL,
  site = NULL,
  confirm = TRUE,
  call = caller_env()
) {
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
#' @export
delete_sp_list_items <- function(
  item_id = NULL,
  ...,
  sp_list = NULL,
  filter = NULL,
  confirm = TRUE,
  .progress = TRUE
) {
  sp_list <- sp_list %||% get_sp_list(...)

  if (is.null(item_id)) {
    sp_list_items <- list_sp_list_items(
      sp_list = sp_list,
      filter = filter,
      select = "id"
    )

    item_id <- sp_list_items[["id"]]
  }

  if (confirm) {
    check_yes(
      cli::format_inline(
        "Do you want to delete {length(item_id)} list item(s)?"
      ),
      call = call
    )
  }

  # https://learn.microsoft.com/en-us/graph/api/listitem-delete?view=graph-rest-1.0&tabs=http
  # TODO: Add error handling if any id values are not valid
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

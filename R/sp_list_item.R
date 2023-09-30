#' Get, list, update, and delete SharePoint list items
#'
#' [list_sp_list_items()] lists `sp_list` items. Additional functions should be
#' completed for the `get_item`, `create_item`, `update_item`, and `delete_item`
#' methods documented in [Microsoft365R::ms_list].
#'
#' @name sp_list_item
NULL

#' @rdname sp_list_item
#' @name list_sp_list_items
#' @inheritParams ms_graph_terms
#' @inheritParams get_sp_list
#' @param select A character vector of column names to include in the returned
#'   data frame of list items. If `NULL`, the data frame includes all columns
#'   from the list.
#' @param all_metadata If `TRUE`, the returned data frame will contain extended
#'   metadata as separate columns, while the data fields will be in a nested
#'   data frame named fields. This is always set to `FALSE` if `n = NULL` or
#'   `as_data_frame = FALSE`.
#' @param pagesize Number of list items to return. Reduce from default of 5000
#'   is experiencing timeouts.
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
                               site_url = NULL,
                               site = NULL,
                               drive_name = NULL,
                               drive_id = NULL,
                               drive = NULL,
                               call = caller_env()) {
  sp_list <- sp_list %||% get_sp_list(
    list_name = list_name,
    list_id = list_id,
    ...,
    site_url = site_url,
    site = site,
    drive_name = drive_name,
    drive_id = drive_id,
    drive = drive,
    call = call
  )

  check_ms(sp_list, "ms_list", call = call)

  if (is.character(select)) {
    select <- paste0(select, collapse = ",")
  }

  if (all_metadata && (!as_data_frame || is.null(n))) {
    cli::cli_warn(
      "{.arg all_metadata} can't be {.code TRUE} if
        {.code n = NULL} or {.code as_data_frame = FALSE}"
    )
  }

  cli::cli_progress_step(
    "Getting list items from SharePoint"
  )

  sp_list$list_items(
    filter = filter,
    select = select,
    all_metadata = all_metadata,
    as_data_frame = as_data_frame,
    pagesize = pagesize
  )
}

#' @rdname sp_list_item
#' @name update_sp_list_item
#' @export
import_sp_list_items <- function(data,
                                 list_name = NULL,
                                 list_id = NULL,
                                 id = NULL,
                                 ...,
                                 filter = NULL,
                                 select = NULL,
                                 all_metadata = FALSE,
                                 as_data_frame = TRUE,
                                 pagesize = 5000,
                                 site_url = NULL,
                                 site = NULL,
                                 drive_name = NULL,
                                 drive_id = NULL,
                                 drive = NULL,
                                 call = caller_env()) {
  sp_list <- get_sp_list(
    list_name = list_name,
    list_id = list_id,
    ...,
    site_url = site_url,
    site = site,
    drive_name = drive_name,
    drive_id = drive_id,
    drive = drive,
    call = call
  )

  stopifnot(is.data.frame(data))

  cli_progress_step(
    "Importing {.arg data} into list"
  )

  sp_list$bulk_import(data)
}

#' @rdname sp_list_item
#' @name get_sp_list_item
#' @export
get_sp_list_item <- function(id,
                             list_name = NULL,
                             ...,
                             sp_list = NULL,
                             list_id = NULL,
                             site_url = NULL,
                             site = NULL,
                             drive_name = NULL,
                             drive_id = NULL,
                             drive = NULL,
                             call = caller_env()) {
  sp_list <- sp_list %||% get_sp_list(
    list_name = list_name,
    list_id = list_id,
    ...,
    site_url = site_url,
    site = site,
    drive_name = drive_name,
    drive_id = drive_id,
    drive = drive,
    call = call
  )

  check_ms(sp_list, "ms_list", call = call)

  cli::cli_progress_step(
    "Getting item {.val {id}}"
  )

  sp_list$get_item(id)
}


#' @rdname sp_list_item
#' @name update_sp_list_item
#' @export
update_sp_list_item <- function(id,
                                list_name = NULL,
                                ...,
                                sp_list = NULL,
                                list_id = NULL,
                                site_url = NULL,
                                site = NULL,
                                drive_name = NULL,
                                drive_id = NULL,
                                drive = NULL,
                                call = caller_env()) {
  sp_list <- sp_list %||% get_sp_list(
    list_name = list_name,
    list_id = list_id,
    site_url = site_url,
    site = site,
    drive_name = drive_name,
    drive_id = drive_id,
    drive = drive,
    call = call
  )

  check_ms(sp_list, "ms_list", call = call)

  cli::cli_progress_step(
    "Updating item {.val {id}}"
  )

  sp_list$update_item(id, ...)
}

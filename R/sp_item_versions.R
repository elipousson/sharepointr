#' List versions for a SharePoint item
#'
#' This is an implementation of a new method for a `ms_item` object using the
#' `do_operation` method directly. The intent is to add a list_versions method
#' back to the Microsoft365R package which may include changes to the
#' functionality and output of this function.
#'
#' @inheritDotParams get_sp_item
#' @param sp_item SharePoint item to get versions for. Additional parameters
#'   passed to `...` are ignored if sp_item is supplied.
#' @param as_data_frame If `TRUE`, return a data frame of versions. If `FALSE`,
#'   return a list.
#' @export
#' @returns A data frame if `as_data_frame = TRUE` or a list if `FALSE`.
list_sp_item_versions <- function(...,
                                  sp_item = NULL,
                                  as_data_frame = TRUE) {
  sp_item <- sp_item %||% get_sp_item(...)

  sp_item_versions <- sp_item$do_operation("versions")


  if (!as_data_frame) {
    return(sp_item_versions)
  }

  sp_item_versions_data <- sp_item_versions[["value"]] |>
    ms_obj_list_as_data_frame(
      obj_col = "versions"
    ) |>
    fmt_sp_list_col()

  # FIXME: Figure out how/if to preserve the odata.context URL
  # attributes(sp_item_versions_data) <- set_names(
  #  as.list(sp_item_versions[["@odata.context"]]),
  #  "@odata.context"
  # )

  if (is_installed("fs")) {
    sp_item_versions_data <- fmt_sp_item_size(sp_item_versions_data)
  }

  sp_item_versions_data
}

#' @noRd
fmt_sp_list_col <- function(data, col = "lastModifiedBy") {
  check_data_frame(data)

  list_col <- data[[col]]
  data[[col]] <- NULL

  vctrs::vec_cbind(
    data,
    vctrs::vec_rbind(!!!list_col)
  )
}

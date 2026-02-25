#' List items from the hidden SharePoint "User Information List"
#'
#' @param sp_site A `ms_site` object.
#' @keywords internal
#' @export
list_sp_site_user_info <- function(
  ...,
  sp_site = NULL,
  as_data_frame = TRUE
) {
  sp_site <- sp_site %||% get_sp_site(...)

  sp_list <- get_sp_list(
    list_name = "User Information List",
    site = sp_site,
    as_data_frame = FALSE
  )

  list_sp_list_items(
    sp_list = sp_list,
    as_data_frame = as_data_frame
  )
}

#' Convert a vector of user identifiers to lookup ID values (or another type of identifier) using the hidden SharePoint "User Information List"
#'
#' @param users A character vector of email addresses (or another identifier as specified by `users_id`). Not case sensitive.
#' @param user_info_list Data frame from "User Information List". Typically,
#' created with [list_sp_site_user_info()]. @param ... Parameters passed to
#' [list_sp_site_user_info()] if `user_info_list` is not supplied.
#' @param users_id Type of `users` vector to expect as input. Defaults to `"EMail"`.
#' @param lookup_id Type of lookup ID value to return. Defaults to `"id"`.
#' @param allow_hidden If `TRUE`, include users with `UserInfoHidden = TRUE` in
#' the possible results. Defaults to `FALSE`.
#' @keywords internal
#' @export
sp_user_id_as_lookup_id <- function(
  users,
  ...,
  user_info_list = NULL,
  users_id = "EMail",
  lookup_id = "id",
  allow_hidden = FALSE
) {
  user_info_list <- user_info_list %||%
    list_sp_site_user_info(
      ...
    )

  if (!allow_hidden) {
    user_info_list <- user_info_list[
      !user_info_list$UserInfoHidden,
    ]
  }

  user_index <- match(
    tolower(users),
    tolower(user_info_list[[users_id]])
  )

  user_index[!is.na(user_index)] <- user_info_list[[lookup_id]][[user_index[
    !is.na(user_index)
  ]]]

  user_index
}

#' Format a data frame with specified person columns to create or update
#' person/group columns in a SharePoint list
#' @keywords internal
#' @export
fmt_person_lookup_id_values <- function(
  .data,
  cols,
  users_id = "EMail",
  site_users = NULL,
  sp_site = NULL
) {
  site_users <- site_users %||%
    list_sp_site_user_info(
      sp_site = sp_site
    )
  nm <- names(.data)
  cols <- arg_match(cols, nm, multiple = TRUE)
  for (j in cols) {
    .data[[j]] <- sp_user_id_as_lookup_id(
      .data[[j]],
      user_info_list = site_users,
      users_id = users_id
    )
  }

  nm[nm %in% cols] <- paste0(nm[nm %in% cols], "LookupId")

  rlang::set_names(
    .data,
    nm
  )
}

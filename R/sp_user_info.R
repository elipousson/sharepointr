#' List items from the hidden SharePoint "User Information List"
#'
#' `r lifecycle::badge("experimental")`
#'
#' [list_sp_site_user_info()] lists users from the hidden "User Information
#' List" for a site. Use the results to match users to lookup ID values for
#' person or group columns with [fmt_sp_list_lookup_items()] or
#' [update_sp_list_person_items()].
#'
#' @param ... Additional parameters passed to [get_sp_site()] if `sp_site` is
#'   not supplied.
#' @param sp_site A `ms_site` object.
#' @param user_type Type of users to return. "all" (default) returns all users
#'   and "visible" excludes users where `UserInfoHidden` is `TRUE`.
#' @param filter Optional. A filter query string passed to
#'   [list_sp_list_items()]. If `user_type = "visible"`, `filter` is combined
#'   with a filter for visible users.
#' @inheritParams list_sp_list_items
#' @keywords lists
#' @export
list_sp_site_user_info <- function(
  ...,
  sp_site = NULL,
  user_type = c("all", "visible"),
  filter = NULL,
  as_data_frame = TRUE,
  call = caller_env()
) {
  user_type <- arg_match(user_type, error_call = call)
  check_string(filter, allow_null = TRUE, call = call)

  sp_site <- sp_site %||% get_sp_site(..., call = call)

  sp_list <- get_sp_list(
    list_name = "User Information List",
    site = sp_site,
    as_data_frame = FALSE,
    call = call
  )

  if (user_type == "visible") {
    # Boolean fields must be compared to 0 or 1 ("ne true" returns hidden users)
    filter <- paste(
      c(filter, "fields/UserInfoHidden eq 0"),
      collapse = " and "
    )
  }

  list_sp_list_items(
    sp_list = sp_list,
    filter = filter,
    as_data_frame = as_data_frame,
    call = call
  )
}

#' @param user_column Name of column (or record element) in `user_info_data`
#'   with values to match to `join_column` values. Defaults to `"EMail"`.
#' @param user_info_data Optional. A data frame or an unnamed list of named
#'   lists from the "User Information List" for the site. If `NULL`, items are
#'   retrieved with [list_sp_site_user_info()] for the site of `sp_list`.
#' @param allow_hidden If `TRUE`, include users with `UserInfoHidden = TRUE` in
#'   the possible matches. Defaults to `FALSE`.
#' @rdname create_sp_list_lookup_column
#' @keywords lists
#' @export
update_sp_list_person_items <- function(
  data = NULL,
  sp_list = NULL,
  column_name,
  join_column = column_name,
  user_column = "EMail",
  user_info_data = NULL,
  allow_hidden = FALSE,
  ...,
  .id = "id",
  na_fields = c("drop", "replace"),
  .progress = TRUE,
  call = caller_env()
) {
  check_bool(allow_hidden, call = call)

  sp_list <- sp_list %||%
    get_sp_list(
      ...,
      as_data_frame = FALSE,
      call = call
    )

  check_ms_obj(sp_list, "ms_list", call = call)

  if (is.null(user_info_data)) {
    user_info_data <- list_sp_site_user_info(
      sp_site = get_sp_site(
        site_id = sp_list_site_id(sp_list),
        call = call
      ),
      user_type = if (allow_hidden) "all" else "visible",
      call = call
    )
  } else if (!allow_hidden) {
    user_info_data <- drop_hidden_users(user_info_data)
  }

  update_sp_list_lookup_items(
    data = data,
    sp_list = sp_list,
    column_name = column_name,
    lookup_list_data = user_info_data,
    join_column = join_column,
    lookup_join_column = user_column,
    ...,
    .id = .id,
    ignore_case = TRUE,
    na_fields = na_fields,
    .progress = .progress,
    call = call
  )
}

#' Drop hidden users from "User Information List" data
#' @returns `user_info_data` without users where `UserInfoHidden` is `TRUE`.
#'   Users with a missing `UserInfoHidden` value are kept.
#' @noRd
drop_hidden_users <- function(user_info_data) {
  if (is.data.frame(user_info_data)) {
    if (!has_name(user_info_data, "UserInfoHidden")) {
      return(user_info_data)
    }

    vctrs::vec_slice(
      user_info_data,
      !(user_info_data[["UserInfoHidden"]] %in% TRUE)
    )
  } else {
    purrr::discard(
      user_info_data,
      \(x) isTRUE(x[["UserInfoHidden"]])
    )
  }
}

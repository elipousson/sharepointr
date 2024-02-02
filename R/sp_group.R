#' Get SharePoint group for a site or list group members
#'
#' [get_sp_group()] gets the group associated with an individual site using the
#' `get_group` method. [list_sp_group_members()] lists members in the group.
#' Note that, as of February 1, 2024, the returned member data frame when
#' `as_data_frame = TRUE` contains a large number of list columns that could be
#' coerced into character columns. This should be addressed in a later update.
#'
#' @inheritParams ms_graph_obj_terms
#' @inheritParams get_sp_site
#' @aliases get_sp_site_group
#' @export
get_sp_group <- function(site_url = NULL,
                         site_name = NULL,
                         site_id = NULL,
                         ...,
                         site = NULL,
                         call = caller_env()) {
  if (is_url(site)) {
    site_url <- site
    site <- NULL
  }

  site <- site %||% get_sp_site(
    site_url = site_url,
    site_name = site_name,
    site_id = site_id,
    ...,
    call = call
  )

  check_ms_site(site, call = call)

  site$get_group()
}

#' @name list_sp_group_members
#' @param as_data_frame If `TRUE` (default), converted list of members into a
#'   data frame with a list column named `az_user` that contains the member
#'   list and properties converted into columns.
#' @rdname get_sp_group
#' @export
list_sp_group_members <- function(site_url = NULL,
                                  site_name = NULL,
                                  site_id = NULL,
                                  ...,
                                  as_data_frame = TRUE,
                                  call = caller_env()) {
  sp_group <- get_sp_group(
    site_url = site_url,
    site_name = site_name,
    site_id = site_id,
    ...,
    call = call
  )

  members <- ms_obj_list_as_data_frame(
    sp_group$list_members(),
    obj_col = "az_user",
    unlist_cols = FALSE,
    .error_call = call
  )

  if (!as_data_frame) {
    return(members)
  }

  # FIXME: This is a brittle and likely incomplete solution
  for (nm in c(
    "accountEnabled", "id", "employeeId", "mail", "displayName",
    "jobTitle", "department", "givenName", "surname", "mailNickname",
    "businessPhones", "mobilePhone", "officeLocation"
  )) {
    fn <- as.character
    if (nm == "accountEnabled") {
      fn <- as.logical
    }

    members[[nm]] <- fn(members[[nm]])
  }

  members
}

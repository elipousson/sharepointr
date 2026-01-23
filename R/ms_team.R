#' Wrapper for `Microsoft365R::get_team`
#' @noRd
get_ms_team <- function(
  ...
) {
  Microsoft365R::get_team(
    ...
  )
}

#' Wrapper for list_channels method for `ms_team` object
#' @noRd
get_ms_team_channels <- function(
  ...,
  filter = NULL,
  n = NULL,
  as_data_frame = TRUE,
  keep_list_cols = c(
    "description",
    "email",
    "webUrl",
    "isFavoriteByDefault"
  )
) {
  ms_team_obj <- get_ms_team(
    ...
  )

  ms_team_list <- ms_team_obj$list_channels(filter = filter, n = n %||% Inf)

  if (!as_data_frame) {
    return(ms_team_list)
  }

  ms_obj_list_as_data_frame(
    ms_team_list,
    obj_col = "ms_team",
    keep_list_cols = keep_list_cols
  )
}

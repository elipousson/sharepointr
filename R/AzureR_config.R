#' List or delete files from the AzureR configuration directory
#'
#' [AzureR_config_ls()] uses [rappdirs::user_config_dir()] and [fs::dir_ls()] to
#' list files from the AzureR configuration directory. [AzureR_config_delete()]
#' uses [fs::file_delete()] to remove the "graph_logins.json" configuration file
#' if needed. Use this function with caution but it may be an option to address
#' a "Unable to refresh token" error.
#'
#' @name AzureR_config
#' @param path Path to configuration directory for AzureR package where the JSON
#'   file for graph_logins is stored. If `NULL`, path is set with the base
#' folder for `rappdirs::user_cache_dir("AzureR")` (for Windows) or
#'  `rappdirs::user_config_dir("AzureR")` (for non-Windows).
#' @inheritParams fs::dir_ls
#' @param filename Filename to delete from configuration directory. Defaults to
#'   "graph_logins.json". Set to `NULL` if path contains a file name.
NULL

#' @rdname AzureR_config
#' @name AzureR_config_ls
#' @export
AzureR_config_ls <- function(path = NULL, glob = "*.json") {
  check_installed(c("rappdirs", "fs"))
  fs::dir_ls(path = AzureR_set_path(path), glob = glob)
}

#' @rdname AzureR_config
#' @name AzureR_config_delete
#' @export
AzureR_config_delete <- function(path = NULL, filename = "graph_logins.json") {
  check_installed(c("rappdirs", "fs"))
  fs::file_delete(path = str_c_fsep(AzureR_set_path(path), filename))
}

#' @noRd
AzureR_set_path <- function(path = NULL) {
  if (identical(.Platform$OS.type, "windows")) {
    path <- path %||%
      fs::path_dir(fs::path_dir(rappdirs::user_cache_dir("AzureR")))
  } else {
    path <- path %||%
      rappdirs::user_config_dir("AzureR")
  }
  path
}

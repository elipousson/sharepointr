#' Cache a `ms_object` class object to a file
#'
#' @param overwrite If `TRUE`, replace the existing cached object named by
#'   `cache_file` with the new object. If `FALSE`, error if a cached file with
#'   the same `cache_file` name already exists.
#' @param cache_file File name for cached file. Required.
#' @param cache_dir Cache directory. By default, uses an environmental variable
#'   named "sharepointr.cache_dir". If "sharepointr.cache_dir" is not set, the
#'   cache directory is set to `rappdirs::user_cache_dir("sharepointr")`.
#' @keywords internal
cache_ms_obj <- function(x,
                         cache_file,
                         cache_dir = NULL,
                         what = "ms_site",
                         overwrite = FALSE,
                         arg = caller_arg(x),
                         call = caller_env()) {
  check_ms_obj(x, what = what, arg = arg, call = call)

  # FIXME: Is it possible to set filename based on object properties?
  # filename <- paste0(x[["properties"]][["name"]], ".rds")
  path <- sp_cache_path(cache_file, cache_dir, call = call)

  if (file.exists(path)) {
    if (!overwrite) {
      cli_abort(
        "Set {.code overwrite = TRUE} to replace cached
        {.cls {what}} object: {.file {cache_file}} ",
        call = call
      )
    } else {
      file.remove(path)
    }
  }

  saveRDS(x, path)
}

#' Does a named cached file exist?
#'
#' @noRd
sp_cache_file_exists <- function(cache_file = character(0),
                                 cache_dir = NULL,
                                 call = caller_env()) {
  file.exists(sp_cache_path(cache_file, cache_dir, call = call))
}

#' Get a object from the cache
#'
#' @noRd
get_sp_cache <- function(cache_file,
                         cache_dir = NULL,
                         what = "ms_site",
                         call = caller_env()) {
  path <- sp_cache_path(cache_file, cache_dir, call = call)

  if (file.exists(path)) {
    ms_obj <- readRDS(path)
  }

  if (!is_ms_obj(ms_obj, what)) {
    cli_warn(
      "Cached {.val {default}} is not a {.cls {what}} object"
    )

    return(NULL)
  }

  ms_obj
}

#' Get path to cached file
#'
#' @noRd
sp_cache_path <- function(cache_file,
                          cache_dir = NULL,
                          call = caller_env()) {
  check_string(cache_file, call = call)

  file.path(sp_cache_dir(cache_dir, call), cache_file)
}

#' Get cache directory and create directory if it does not exist
#'
#' @noRd
sp_cache_dir <- function(cache_dir = NULL,
                         call = caller_env()) {
  check_string(cache_dir, call = call)

  cache_dir <- cache_dir %||% Sys.getenv("sharepointr.cache_dir")

  if (identical(cache_dir, "")) {
    check_installed("rappdirs", call = call)
    cache_dir <- rappdirs::user_cache_dir("sharepointr")
  }

  if (!dir.exists(cache_dir)) {
    dir.create(cache_dir)
  }

  path.expand(cache_dir)
}

#' Cache a `ms_object` class object to a file
#'
#' @param overwrite If `TRUE`, replace the existing cached object named by
#'   `cache_file` with the new object. If `FALSE`, error if a cached file with
#'   the same `cache_file` name already exists.
#' @param cache_file File name for cached file. Required.
#' @param cache_dir Cache directory. By default, uses an option
#'   named "sharepointr.cache_dir". If "sharepointr.cache_dir" is not set, the
#'   cache directory is set to `rappdirs::user_cache_dir("sharepointr")`.
#' @keywords internal
cache_ms_obj <- function(
  x,
  cache_file,
  cache_dir = NULL,
  what = "ms_site",
  overwrite = FALSE,
  arg = caller_arg(x),
  call = caller_env()
) {
  check_ms_obj(x, what = what, arg = arg, call = call)

  # FIXME: Is it possible to set filename based on object properties?
  # filename <- paste0(x[["properties"]][["name"]], ".rds")
  path <- sp_cache_path(
    cache_file,
    cache_dir,
    what = what,
    call = call,
    allow_missing = TRUE
  )

  if (file.exists(path)) {
    # TODO: Consider if checking for an overwrite is helpful or not
    if (!overwrite) {
      cli_warn(
        "{.arg overwrite} must be `TRUE` to replace existing cached
        {.cls {what}} object at {.file {path}}",
        call = call
      )

      return(invisible(NULL))
    } else {
      file.remove(path)
    }
  }

  saveRDS(x, path)
}

#' Get a object from the cache
#'
#' @noRd
get_cached_ms_obj <- function(
  cache_file = NULL,
  cache_dir = NULL,
  what = NULL,
  allow_missing = TRUE,
  call = caller_env()
) {
  if (is.null(cache_file) && !is.null(what)) {
    cache_file <- paste0(what, ".rds")
  }

  # Get cached object if available
  cache_path <- sp_cache_path(
    cache_file,
    cache_dir = cache_dir,
    what = what,
    allow_missing = allow_missing,
    call = call
  )

  if (!file.exists(cache_path) && allow_missing) {
    return(NULL)
  }

  ms_obj <- readRDS(cache_path)

  # TODO: Consider adding a check for name or URL to ensure the cached object
  # matches the request object
  if (is_ms_obj(ms_obj, what)) {
    return(ms_obj)
  }

  cli_abort(
    c(
      "Cached file {.file {cache_file}} must be a {.cls {what}} object",
      "v" = "Removing invalid cached file."
    ),
    call = call
  )
}

#' Get path to cached file
#'
#' @noRd
sp_cache_path <- function(
  cache_file = NULL,
  cache_dir = NULL,
  what = NULL,
  allow_missing = TRUE,
  call = caller_env()
) {
  # Replace NULL `cache_file` if `what` is supplied
  if (is.null(cache_file) && is_string(what)) {
    cache_file <- paste0(what, ".rds")
  }

  # Validate and build cache file path
  check_string(cache_file, call = call)
  cache_dir <- sp_cache_dir(cache_dir, call)
  cache_path <- file.path(cache_dir, cache_file)

  # Return path if exists
  if (file.exists(cache_path)) {
    return(cache_path)
  }

  # Return non-existent path (default) or error
  if (allow_missing) {
    return(cache_path)
  }

  cli_abort(
    "Cached file {.file {cache_file}} must exist in {.path {cache_dir}}.",
    call = call
  )
}

#' Get cache directory and create directory if it does not exist
#'
#' @noRd
sp_cache_dir <- function(cache_dir = NULL, call = caller_env()) {
  cache_dir <- cache_dir %||% getOption("sharepointr.cache_dir")

  # Replace non-existent path with package cache directory
  if (is.null(cache_dir)) {
    check_installed("rappdirs", call = call)
    cache_dir <- rappdirs::user_cache_dir("sharepointr")
  }

  check_string(cache_dir, call = call)

  # Create cache directory if needed
  if (!dir.exists(cache_dir)) {
    dir.create(cache_dir, recursive = TRUE)
  }

  path.expand(cache_dir)
}

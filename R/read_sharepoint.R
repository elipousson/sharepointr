#' Read a SharePoint item based on a file URL or file name and site
#' details
#'
#' @description
#' [read_sharepoint()] is designed to download a SharePoint item to a temporary
#' folder and read the file based on the file extension. If a function is
#' provided to .f, it is used to read the downloaded file. If not, class of the
#' returned object depends on the file extension of the file parameter.
#'
#' - If the file is a csv, csv2, or tsv file or a Microsoft Excel file (xlsx or
#' xls), [readr::read_delim()] or [readxl::read_excel()] is used to return a
#' data frame.
#' - If the file is a rds file, [readr::read_rds()] is used to return the saved
#' object.
#' - If the file is a pptx or docx file, [officer::read_docx()] or
#' [officer::read_pptx()] are used to read the file into a `rdocx` or `rpptx`
#' object.
#' - If the file has a "gpkg", "geojson", "kml", "gdb", or "zip" file extension,
#' [sf::read_sf()] is used to read the file into a `sf` data frame.
#'
#' If the file has none of these file extensions, an attempt is made to read the
#' file with [readr::read_lines()].
#'
#' @name read_sharepoint
#' @param file Required. A SharePoint shared file URL, document URL, or, if
#'   `item_id` is supplied, a file name to use in combination with `new_path` to
#'   set `dest` with location and filename for downloaded item.
#' @param .f Optional function to use to read file downloaded from SharePoint.
#' @param ... Additional parameters passed to one of the functions identified in
#'   the description or supplied to `.f`
#' @inheritParams download_sp_item
#' @inheritParams get_sp_drive
#' @inheritParams get_sp_site
#' @export
read_sharepoint <- function(file,
                            ...,
                            .f = NULL,
                            new_path = tempdir(),
                            overwrite = TRUE,
                            drive_name = NULL,
                            drive_id = NULL,
                            drive = NULL,
                            site_url = NULL,
                            site_name = NULL,
                            site_id = NULL,
                            site = NULL) {
  dest <- download_sp_file(
    file = file,
    new_path = new_path,
    drive_name = drive_name,
    drive_id = drive_id,
    drive = drive,
    site_url = site_url,
    site_name = site_name,
    site_id = site_id,
    site = site,
    overwrite = overwrite
  )

  message <- "Reading item with "

  if (!is.null(.f)) {
    fn_label <- expr_text(substitute(.f))
    .f <- as_function(.f)
    cli_progress_step("{message}{.fn {fn_label}}")
    return(.f(dest, ...))
  }

  if (is_fileext_path(dest, c("csv", "csv2", "tsv"))) {
    check_installed("readr")
    cli_progress_step("{message}{.fn readr::read_delim}")
    return(readr::read_delim(dest, ...))
  }

  if (is_fileext_path(dest, c("xlsx", "xls"))) {
    check_installed("readxl")
    cli_progress_step("{message}{.fn readxl::read_excel}")
    return(readxl::read_excel(dest, ...))
  }

  if (is_fileext_path(dest, "rds")) {
    check_installed("readr")
    cli_progress_step("{message}{.fn readr::read_rds}")
    return(readr::read_rds(dest, ...))
  }

  if (is_fileext_path(dest, "docx")) {
    check_installed("officer")
    cli_progress_step("{message}{.fn officer::read_docx}")
    return(officer::read_docx(dest))
  }

  if (is_fileext_path(dest, "pptx")) {
    check_installed("officer")
    cli_progress_step("{message}{.fn officer::read_pptx}")
    return(officer::read_pptx(dest))
  }

  if (is_fileext_path(dest, c("gpkg", "geojson", "kml", "gdb", "zip"))) {
    check_installed("sf")
    cli_progress_step("{message}{.fn sf::read_sf}")
    return(sf::read_sf(dest, ...))
  }

  check_installed("readr")
  cli_progress_step("{message}{.fn readr::read_lines}")
  readr::read_lines(dest, ...)
}


#' Read a SharePoint item based on a file URL or file name and site
#' details
#'
#' @description
#' [read_sharepoint()] is designed to download a SharePoint item to a temporary
#' folder and read the file based on the file extension. The class of the
#' returned object depends on the file extension of the file parameter.
#'
#' - If the file is a csv or Microsoft Excel file (xlsx or xls), the
#' [readr::read_csv()] or [readxl::read_excel()] is used to return a data frame.
#' - If the file is a pptx or docx file, [officer::read_docx()] or
#' [officer::read_pptx()] are used to read the file into a `rdocx` or `rpptx`
#' object.
#' - If the file is a GeoPackage or GeoJSON file, [sf::read_sf()] is used to
#' read the file into a `sf` data frame.
#'
#' @name read_sharepoint
#' @inheritParams download_sp_item
#' @export
read_sharepoint <- function(file,
                            path = tempdir(),
                            drive_name = NULL,
                            drive_id = NULL,
                            site_url = NULL,
                            dest = NULL,
                            overwrite = TRUE,
                            recursive = FALSE,
                            parallel = FALSE,
                            ...) {
  dest <- download_sp_item(
    file = file,
    path = path,
    drive_name = drive_name,
    drive_id = drive_id,
    site_url = site_url,
    dest = dest,
    overwrite = overwrite,
    recursive = recursive,
    parallel = parallel
  )

  message <- "Reading item with "

  if (is_fileext_path(dest, "csv")) {
    check_installed("readr")
    cli_progress_step("{message}{.fn readr::read_csv}")
    readr::read_csv(dest, ...)
  } else if (is_fileext_path(dest, "xlsx")) {
    check_installed("readxl")
    cli_progress_step("{message}{.fn readxl::read_excel}")
    readxl::read_excel(dest, ...)
  } else if (is_fileext_path(dest, "docx")) {
    check_installed("officer")
    cli_progress_step("{message}{.fn officer::read_docx}")
    officer::read_docx(dest)
  } else if (is_fileext_path(dest, "pptx")) {
    check_installed("officer")
    cli_progress_step("{message}{.fn officer::read_pptx}")
    officer::read_pptx(dest)
  } else if (is_fileext_path(dest, c("gpkg", "geojson"))) {
    check_installed("sf")
    cli_progress_step("{message}{.fn sf::read_sf}")
    sf::read_sf(dest, ...)
  }
}

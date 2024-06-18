#' Read a CSV file with a schema for a Microsoft List
#' @noRd
sp_list_read_file <- function(file) {
  check_installed("xml2")

  schema <- xml2::read_html(readLines(con = file, n = 1))

  if (is_installed("readr")) {
    data <- readr::read_csv(file, skip = 1)
  } else {
    data <- read.csv(file, skip = 1)
  }

  list(
    schema = schema,
    data = data
  )
}

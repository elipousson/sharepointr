#' List SharePoint pages or get a single SharePoint page
#'
#' [list_sp_pages()] returns a list of SharePoint pages associated with a
#' specified SharePoint site. [get_sp_page()] returns a single SharePoint page.
#'
#' @inheritDotParams get_sp_site
#' @param site Optional `ms_site` object to use. If not provided, the `...`
#'   arguments are passed to [get_sp_site()].
#' @param page_type Page type to request. One of "sitePage" or "page".
#' @param as_data_frame If `TRUE`, return a data frame with details on the
#'   SharePoint site pages. If `FALSE`, return a list.
#' @inheritParams rlang::args_error_context
#' @export
list_sp_pages <- function(...,
                          site = NULL,
                          page_type = c("sitePage", "page"),
                          as_data_frame = TRUE,
                          call = caller_env()) {
  sp_site <- site %||% get_sp_site(..., call = call)

  page_type <- arg_match(page_type, error_call = call)

  op <- switch(page_type,
    "page" = "pages",
    "sitePage" = "pages/microsoft.graph.sitePage"
  )

  sp_pages <- sp_site$do_operation(op)

  if (!as_data_frame) {
    return(sp_pages[["value"]])
  }

  sp_pages[["value"]] |>
    ms_obj_list_as_data_frame(
      obj_col = "ms_page",
      keep_list_cols = "createdBy",
      .error_call = call
    )
}

#' @param page_url,page_id SharePoint page URL or ID.
#' @rdname list_sp_pages
#' @export
get_sp_page <- function(page_url = NULL, page_id = NULL, ..., site = NULL) {
  page_url_parts <- NULL

  if (!is.null(page_url)) {
    page_url_parts <- sp_url_parse(page_url)
  }

  if (is.null(site) && !is.null(page_url_parts)) {
    site <- get_sp_site(site_url = page_url_parts[["site_url"]])
  }

  sp_site <- site %||% get_sp_site(...)

  if (is.null(page_id)) {
    sp_site_pages <- list_sp_pages(site = sp_site, as_data_frame = FALSE)

    sp_site_page_match <- vapply(
      sp_site_pages,
      \(x) {
        x[["name"]] == page_url_parts[["page_name"]]
      },
      TRUE
    )

    page_id <- sp_site_pages[sp_site_page_match][["id"]]
  }

  op <- paste0("pages/", page_id, "/microsoft.graph.sitePage")
  sp_page <- sp_site$do_operation(op)

  sp_page[["value"]]
}


#' @noRd
list_sp_page_parts <- function(
    page_url = NULL,
    page_id = NULL,
    sp_page = NULL,
    ...,
    sp_site = NULL,
    site_url = NULL,
    part_type = c(
      "webparts",
      "verticalSection",
      "horizontalSections",
      "horizontalSectionColumns",
      "horizontalSectionColumn_webparts"
    ),
    h_section_id = NULL,
    h_section_col_id = NULL,
    as_data_frame = TRUE) {
  if (!is.null(page_url) && is.null(site_url)) {
    site_url <- site_url %||% sp_url_parse(page_url)[["site_url"]]
  }

  if (is.null(page_id)) {
    if (is.null(sp_page)) {
      sp_page <- get_sp_page(page_id = page_id, site_url = site_url, ...)
    } else {
      site_url <- site_url %||% sp_url_parse(sp_page[["webUrl"]])[["site_url"]]
    }

    stopifnot(
      !is.null(sp_page[["id"]])
    )

    page_id <- sp_page[["id"]]
  }

  sp_site <- sp_site %||% get_sp_site(site_url = site_url, ...)

  part_type <- arg_match(part_type)

  part <- switch(part_type,
    "webparts" = "webparts",
    "verticalSection" = "canvasLayout/verticalSection/webparts",
    "horizontalSections" = "canvasLayout/horizontalSections", #
    "horizontalSectionColumns" = "canvasLayout/horizontalSections/{h_section_id}/columns",
    "horizontalSectionColumn_webparts" = "horizontalSections/{h_section_id}/columns/{h_section_col_id}/webparts"
  )

  op <- glue(paste0("pages/{page_id}/microsoft.graph.sitePage/", part))

  sp_page_parts <- sp_site$do_operation(op)

  if (!as_data_frame) {
    return(sp_page_parts)
  }

  sp_page_parts[["value"]] |>
    ms_obj_list_as_data_frame(
      obj_col = paste0("ms_", part_type),
      keep_list_cols = "createdBy"
    )
}

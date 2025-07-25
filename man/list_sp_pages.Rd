% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/sp_pages.R
\name{list_sp_pages}
\alias{list_sp_pages}
\alias{get_sp_page}
\title{List SharePoint pages or get a single SharePoint page}
\usage{
list_sp_pages(
  ...,
  site = NULL,
  page_type = c("sitePage", "page"),
  as_data_frame = TRUE,
  call = caller_env()
)

get_sp_page(page_url = NULL, page_id = NULL, ..., site = NULL)
}
\arguments{
\item{...}{
  Arguments passed on to \code{\link[=get_sp_site]{get_sp_site}}
  \describe{
    \item{\code{site_url}}{A SharePoint site URL in the format "https://[tenant
name].sharepoint.com/sites/[site name]". Any SharePoint item or document
URL can also be parsed to build a site URL using the tenant and site name
included in the URL.}
    \item{\code{site_name,site_id}}{Site name or ID of the SharePoint site as an
alternative to the SharePoint site URL. Exactly one of  \code{site_url},
\code{site_name}, and \code{site_id} must be supplied.}
    \item{\code{refresh}}{If \code{TRUE}, get a new site even if the existing site is cached
as a local option. If \code{FALSE}, use the cached \code{ms_site} object.}
    \item{\code{cache}}{If \code{TRUE}, cache site to a file using \code{\link[=cache_sp_site]{cache_sp_site()}}.}
    \item{\code{cache_file}}{File name for cached drive or site. Default \code{NULL}.}
    \item{\code{overwrite}}{If \code{TRUE}, replace the existing cached object named by
\code{cache_file} with the new object. If \code{FALSE}, error if a cached file with
the same \code{cache_file} name already exists.}
  }}

\item{site}{Optional \code{ms_site} object to use. If not provided, the \code{...}
arguments are passed to \code{\link[=get_sp_site]{get_sp_site()}}.}

\item{page_type}{Page type to request. One of "sitePage" or "page".}

\item{as_data_frame}{If \code{TRUE}, return a data frame with details on the
SharePoint site pages. If \code{FALSE}, return a list.}

\item{call}{The execution environment of a currently
running function, e.g. \code{caller_env()}. The function will be
mentioned in error messages as the source of the error. See the
\code{call} argument of \code{\link[rlang:abort]{abort()}} for more information.}

\item{page_url, page_id}{SharePoint page URL or ID.}
}
\description{
\code{\link[=list_sp_pages]{list_sp_pages()}} returns a list of SharePoint pages associated with a
specified SharePoint site. \code{\link[=get_sp_page]{get_sp_page()}} returns a single SharePoint page.
}
\keyword{pages}

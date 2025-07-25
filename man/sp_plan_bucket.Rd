% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/sp_plan_bucket.R
\name{sp_plan_bucket}
\alias{sp_plan_bucket}
\alias{list_sp_plan_buckets}
\title{List SharePoint planner buckets}
\usage{
list_sp_plan_buckets(
  plan_title = NULL,
  plan_id = NULL,
  ...,
  filter = NULL,
  n = NULL,
  plan = NULL,
  as_data_frame = TRUE,
  call = caller_env()
)
}
\arguments{
\item{plan_title, plan_id}{Planner title or ID. Exactly one of the two
arguments must be supplied.}

\item{...}{Additional arguments passed to \code{\link[=get_sp_group]{get_sp_group()}}.}

\item{filter}{A string with \href{https://learn.microsoft.com/en-us/graph/query-parameters?tabs=http#filter-parameter}{an OData expression}
apply as a filter to the results. Learn more in the \href{https://learn.microsoft.com/en-us/graph/filter-query-parameter}{Microsoft Graph API documentation}
on using filter query parameters.}

\item{n}{Maximum number of lists, plans, tasks, or other items to return.
Defaults to \code{NULL} which sets n to \code{Inf}.}

\item{plan}{A \code{ms_plan} object. If \code{plan} is supplied, \code{plan_title},
\code{plan_id}, and any additional parameters passed to \code{...} are ignored.}

\item{as_data_frame}{If \code{TRUE} (default for \code{\link[=list_sp_plan_buckets]{list_sp_plan_buckets()}}), return
a data frame of object properties with with a list column named
"ms_plan_bucket" containing \code{ms_plan_task} objects. If \code{FALSE}, return a
\code{ms_plan_bucket} object or list of \code{ms_plan_bucket} objects.}

\item{call}{The execution environment of a currently
running function, e.g. \code{caller_env()}. The function will be
mentioned in error messages as the source of the error. See the
\code{call} argument of \code{\link[rlang:abort]{abort()}} for more information.}
}
\value{
For \code{\link[=list_sp_plan_buckets]{list_sp_plan_buckets()}}, a list of \code{ms_plan_bucket} class
objects or a data frame with a list column named "ms_plan_task".
}
\description{
\code{\link[=list_sp_plan_buckets]{list_sp_plan_buckets()}} lists the buckets for a specified plan using the
\code{list_buckets} method.
}
\seealso{
\link[Microsoft365R:ms_plan_task]{Microsoft365R::ms_plan_task}
}
\keyword{plans}

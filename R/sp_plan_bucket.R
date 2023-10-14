
#' List SharePoint planner buckets
#'
#' [list_sp_plan_buckets()] lists the buckets for a specified plan using the
#' `list_buckets` method.
#'
#' @name sp_plan_bucket
#' @param as_data_frame If `TRUE` (default for [list_sp_plan_buckets()]), return
#'   a data frame of object properties with with a list column named
#'   "ms_plan_bucket" containing `ms_plan_task` objects. If `FALSE`, return a
#'   `ms_plan_bucket` object or list of `ms_plan_bucket` objects.
#' @seealso [Microsoft365R::ms_plan_task]
NULL

#' @rdname sp_plan_bucket
#' @name list_sp_plan_buckets
#' @inheritParams Microsoft365R::ms_plan_task
#' @inheritParams get_sp_plan
#' @inheritParams ms_graph_arg_terms
#' @inheritParams ms_graph_obj_terms
#' @returns For [list_sp_plan_buckets()], a list of `ms_plan_bucket` class
#'   objects or a data frame with a list column named "ms_plan_task".
#' @export
list_sp_plan_buckets <- function(plan_title = NULL,
                                 plan_id = NULL,
                                 ...,
                                 filter = NULL,
                                 n = NULL,
                                 plan = NULL,
                                 as_data_frame = TRUE,
                                 call = caller_env()) {
  plan <- plan %||%
    get_sp_plan(plan_title = plan_title, plan_id = plan_id, ..., call = call)

  check_ms_obj(plan, "ms_plan", call = call)

  plan_buckets <- plan$list_buckets(
    filter = filter,
    n = n %||% Inf
  )

  if (!as_data_frame) {
    return(plan_buckets)
  }

  ms_obj_list_as_data_frame(
    plan_buckets,
    obj_col = "ms_plan_bucket",
    .error_call = call
  )
}

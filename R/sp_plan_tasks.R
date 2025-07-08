#' Get a SharePoint task or list tasks from a planner
#'
#' [get_sp_task()] gets an individual planner task using the `get_task` method.
#' [list_sp_tasks()] lists the tasks for a specified plan using the `list_tasks`
#' method.
#'
#' @name sp_tasks
#' @param as_data_frame If `TRUE` (default for [list_sp_tasks()]), return a data
#'   frame of object properties with with a list column named "ms_plan_task"
#'   containing `ms_plan_task` objects. If `FALSE` (default [get_sp_task()]),
#'   return a `ms_plan_task` object or list of `ms_plan_task` objects.
#' @seealso [Microsoft365R::ms_plan_task]
NULL

#' @rdname sp_tasks
#' @name list_sp_tasks
#' @param task_title,task_id Planner task title and id. Exactly one of
#'   `task_title` and `task_id` must be supplied.
#' @export
get_sp_task <- function(
  task_title = NULL,
  task_id = NULL,
  ...,
  plan_title = NULL,
  plan_id = NULL,
  plan = NULL,
  as_data_frame = FALSE,
  call = caller_env()
) {
  plan <- plan %||%
    get_sp_plan(plan_title = plan_title, plan_id = plan_id, ..., call = call)

  check_ms_obj(plan, "ms_plan", call = call)

  check_exclusive_strings(task_title, task_id, call = call)

  task <- plan$get_task(task_title = task_title, task_id = task_id)

  if (!as_data_frame) {
    return(task)
  }

  ms_obj_list_as_data_frame(
    task,
    obj_col = "ms_plan_task",
    .error_call = call
  )
}

#' @rdname sp_tasks
#' @name list_sp_tasks
#' @inheritParams Microsoft365R::ms_plan_task
#' @inheritParams get_sp_plan
#' @inheritParams ms_graph_arg_terms
#' @inheritParams ms_graph_obj_terms
#' @returns For [list_sp_tasks()], a list of `ms_plan_task` class objects or a
#'   data frame with a list column named "ms_plan_task".
#' @export
list_sp_tasks <- function(
  plan_title = NULL,
  plan_id = NULL,
  ...,
  filter = NULL,
  n = NULL,
  plan = NULL,
  as_data_frame = TRUE,
  call = caller_env()
) {
  plan <- plan %||%
    get_sp_plan(plan_title = plan_title, plan_id = plan_id, ..., call = call)

  check_ms_obj(plan, "ms_plan", call = call)

  plan_tasks <- plan$list_tasks(
    filter = filter,
    n = n %||% Inf
  )

  if (!as_data_frame) {
    return(plan_tasks)
  }

  ms_obj_list_as_data_frame(
    plan_tasks,
    obj_col = "ms_plan_task",
    .error_call = call
  )
}

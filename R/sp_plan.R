#' Get a SharePoint plan or list SharePoint plans
#'
#' [get_sp_plan()] returns a single `ms_plan` object using the `get_plan`
#' method. [list_sp_plans()] returns a data frame with plan properties or a list
#' of `ms_plan` objects.
#'
#' @name sp_plan
#' @inheritParams get_sp_site_group
#' @param as_data_frame If `TRUE` (default for [list_sp_plans()]), return a data
#'   frame with the plan title, id, creation date/time, and owner ID with a list
#'   column named "ms_plan" containing `ms_plan` objects. If `FALSE` (default
#'   [get_sp_plan()]), return a `ms_plan` object or list of `ms_plan` objects.
#' @seealso [Microsoft365R::ms_plan]
NULL

#' @rdname sp_plan
#' @name get_sp_plan
#' @param plan_title,plan_id Planner title or ID. Exactly one of the two
#'   arguments must be supplied.
#' @inheritParams Microsoft365R::ms_plan
#' @returns For [get_sp_plan()], a `ms_plan` class object or a 1 row data frame
#'   with a "ms_plan" column.
#' @export
get_sp_plan <- function(plan_title = NULL,
                        plan_id = NULL,
                        ...,
                        site = NULL,
                        site_url = NULL,
                        as_data_frame = FALSE,
                        call = caller_env()) {
  if (is_url(plan_title)) {
    site_url <- site_url %||% plan_title
  }

  grp <- get_sp_site_group(
    site = site,
    site_url = site_url,
    ...,
    call = call
  )

  check_exclusive_strings(plan_title, plan_id, call = call)

  plan <- grp$get_plan(
    plan_title = plan_title,
    plan_id = plan_id
  )

  if (!as_data_frame) {
    return(plan)
  }

  ms_obj_list_as_data_frame(
    plan,
    obj_col = "ms_plan"
  )
}


#' @rdname sp_plan
#' @name list_sp_plans
#' @param ... Additional arguments passed to [get_sp_site_group()].
#' @inheritParams ms_graph_terms
#' @returns For [list_sp_plans()], A list of `ms_plan` class objects or a data
#'   frame with a list column named "ms_plan".
#' @export
list_sp_plans <- function(...,
                          filter = NULL,
                          n = NULL,
                          site = NULL,
                          as_data_frame = TRUE,
                          call = caller_env()) {
  grp <- get_sp_site_group(
    ...,
    site = site,
    call = call
  )

  check_ms(grp, "az_group", call = call)

  plan_list <- grp$list_plans(
    filter = filter,
    n = n %||% Inf
  )

  if (!as_data_frame) {
    return(plan_list)
  }

  ms_obj_list_as_data_frame(
    plan_list,
    obj_col = "ms_plan"
  )
}


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
get_sp_task <- function(task_title = NULL,
                        task_id = NULL,
                        ...,
                        plan_title = NULL,
                        plan_id = NULL,
                        plan = NULL,
                        as_data_frame = FALSE,
                        call = caller_env()) {
  plan <- plan %||%
    get_sp_plan(plan_title = plan_title, plan_id = plan_id, ..., call = call)

  check_ms(plan, "ms_plan", call = call)

  check_exclusive_strings(task_title, task_id, call = call)

  task <- plan$get_task(task_title = task_title, task_id = task_id)

  if (!as_data_frame) {
    return(task)
  }

  ms_obj_list_as_data_frame(
    task,
    obj_col = "ms_plan_task",
    .error_call = call
  )}

#' @rdname sp_tasks
#' @name list_sp_tasks
#' @inheritParams Microsoft365R::ms_plan_task
#' @inheritParams get_sp_plan
#' @inheritParams ms_graph_terms
#' @param plan A `ms_plan` object. If `plan` is supplied, `plan_title`,
#'   `plan_id`, and any additional parameters passed to `...` are ignored.
#' @returns For [list_sp_tasks()], a list of `ms_plan_task` class objects or a
#'   data frame with a list column named "ms_plan_task".
#' @export
list_sp_tasks <- function(plan_title = NULL,
                          plan_id = NULL,
                          ...,
                          filter = NULL,
                          n = NULL,
                          plan = NULL,
                          as_data_frame = TRUE,
                          call = caller_env()) {
  plan <- plan %||%
    get_sp_plan(plan_title = plan_title, plan_id = plan_id, ..., call = call)

  check_ms(plan, "ms_plan", call = call)

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

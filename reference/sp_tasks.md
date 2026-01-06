# Get a SharePoint task or list tasks from a planner

`get_sp_task()` gets an individual planner task using the `get_task`
method. `list_sp_tasks()` lists the tasks for a specified plan using the
`list_tasks` method.

## Usage

``` r
get_sp_task(
  task_title = NULL,
  task_id = NULL,
  ...,
  plan_title = NULL,
  plan_id = NULL,
  plan = NULL,
  as_data_frame = FALSE,
  call = caller_env()
)

list_sp_tasks(
  plan_title = NULL,
  plan_id = NULL,
  ...,
  filter = NULL,
  n = NULL,
  plan = NULL,
  as_data_frame = TRUE,
  call = caller_env()
)
```

## Arguments

- task_title, task_id:

  Planner task title and id. Exactly one of `task_title` and `task_id`
  must be supplied.

- ...:

  Additional arguments passed to
  [`get_sp_group()`](https://elipousson.github.io/sharepointr/reference/get_sp_group.md).

- plan_title, plan_id:

  Planner title or ID. Exactly one of the two arguments must be
  supplied.

- plan:

  A `ms_plan` object. If `plan` is supplied, `plan_title`, `plan_id`,
  and any additional parameters passed to `...` are ignored.

- as_data_frame:

  If `TRUE` (default for `list_sp_tasks()`), return a data frame of
  object properties with with a list column named "ms_plan_task"
  containing `ms_plan_task` objects. If `FALSE` (default
  `get_sp_task()`), return a `ms_plan_task` object or list of
  `ms_plan_task` objects.

- call:

  The execution environment of a currently running function, e.g.
  `caller_env()`. The function will be mentioned in error messages as
  the source of the error. See the `call` argument of
  [`abort()`](https://rlang.r-lib.org/reference/abort.html) for more
  information.

- filter:

  A string with [an OData
  expression](https://learn.microsoft.com/en-us/graph/query-parameters?tabs=http#filter-parameter)
  apply as a filter to the results. Learn more in the [Microsoft Graph
  API
  documentation](https://learn.microsoft.com/en-us/graph/filter-query-parameter)
  on using filter query parameters.

- n:

  Maximum number of lists, plans, tasks, or other items to return.
  Defaults to `NULL` which sets n to `Inf`.

## Value

For `list_sp_tasks()`, a list of `ms_plan_task` class objects or a data
frame with a list column named "ms_plan_task".

## See also

[Microsoft365R::ms_plan_task](https://rdrr.io/pkg/Microsoft365R/man/ms_plan_task.html)

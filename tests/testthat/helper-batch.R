# Mock sp_graph_batch_requests() to send each request in a $batch request
# with the do_operation method of a fake ms_list. Tests that record the
# requests sent for each item then work the same with `.batch = TRUE` and
# `.batch = FALSE`.
#
# sp_graph_batch() can't be mocked for this since purrr::in_parallel() replaces
# the environment of the mocked function (so it can't find `sp_list`).
local_batch_with_do_operation <- function(sp_list, env = parent.frame()) {
  local_mocked_bindings(
    sp_graph_batch_requests = function(token, requests, ...) {
      purrr::imap(
        unname(requests),
        \(request, i) {
          # e.g. "/sites/{site-id}/lists/{list-id}/items/1" -> "items/1"
          args <- list(sub("^/sites/[^/]*/lists/[^/]*/", "", request[["url"]]))

          if (!is.null(request[["body"]])) {
            args[["body"]] <- request[["body"]]
          }

          args[["http_verb"]] <- request[["method"]]
          do.call(sp_list$do_operation, args)

          list(id = as.character(i), status = 200L)
        }
      )
    },
    .env = env
  )
}

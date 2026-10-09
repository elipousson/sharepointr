# get_sp_list_view gets views by title, id, or the default view

    Code
      get_sp_list_view(new_fake_ms_list(), view_title = "A", view_id = "B")
    Condition
      Error:
      ! Supply `view_title` or `view_id`, not both.

# update_sp_list_view and delete_sp_list_view protect the default view

    Code
      update_sp_list_view(new_fake_ms_list(), view_title = "All Items", default_view = FALSE)
    Condition
      Error:
      ! "All Items" is the default view.
      i Set another view as the default view instead.
    Code
      delete_sp_list_view(new_fake_ms_list(), view_title = "All Items", confirm = FALSE)
    Condition
      Error:
      ! "All Items" is the default view and can't be deleted.
      i Set another view as the default view first.
    Code
      delete_sp_list_view(new_fake_ms_list())
    Condition
      Error:
      ! `view_title` or `view_id` must be supplied.

# validate_view_definition validates view properties

    Code
      validate_view_definition(list(Title = "A", row_limit = 10))
    Condition
      Error:
      ! A has unknown view property: row_limit.
      i Use RowLimit in place of row_limit.
      i Allowed properties: Title, ViewFields, ViewQuery, RowLimit, Paged, DefaultView, Hidden, Scope, CustomFormatter, MobileView, and MobileDefaultView.
    Code
      validate_view_definition(list(RowLimit = 10))
    Condition
      Error:
      ! `view.Title` must be a single string, not `NULL`.
    Code
      validate_view_definition(list(Title = "A", Scope = 5))
    Condition
      Error:
      ! `A.Scope` must be a whole number between 0 and 3, not the number 5.
    Code
      validate_view_definition(list(Title = "A", CustomFormatter = "{not json"))
    Condition
      Error:
      ! `A.CustomFormatter` must be valid JSON.


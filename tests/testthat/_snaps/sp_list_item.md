# match_sp_list_field_names() matches names to list fields

    Code
      match_sp_list_field_names(c("Title", "Other", "ContentType"), values)
    Message
      ! All column names in `data` must match field names in the supplied list.
      i Columns "Other" and "ContentType" dropped from `data`
    Output
      [1]  TRUE FALSE FALSE
    Code
      match_sp_list_field_names(c("Title", "Other"), values, what = "field")
    Message
      ! All field names in `data` must match field names in the supplied list.
      i Field "Other" dropped from `data`
    Output
      [1]  TRUE FALSE

---

    Code
      match_sp_list_field_names("Other", values, what = "field")
    Condition
      Error:
      ! At least one field in `data` must match field names in the supplied list.
      i Field names from list are "Title" and "Status"

---

    Code
      match_sp_list_field_names(c("Title", "Other"), values, strict = TRUE)
    Condition
      Error:
      ! All column names in `data` must match field names in the supplied list.
      i Field names from list are "Title" and "Status"

# check_sp_list_values() reports values that don't match the list

    Code
      check_sp_list_values(data, specs, validate = "error")
    Condition
      Warning:
      1 value in `data` doesn't match the list column definitions.
      x Row 3, Title: a value is required
      Error:
      ! 3 values in `data` don't match the list column definitions.
      x Row 2, Title: 8 characters (maximum 5)
      x Row 2, Status: "C" is not a choice
      x Row 3, Count: 11 is outside 0 to 10

# check_sp_list_values() checks required values for create and update

    Code
      check_sp_list_values(list(Status = "C"), specs, "error")
    Condition
      Warning:
      1 value in `data` doesn't match the list column definitions.
      x Row 1, Title: a value is required
      Error:
      ! 1 value in `data` doesn't match the list column definitions.
      x Row 1, Status: "C" is not a choice


# sp_workbook_request() aborts with a hint for a known inner error code

    Code
      sp_workbook_request(item, "worksheets")
    Condition
      Error:
      ! Can't send a "GET" request to the workbook "Book.xlsx".
      x The request conflicts.
      i Another user may have the workbook locked for editing. Try again after they close it.

# sp_workbook_request() aborts without a hint for unknown error codes

    Code
      sp_workbook_request(item, "worksheets")
    Condition
      Error:
      ! Can't send a "GET" request to the workbook "Book.xlsx".
      x Something failed.


# Create listinfo object

Helper function to create a listInfo object for use internally by
[`create_sp_list()`](https://elipousson.github.io/sharepointr/reference/create_sp_list.md).
See:
<https://learn.microsoft.com/en-us/graph/api/resources/listinfo?view=graph-rest-1.0>

## Usage

``` r
create_list_info(
  template = c("documentLibrary", "genericList", "task", "survey", "announcements",
    "contacts"),
  content_types = NULL,
  hidden = NULL,
  call = caller_env()
)
```

## Arguments

- template:

  Type of template to use in creating the list.

- content_types:

  Optional. Set `TRUE` for `contentTypesEnabled` to be enabled.

- hidden:

  Optional. Set `TRUE` for list to be hidden.

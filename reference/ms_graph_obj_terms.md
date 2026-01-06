# Shared general definitions for Microsoft Graph objects

Shared general definitions for Microsoft Graph objects

## Arguments

- site:

  A `ms_site` object. If `site` is supplied, `site_url`, `site_name`,
  and `site_id` are ignored.

- plan:

  A `ms_plan` object. If `plan` is supplied, `plan_title`, `plan_id`,
  and any additional parameters passed to `...` are ignored.

- sp_list:

  A `ms_list` object. If supplied, `list_name`, `list_id`, `site_url`,
  `site`, `drive_name`, `drive_id`, `drive`, and any additional
  parameters passed to `...` are all ignored.

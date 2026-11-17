# check_sp_drive_folders normalizes folder paths

    Code
      check_sp_drive_folders(1)
    Condition
      Error:
      ! folders must be a character vector of folder paths (a YAML sequence of strings).
    Code
      check_sp_drive_folders(c("A", "/A"))
    Condition
      Error:
      ! folders must be unique. Duplicated: "A".
    Code
      check_sp_drive_folders(c("", "A|B"))
    Condition
      Error:
      ! folders has invalid folder path: "" and "A|B".
      i Separate folders with `/`. A folder name can't be empty, start or end with a space, end with a period, or include any of `" * : < > ? \ |`.

# create_sp_drive errors for a template or a list definition

    Code
      create_sp_drive("Test", template = "genericList")
    Condition
      Error in `create_sp_drive()`:
      ! `template` can't be set: a drive is always created with the "documentLibrary" template.
    Code
      create_sp_drive(definition = list(displayName = "Test", list = list(template = "genericList"),
      columns = list()))
    Condition
      Error in `create_sp_drive()`:
      ! `definition` must use the "documentLibrary" template, not "genericList".
      i Use `create_sp_list()` to create a list.
    Code
      create_sp_drive("Test", folders = "A:B")
    Condition
      Error in `create_sp_drive()`:
      ! folders has invalid folder path: "A:B".
      i Separate folders with `/`. A folder name can't be empty, start or end with a space, end with a period, or include any of `" * : < > ? \ |`.

# update_sp_drive and delete_sp_drive check their inputs

    Code
      update_sp_drive(drive = onedrive)
    Condition
      Error in `update_sp_drive()`:
      ! `display_name` or `description` must be supplied.
    Code
      update_sp_drive(drive = onedrive, display_name = "New")
    Condition
      Error in `update_sp_drive()`:
      ! `drive` must be a SharePoint document library, not a "business" drive.
    Code
      delete_sp_drive(drive = onedrive)
    Condition
      Error in `delete_sp_drive()`:
      ! `drive` must be a SharePoint document library, not a "business" drive.
    Code
      delete_sp_drive(drive = "Documents")
    Condition
      Error in `delete_sp_drive()`:
      ! `drive` must be ms_drive, not the string "Documents".

# create_sp_list errors for folders in a list definition

    Code
      create_sp_list(definition = definition, template = "genericList")
    Condition
      Error in `create_sp_list()`:
      ! Folders can only be created for a "documentLibrary" library, not a "genericList" list.


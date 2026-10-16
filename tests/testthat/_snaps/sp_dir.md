# sp_dir_info() errors for a file URL from the shares API

    Code
      sp_dir_info(
        "https://contoso.sharepoint.com/sites/Team/Shared%20Documents/Folder/A.csv")
    Condition
      Error:
      ! `path` must be a folder or document library URL.
      i <https://contoso.sharepoint.com/sites/Team/Shared%20Documents/Folder/A.csv> is a file.

# sp_dir_info() falls back to the parsed URL if the shares API fails

    Code
      sp_dir_info(
        "https://contoso.sharepoint.com/sites/Team/Shared%20Documents/Folder")
    Condition
      Error:
      ! Can't get a SharePoint folder from <https://contoso.sharepoint.com/sites/Team/Shared%20Documents/Folder>.
      Caused by error in `sp_shares_get_drive_path()`:
      ! Forbidden (HTTP 403).


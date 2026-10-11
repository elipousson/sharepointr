# upload_sp_item() errors if `dest` is a file URL

    Code
      upload_sp_item(local_file, dest = "https://contoso.sharepoint.com/sites/Team/Shared%20Documents/Folder/A.csv")
    Condition
      Error:
      ! `dest` must be a folder or document library URL.
      i <https://contoso.sharepoint.com/sites/Team/Shared%20Documents/Folder/A.csv> is a file.


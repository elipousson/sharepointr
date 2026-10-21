# write_sharepoint() errors for a shapefile

    Code
      write_sharepoint(nc, "nc.shp", new_path = withr::local_tempdir())
    Condition
      Error:
      ! `file` can't be a shapefile.
      i Use a single file format like GeoPackage ('.gpkg') or GeoJSON ('.geojson') instead.

# upload_sp_item() errors if `dest` is a file URL

    Code
      upload_sp_item(local_file, dest = "https://contoso.sharepoint.com/sites/Team/Shared%20Documents/Folder/A.csv")
    Condition
      Error:
      ! `dest` must be a folder or document library URL.
      i <https://contoso.sharepoint.com/sites/Team/Shared%20Documents/Folder/A.csv> is a file.


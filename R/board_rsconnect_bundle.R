rsc_bundle <- function(board, name, path, metadata, x = NULL, bundle_path = tempfile()) {
  fs::dir_create(bundle_path)

  # Bundle contains:
  # * pin
  fs::file_copy(path, fs::path(bundle_path, fs::path_file(path)))

  # * data.txt (used to retrieve pins)
  yaml::write_yaml(metadata, fs::path(bundle_path, "data.txt"))

  # * index.html
  rsc_bundle_preview_create(board, name, metadata, path = bundle_path, x = x)

  # * manifest.json (used for deployment)
  manifest <- rsc_bundle_manifest(board, c(path, "data.txt", "index.html"))
  jsonlite::write_json(manifest, fs::path(bundle_path, "manifest.json"), auto_unbox = TRUE)

  invisible(bundle_path)
}

# Extracted from rsconnect:::createAppManifest
rsc_bundle_manifest <- function(board, files) {
  list(
    version = 1,
    locale = "en_US",
    platform = "3.5.1",
    metadata = list(
      appmode = "static",
      primary_rmd = NA,
      primary_html = "index.html",
      content_category = "pin",
      has_parameters = FALSE
    ),
    packages = NA,
    files = files,
    users = NA
  )
}

rsc_bundle_preview_create <- function(board, name, x, metadata, path) {
  # Copy support files
  template <- fs::dir_ls(fs::path_package("pins", "preview"))
  file.copy(template, path, recursive = TRUE)

  # Update index template with pin data
  index <- rsc_bundle_preview_index(board, name, x, metadata)
  writeLines(index, fs::path(path, "index.html"))

  invisible(path)
}

rsc_bundle_preview_index <- function(board, name, x, metadata) {
  data_preview <- rsc_bundle_preview_data(x)

  data <- list(
    pin_files = paste0("<a href=\"", metadata$file, "\">", metadata$file, "</a>", collapse = ", "),
    data_preview = jsonlite::toJSON(data_preview, auto_unbox = TRUE),
    data_preview_style = if (is.data.frame(x)) "" else "display:none",
    pin_name = paste0(board$account, "/", name),
    pin_metadata = jsonlite::toJSON(metadata, auto_unbox = TRUE, pretty = TRUE),
    server_name = board$server
  )

  template <- readLines(fs::path_package("pins", "preview", "index.html"))
  whisker::whisker.render(template, data)
}

rsc_bundle_preview_data <- function(df, n = 100) {
  if (!is.data.frame(df)) {
    return(list(data = list(), columns = list()))
  }

  cols <- lapply(colnames(df), function(col) {
    list(
      name = col,
      label = col,
      align = if (is.numeric(df[[col]])) "right" else "left",
      type = ""
    )
  })

  rows <- utils::head(df, n = n)

  # https://github.com/mlverse/pagedtablejs
  list(
    data = rows,
    columns = cols,
    options = list(
      columns = list(max = 10),
      rows = list(min = 1, total = nrow(rows))
    )
  )
}

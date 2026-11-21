library(toad)

# -----------------------------------------------------------------------------
# available_datasets()
# -----------------------------------------------------------------------------
expect_equal(
  available_datasets(),
  c("HCP1065", "TractSeg"),
  info = "available_datasets returns HCP1065 and TractSeg"
)

# -----------------------------------------------------------------------------
# available_bundles()
# -----------------------------------------------------------------------------
expect_equal(length(available_bundles("HCP1065")), 87L)
expect_true("Left Arcuate Fasciculus" %in% available_bundles("HCP1065"))
expect_true("Corpus Callosum" %in% available_bundles("HCP1065"))

expect_equal(length(available_bundles("TractSeg")), 72L)
expect_true("Left Arcuate Fasciculus" %in% available_bundles("TractSeg"))
expect_true("Corpus Callosum" %in% available_bundles("TractSeg"))

expect_error(available_bundles("unknown"), "Dataset not supported")

# -----------------------------------------------------------------------------
# .toad_interp()
# -----------------------------------------------------------------------------
interp <- toad:::.toad_interp

x <- "HCP1065"
expect_equal(interp("{x}"), "HCP1065")
expect_equal(interp("{no_such_var_xyz}"), "{no_such_var_xyz}")

bundle_name <- "Left Fornix"
expect_true(grepl("Left Fornix", interp("{.val {bundle_name}}")))

# -----------------------------------------------------------------------------
# .toad_abort_base() – base-R fallback
# -----------------------------------------------------------------------------
expect_error(toad:::.toad_abort_base("single line error", env = environment()))

msg_multi <- c("header line", i = "info line", x = "extra line")
expect_error(toad:::.toad_abort_base(msg_multi, env = environment()))

msg_empty_prefix <- c("first line", "second line")
names(msg_empty_prefix) <- c("i", "")
expect_error(toad:::.toad_abort_base(msg_empty_prefix, env = environment()))

# -----------------------------------------------------------------------------
# .toad_abort() – cli branch and no-cli branch
# -----------------------------------------------------------------------------
expect_error(toad:::.toad_abort("test error message"))

old_opt <- options(toad.no_cli = TRUE)
expect_error(toad:::.toad_abort("no-cli single error"))
options(old_opt)

# -----------------------------------------------------------------------------
# .toad_download_file() – exercised with a file:// URL (no network)
# -----------------------------------------------------------------------------
fake_obj <- list(check = "download_file_coverage")
src_file <- tempfile(fileext = ".rds")
dst_file <- tempfile(fileext = ".rds")
saveRDS(fake_obj, src_file)
toad:::.toad_download_file(paste0("file://", src_file), dst_file)
expect_equal(readRDS(dst_file), fake_obj)
unlink(c(src_file, dst_file))

# -----------------------------------------------------------------------------
# .tractseg_release_json() – via file:// URL (no network)
# -----------------------------------------------------------------------------
json_file <- tempfile(fileext = ".json")
writeLines(
  '{"assets":[{"name":"TractSeg_100307_AF_left.rds"},{"name":"TractSeg_100408_AF_left.rds"}]}',
  json_file
)
payload <- toad:::.tractseg_release_json(
  "AF_left",
  paste0("file://", json_file)
)
expect_true(grepl("TractSeg_100307_AF_left.rds", payload, fixed = TRUE))
unlink(json_file)

# Missing file -> NULL (no error)
expect_equal(
  toad:::.tractseg_release_json("NOPE", "file:///nonexistent/release.json"),
  NULL
)

# Default API URL construction (api_url = NULL branch)
expect_equal(
  toad:::.tractseg_api_url("AF_left"),
  "https://api.github.com/repos/tractoverse/toad/releases/tags/tractseg-AF_left"
)
# The default branch of .tractseg_release_json() builds the API URL itself.
# Mock .tractseg_read_release() so no network is required.
orig_read_release <- get(".tractseg_read_release", envir = asNamespace("toad"))
default_payload <- '{"assets":[{"name":"TractSeg_100307_AF_left.rds"}]}'
assignInNamespace(
  ".tractseg_read_release",
  function(api_url) {
    expect_equal(
      api_url,
      "https://api.github.com/repos/tractoverse/toad/releases/tags/tractseg-AF_left"
    )
    default_payload
  },
  ns = "toad"
)
expect_true(grepl(
  "TractSeg_100307_AF_left.rds",
  toad:::.tractseg_release_json("AF_left"),
  fixed = TRUE
))
assignInNamespace(".tractseg_read_release", orig_read_release, ns = "toad")

# -----------------------------------------------------------------------------
# .tractseg_release_assets() / .tractseg_subject_ids() – pure parsing
# -----------------------------------------------------------------------------
json_text <- paste0(
  '{"assets":[',
  '{"name":"TractSeg_100307_AF_left.rds"},',
  '{"name":"TractSeg_100408_AF_left.rds"},',
  '{"name":"TractSeg_101006_AF_left.rds"},',
  '{"name":"README.md"}',
  ']}'
)
assets <- toad:::.tractseg_release_assets(json_text, "AF_left")
expect_equal(length(assets), 3L)
expect_equal(
  toad:::.tractseg_subject_ids(assets, "AF_left"),
  c("100307", "100408", "101006")
)

# Subject IDs are filtered to the requested bundle stem
mixed <- c(
  "TractSeg_100307_AF_left.rds",
  "TractSeg_100307_AF_right.rds",
  "not-a-subject-file.rds"
)
expect_equal(
  toad:::.tractseg_subject_ids(mixed, "AF_left"),
  "100307"
)

# -----------------------------------------------------------------------------
# .tractseg_subject_list() – full pipeline with the network seam mocked
# -----------------------------------------------------------------------------
orig_release_json <- get(".tractseg_release_json", envir = asNamespace("toad"))
assignInNamespace(
  ".tractseg_release_json",
  function(bundle_stem, api_url = NULL) json_text,
  ns = "toad"
)
expect_equal(
  toad:::.tractseg_subject_list("AF_left"),
  c("100307", "100408", "101006")
)

# NULL payload (release not published) -> character(0)
assignInNamespace(
  ".tractseg_release_json",
  function(bundle_stem, api_url = NULL) NULL,
  ns = "toad"
)
expect_equal(
  toad:::.tractseg_subject_list("BUNDLE_DOES_NOT_EXIST_XYZ"),
  character(0L)
)

assignInNamespace(".tractseg_release_json", orig_release_json, ns = "toad")

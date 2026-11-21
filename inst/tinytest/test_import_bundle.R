library(toad)

# -----------------------------------------------------------------------------
# Helpers: real fiber bundles so fiber::bundle_set() validates
# -----------------------------------------------------------------------------
make_bundle <- function(name) {
  sl <- fiber::streamline(points = cbind(X = 0:2, Y = 0:2, Z = 0:2))
  fiber::bundle(streamlines = list(sl), bundle_data = list(name = name))
}

mock_download <- function(bundle_obj = make_bundle("mock")) {
  orig_dl <- get(".toad_download_file", envir = asNamespace("toad"))
  assignInNamespace(
    ".toad_download_file",
    function(url, destfile) saveRDS(bundle_obj, destfile),
    ns = "toad"
  )
  orig_dl
}

restore_download <- function(orig_dl) {
  assignInNamespace(".toad_download_file", orig_dl, ns = "toad")
}

mock_subjects <- function(subjects = c("100307", "100408", "101006")) {
  orig_tsl <- get(".tractseg_subject_list", envir = asNamespace("toad"))
  assignInNamespace(
    ".tractseg_subject_list",
    function(bundle_stem) subjects,
    ns = "toad"
  )
  orig_tsl
}

restore_subjects <- function(orig_tsl) {
  assignInNamespace(".tractseg_subject_list", orig_tsl, ns = "toad")
}

# -----------------------------------------------------------------------------
# Error paths
# -----------------------------------------------------------------------------
expect_error(
  import_bundle("bad_dataset", "Left Fornix"),
  "Dataset not supported"
)

expect_error(
  import_bundle("HCP1065", "Not A Real Bundle"),
  "does not contain the bundle"
)

# -----------------------------------------------------------------------------
# HCP1065 happy path (download mocked)
# -----------------------------------------------------------------------------
fake_hcp <- make_bundle("HCP1065 AC")
orig_dl <- mock_download(fake_hcp)
result <- import_bundle("HCP1065", "Anterior Commissure")
restore_download(orig_dl)
expect_equal(result, fake_hcp)

# -----------------------------------------------------------------------------
# TractSeg: subjects = NULL  ->  bundle_set of all subjects
# -----------------------------------------------------------------------------
fake_ts <- make_bundle("TractSeg AF left")
orig_tsl <- mock_subjects()
orig_dl <- mock_download(fake_ts)
res_null <- import_bundle(
  "TractSeg",
  "Left Arcuate Fasciculus",
  subjects = NULL
)
restore_subjects(orig_tsl)
restore_download(orig_dl)
expect_true(fiber::is_bundle_set(res_null))
expect_equal(res_null@n_bundles, 3L)
expect_equal(
  res_null@bundle_data$id_from_input_names,
  c("100307", "100408", "101006")
)
expect_equal(res_null[[1L]], fake_ts)

# -----------------------------------------------------------------------------
# TractSeg: subjects = integer  ->  random sample
# -----------------------------------------------------------------------------
set.seed(5732L)
orig_tsl <- mock_subjects()
orig_dl <- mock_download(fake_ts)
res_int <- import_bundle("TractSeg", "Left Arcuate Fasciculus", subjects = 2L)
restore_subjects(orig_tsl)
restore_download(orig_dl)
expect_true(fiber::is_bundle_set(res_int))
expect_equal(res_int@n_bundles, 2L)
expect_true(all(
  res_int@bundle_data$id_from_input_names %in% c("100307", "100408", "101006")
))

# -----------------------------------------------------------------------------
# TractSeg: subjects = single character  ->  bare bundle
# -----------------------------------------------------------------------------
orig_tsl <- mock_subjects()
orig_dl <- mock_download(fake_ts)
res_chr <- import_bundle(
  "TractSeg",
  "Left Arcuate Fasciculus",
  subjects = "100307"
)
restore_subjects(orig_tsl)
restore_download(orig_dl)
expect_equal(res_chr, fake_ts)

# -----------------------------------------------------------------------------
# TractSeg: subjects = character vector  ->  bundle_set in that order
# -----------------------------------------------------------------------------
orig_tsl <- mock_subjects()
orig_dl <- mock_download(fake_ts)
res_vec <- import_bundle(
  "TractSeg",
  "Left Arcuate Fasciculus",
  subjects = c("100408", "100307")
)
restore_subjects(orig_tsl)
restore_download(orig_dl)
expect_true(fiber::is_bundle_set(res_vec))
expect_equal(
  res_vec@bundle_data$id_from_input_names,
  c("100408", "100307")
)

# -----------------------------------------------------------------------------
# TractSeg: error paths
# -----------------------------------------------------------------------------
# invalid subject ID
orig_tsl <- mock_subjects()
expect_error(
  import_bundle("TractSeg", "Left Arcuate Fasciculus", subjects = "999999"),
  "not found in the TractSeg dataset"
)
restore_subjects(orig_tsl)

# integer out of range
orig_tsl <- mock_subjects()
expect_error(
  import_bundle("TractSeg", "Left Arcuate Fasciculus", subjects = 99L),
  "must be between"
)
restore_subjects(orig_tsl)

# invalid bundle name
expect_error(
  import_bundle("TractSeg", "Not A Real Bundle"),
  "does not contain the bundle"
)

# release not published -> .tractseg_subject_list returns character(0)
# Match on conditionMessage() rather than expect_error's pattern argument:
# cli_abort stores only the header line in the condition's `message` field
# (the bullets live in `body` and are composed by conditionMessage()), and
# tinytest <= 1.4.1 greps `e$message` while 1.4.3+ greps conditionMessage().
# The pattern lives on the second (bulleted) line, so expect_error would pass
# or fail depending on the installed tinytest version.
orig_tsl <- mock_subjects(character(0L))
err <- tryCatch(
  import_bundle("TractSeg", "Left Arcuate Fasciculus"),
  error = identity
)
expect_true(inherits(err, "error"))
expect_true(grepl("may not have been published yet", conditionMessage(err)))
restore_subjects(orig_tsl)

# invalid subjects type
orig_tsl <- mock_subjects()
expect_error(
  import_bundle("TractSeg", "Left Arcuate Fasciculus", subjects = TRUE),
  "must be NULL, an integer count, or a subject ID string"
)
restore_subjects(orig_tsl)

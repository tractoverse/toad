library(toad)

# The TractSeg convenience accessors each delegate to import_bundle() with the
# matching bundle name. Mock the network seams so no network is required and
# verify every accessor returns a bundle_set of the mocked subject bundles.
fake_bundle <- {
  sl <- fiber::streamline(points = cbind(X = 0:2, Y = 0:2, Z = 0:2))
  fiber::bundle(streamlines = list(sl), bundle_data = list(mock = TRUE))
}
fake_subjects <- c("100307", "100408")

orig_dl <- get(".toad_download_file", envir = asNamespace("toad"))
orig_tsl <- get(".tractseg_subject_list", envir = asNamespace("toad"))

assignInNamespace(
  ".toad_download_file",
  function(url, destfile) saveRDS(fake_bundle, destfile),
  ns = "toad"
)
assignInNamespace(
  ".tractseg_subject_list",
  function(bundle_stem) fake_subjects,
  ns = "toad"
)

bundle_fns <- ls(asNamespace("toad"))
bundle_fns <- bundle_fns[grepl("^TractSeg_", bundle_fns)]
bundle_fns <- bundle_fns[vapply(
  bundle_fns,
  function(n) is.function(get(n, envir = asNamespace("toad"))),
  logical(1)
)]

expect_true(length(bundle_fns) == 72L, info = "72 TractSeg accessors exist")

for (fn_name in bundle_fns) {
  result <- do.call(get(fn_name, envir = asNamespace("toad")), list())
  expect_true(
    fiber::is_bundle_set(result) && result@n_bundles == 2L,
    info = paste(fn_name, "returns a bundle_set of the mocked subjects")
  )
  expect_equal(
    result[[1L]],
    fake_bundle,
    info = paste(fn_name, "first element is the mocked bundle")
  )
}

assignInNamespace(".toad_download_file", orig_dl, ns = "toad")
assignInNamespace(".tractseg_subject_list", orig_tsl, ns = "toad")

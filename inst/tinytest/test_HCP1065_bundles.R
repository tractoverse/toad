library(toad)

# The HCP1065 convenience accessors each delegate to import_bundle() with the
# matching bundle name. Mock .toad_download_file so no network is required and
# verify every accessor returns the mocked bundle.
fake_bundle <- {
  sl <- fiber::streamline(points = cbind(X = 0:2, Y = 0:2, Z = 0:2))
  fiber::bundle(streamlines = list(sl), bundle_data = list(mock = TRUE))
}

orig_dl <- get(".toad_download_file", envir = asNamespace("toad"))
assignInNamespace(
  ".toad_download_file",
  function(url, destfile) saveRDS(fake_bundle, destfile),
  ns = "toad"
)

bundle_fns <- ls(asNamespace("toad"))
bundle_fns <- bundle_fns[grepl("^HCP1065_", bundle_fns)]
bundle_fns <- bundle_fns[vapply(
  bundle_fns,
  function(n) is.function(get(n, envir = asNamespace("toad"))),
  logical(1)
)]

expect_true(length(bundle_fns) == 87L, info = "87 HCP1065 accessors exist")

for (fn_name in bundle_fns) {
  expect_equal(
    do.call(get(fn_name, envir = asNamespace("toad")), list()),
    fake_bundle,
    info = paste(fn_name, "returns the mocked bundle object")
  )
}

assignInNamespace(".toad_download_file", orig_dl, ns = "toad")

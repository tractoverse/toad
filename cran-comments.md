## Submission

This is the initial submission of **toad 0.1.0** (Tractography Open Atlas Data)
to CRAN. The package previously lived under the name `mascot` and has been
renamed as part of the tractoverse family of packages.

This first release:

- Package code is licensed **MIT**; the underlying atlas data (HCP1065: CC
  BY-SA 4.0; TractSeg: CC BY-NC 4.0, non-commercial use only) are documented as
  such in `DESCRIPTION`, the README, and the man pages.
- Provides the `import_bundle()` API to fetch reference tractography atlas
  bundles on demand: the HCP1065 population-averaged atlas (87 bundles) and the
  per-subject TractSeg dataset (72 tracts in 105 HCP Young Adult subjects).
- No data files are bundled with the package; data are downloaded from GitHub
  releases on demand. The necessary network calls are exercised/excluded in
  accordance with the CRAN policy on internet access (examples are wrapped in
  `\dontrun{}`; tests use local fixtures through internal seams).

## Test environments

**Local:**
- macOS (arm64), R 4.6.2

**Continuous integration via GitHub Actions (`R-CMD-check.yaml`):**
- macOS latest, R release
- Windows latest, R release
- Ubuntu latest, R devel
- Ubuntu latest, R release
- Ubuntu latest, R oldrel-1

**R-Hub (35/36 platforms):**
- Checked on all available R-Hub platforms (35 platforms; `rchk` is
  excluded — see below). 34 platforms report `Status: OK` (0 errors |
  0 warnings | 0 notes) and the `vnu` platform (HTML validation) also
  passes.
- `rchk` is not part of the default matrix because the R-Hub check
  container fails on a known upstream flake (`bcheck output file does not
  exist`) before the as-cran check starts. See
  https://github.com/r-hub/actions for the same precedent used by other
  packages.

**Win-builder:**
- [win-builder](https://win-builder.r-project.org/) R release: 0 errors |
  0 warnings | 1 NOTE (new submission; possibly misspelled words in
  DESCRIPTION)
- [win-builder](https://win-builder.r-project.org/) R-devel: 0 errors |
  0 warnings | 1 NOTE (new submission; possibly misspelled words in
  DESCRIPTION)

## R CMD check results

0 errors | 0 warnings | 0 notes

Verified locally with `R CMD build` + `R CMD check --as-cran` on macOS
(arm64), R 4.6.2. The only NOTEs observed locally are environment-related
(pandoc not found — README/NEWS not re-checked; HTML Tidy not found — HTML
validation skipped).

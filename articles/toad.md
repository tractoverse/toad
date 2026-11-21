# Getting started with toad

## What toad does

[{toad}](https://tractoverse.github.io/toad/) (Tractography Open Atlas
Data) provides easy access to reference white matter tractography
atlases for benchmarking and anomaly-detection studies of brain
microstructure. It is the data layer of the
[{tractoverse}](https://github.com/tractoverse/tractoverse) package
family: bundles are returned as the S7 `streamline`, `bundle`, and
`bundle_set` classes of the
[{fiber}](https://tractoverse.github.io/fiber/) package, so they plug
directly into fiber’s shape-descriptor tools, riot’s file
readers/writers, and rtists’ visualisation.

Two atlases are available:

| Dataset | What it contains | License |
|----|----|----|
| `HCP1065` | Population-averaged atlas, 87 white matter bundles from 1,065 HCP subjects | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/) |
| `TractSeg` | Per-subject segmentations, 72 tracts in 105 HCP subjects | [CC BY-NC 4.0](https://creativecommons.org/licenses/by-nc/4.0/) — non-commercial |

The data are hosted as GitHub releases in the package repository and are
downloaded on demand as
[`fiber::bundle`](https://tractoverse.github.io/fiber/reference/bundle.html)
objects — no bulky data files are bundled with the package itself.

The central functions are:

- [`available_datasets()`](https://tractoverse.github.io/toad/reference/available_datasets.md)
  — the datasets a given `toad` version can access;
- [`available_bundles()`](https://tractoverse.github.io/toad/reference/available_bundles.md)
  — the bundles available within a dataset;
- [`import_bundle()`](https://tractoverse.github.io/toad/reference/import_bundle.md)
  — download a bundle (or several) as a `fiber` object.

## The two datasets

### HCP1065 population-averaged atlas

The HCP1065 atlas is a whole-brain population-averaged tractography
atlas derived from 1,065 healthy adults of the [Human Connectome
Project](https://www.humanconnectome.org/study/hcp-young-adult) Young
Adult dataset. It contains 87 white matter bundles, each stored as a
single population-level `bundle`.

The atlas is distributed under the [CC BY-SA
4.0](https://creativecommons.org/licenses/by-sa/4.0/) license. Please
cite the original work when using it:

> Yeh FC. Population-based tract-to-region connectome of the human brain
> and its hierarchical topology. *Nat Commun* **13**, 4933 (2022).
> https://doi.org/10.1038/s41467-022-32595-4

### TractSeg per-subject bundles

The TractSeg dataset provides per-subject white matter bundle
segmentations of 72 tracts in 105 HCP Young Adult subjects, generated
with [TractSeg](https://github.com/MIC-DKFZ/TractSeg) and redistributed
from the [Zenodo archive](https://zenodo.org/records/1477956) (DOI:
[10.5281/zenodo.1477956](https://doi.org/10.5281/zenodo.1477956)).
Because the segmentations are per-subject, this dataset supports
population-style analyses (e.g. bundle shape across subjects), not just
single population averages.

The data are distributed under the [CC BY-NC
4.0](https://creativecommons.org/licenses/by-nc/4.0/) license —
**non-commercial use only**. Please cite the original TractSeg
publication:

> Wasserthal J, Neher P, Maier-Hein KH. TractSeg — Fast and accurate
> white matter tract segmentation. *NeuroImage* **183**, 239–253 (2018).
> https://doi.org/10.1016/j.neuroimage.2018.07.070

Both datasets originate from the Human Connectome Project; users must
also comply with the [HCP data-use
terms](https://www.humanconnectome.org/study/hcp-young-adult/document/wu-minn-hcp-consortium-open-access-data-use-terms).

## Discovering datasets and bundles

[`available_datasets()`](https://tractoverse.github.io/toad/reference/available_datasets.md)
returns the names of the datasets `toad` can access:

``` r

available_datasets()
#> [1] "HCP1065"  "TractSeg"
```

[`available_bundles()`](https://tractoverse.github.io/toad/reference/available_bundles.md)
gives the full names of the bundles in a dataset — the values to pass to
the `bundle` argument of
[`import_bundle()`](https://tractoverse.github.io/toad/reference/import_bundle.md):

``` r

hcp_bundles <- available_bundles("HCP1065")
length(hcp_bundles)
#> [1] 87
head(hcp_bundles)
#> [1] "Anterior Commissure"            "Left Arcuate Fasciculus"       
#> [3] "Right Arcuate Fasciculus"       "Left Acoustic Radiation"       
#> [5] "Right Acoustic Radiation"       "Left Frontal Parietal Cingulum"
```

``` r

ts_bundles <- available_bundles("TractSeg")
length(ts_bundles)
#> [1] 72
head(ts_bundles)
#> [1] "Left Arcuate Fasciculus"           "Right Arcuate Fasciculus"         
#> [3] "Left Anterior Thalamic Radiation"  "Right Anterior Thalamic Radiation"
#> [5] "Commissure Anterior"               "Corpus Callosum"
```

## Importing bundles

`import_bundle(dataset, bundle, subjects = NULL)` downloads the
requested bundle from the GitHub release associated with the dataset and
returns it as a
[`fiber::bundle`](https://tractoverse.github.io/fiber/reference/bundle.html):

``` r

cst_left <- import_bundle("HCP1065", "Left Corticospinal Tract")
cst_left
```

Each bundle also ships a convenience accessor, so
`import_bundle("HCP1065", "Left Corticospinal Tract")` is equivalent to
[`HCP1065_CST_L()`](https://tractoverse.github.io/toad/reference/HCP1065_CST_L.md)

``` r

identical(cst_left, HCP1065_CST_L())
```

### Controlling subjects (TractSeg)

For multi-subject datasets, the `subjects` argument controls which
subjects are loaded. It takes four forms:

| `subjects` | Result |
|----|----|
| `NULL` (default) | All available subjects, as a `bundle_set` |
| an integer scalar `n` | `n` random subjects, as a `bundle_set` |
| a character vector | Those subject IDs, as a `bundle_set` |
| a character scalar | That single subject, returned directly as a `bundle` |

``` r

# A single subject — returns a bundle
af_left <- import_bundle(
  "TractSeg",
  "Left Arcuate Fasciculus",
  subjects = "599469"
)
af_left
```

``` r

# A random sample of 10 subjects — returns a bundle_set
af_sample <- import_bundle("TractSeg", "Left Arcuate Fasciculus", subjects = 10L)
af_sample
```

``` r

# Specific subjects by ID — returns a bundle_set
af_two <- import_bundle(
  "TractSeg",
  "Left Arcuate Fasciculus",
  subjects = c("599469", "613538")
)
af_two
```

The convenience accessors accept the same argument, e.g.
`TractSeg_AF_left(subjects = 10L)`.

## Bundle objects

Whatever the dataset,
[`import_bundle()`](https://tractoverse.github.io/toad/reference/import_bundle.md)
returns objects defined by the
[{fiber}](https://tractoverse.github.io/fiber/) package:

- a **streamline** holds one fibre tract: `@points` is an $`n \times 3`$
  numeric matrix with columns `X`, `Y`, `Z`; `@point_data` is a named
  list of per-point scalar attributes; `@streamline_data` is a named
  list of per-streamline scalars;
- a **bundle** is an ordered collection of `streamline`s in
  `@streamlines`, plus optional bundle-level metadata in `@bundle_data`;
- a **bundle_set** is a named collection of `bundle`s, with the input
  names preserved in `@bundle_data$id_from_input_names`.

For example, the metadata attached by `toad` to each imported bundle
tells you where it came from:

``` r

cst_left@bundle_data
```

Everything else — shape descriptors, reparametrisation, Hausdorff
distances — happens with the tools described in the [fiber
vignette](https://tractoverse.github.io/fiber/articles/fiber.html).

## Where to go next

- The [toad API
  vignette](https://tractoverse.github.io/toad/articles/toad-api.md)
  describes the package’s internal functions and the GitHub-releases
  data architecture in detail.
- The [{fiber}](https://tractoverse.github.io/fiber/) package provides
  the `streamline`, `bundle`, and `bundle_set` classes.
- The other tractoverse packages ({riot} for input/output, {rtists} for
  visualization, {bot} for optimal transport of bundles) build on the
  same data model.

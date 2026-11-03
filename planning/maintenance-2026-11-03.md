# Maintenance and user-supplied reference roadmap — 3 November 2026

This integration starts from published main `1828a36`, preserving the earlier
public core repairs. The separately qualified local scientific candidate and its
reference data remain archived outside this branch. Its data-containing history
is not merged. Existing published ancestry still contains the historical table;
this change removes it from the current tree and package without rewriting
published history. This adaptation did not edit the original checkouts or user data.

## Purpose and acceptance

Provide a reproducible research workflow for LIBS spectra, calibrated predictions,
exploratory classification, maps and exports. Every output must preserve sample,
wavelength, processing and model meaning. Synthetic examples establish software
behavior only; they do not qualify instruments, plasma assumptions or clinical use.

The user requested publication of the repaired software without restricted
reference data, with an exact self-download path. This source tree therefore
contains no atomic reference compilation or selected source-row extract. The
historical bundled table and hard-coded builder are removed. Local downloads are
ignored by Git and package builds; no download occurs on package load or lookup.

## Confirmed defects and completed scientific repairs

- Constructors/readers could lose rows, sample identities or channel alignment.
  Exact axis/metadata validation, faithful parsing and staged export now preserve
  source identities and reject malformed input.
- LOD calculation mixed concentration and response units; quantification lost
  internal-standard ratios and PLS features. Fitted extraction, wavelength and
  processing contracts now accompany model prediction. Undefined PLS limits are
  explicit rather than invented.
- PLS-DA reported training accuracy despite requested validation. CV/LOO now use
  held-out predictions and valid fold ranks; PLS scores, SVM probabilities, OOB
  and training metrics have distinct labels. Singleton/noise clustering measures
  and invalid inputs are handled explicitly.
- The former plasma calculation omitted required physical quantities. The
  two-stage Saha-Boltzmann calculation now requires atomic values, partition
  functions, density and instrument response, with an independent fictional
  forward fixture. No real atomic constants are invented for missing inputs.
- Tissue heuristics and fold changes depended on arbitrary signal scale or
  missing spectral coverage. Scale checks, local-window coverage and explicit
  unclassified results replace silent assumptions.
- Plots mixed prediction intervals with mean confidence bands and PLS fitted
  values with single-feature lines. The repaired plots retain the fitted model's
  actual response and evaluation basis.
- Explorer failures could leave stale results or partial exports. State
  invalidation, explicit evaluation labels, all-shot bundles and useful failure
  messages are retained in this integration.

The earlier local candidate's test/browser/archive evidence is historical. It
supports the carried source repairs but does not substitute for qualification of
this data-free candidate.

## User-supplied reference milestones

1. **Remove bundled reference data.** Exclude old and replacement tables, source
   extracts and legacy builders. Preserve them only in the prior local audit.
   Acceptance: inspect the exact final source archive and Git delta; no new
   data-containing ancestor or atomic data file enters publication.
2. **Explicit local reference contract.** `ls_element_db(path=...)` resolves an
   explicit file before `options(libscanR.element_db=...)`, then
   `LIBSCANR_ELEMENT_DB`. Validate numeric units, medium, source and missing
   values; retain supplied provenance. Missing/invalid configuration must fail
   usefully instead of silently loading a fictional reference.
3. **Installed local converter.** Convert a user-downloaded NIST CSV with nm/eV/
   Aki units and explicit medium; record input/output hashes and source URL/date.
   Refuse malformed input and overwriting existing files. No network requests,
   copied selections, inferred rates or persistent-line claims belong in the tool.
4. **Reference-free teaching and basic workflows.** Explicit `ls_demo_peaks()`
   uses a separate component/position/strength schema and fictional provenance.
   `ls_example_data()` always selects it deliberately. Real atomic simulation,
   identification and requested element overlays require configured data. Plain
   plots/statistical contrasts remain useful with unavailable annotations marked.
5. **Final validation and handover.** Run the full synthetic suite and isolated
   installed package checks, exercise a fresh external download/import locally,
   verify README examples, review package/site/manual and inspect outgoing source.
   Record actual counts/hashes and remaining platform/release gates before a
   normal pull-first main publication. No tag, CRAN/archival submission or manual
   deployment is part of this change.

## Final local evidence

- Exact final archive: `libscanR_0.1.0.9001.tar.gz`, SHA256
  `8c6c1dbac1bb5f4cce2ae66e05a4adda00e80bb3a77ada7531351a72c82daab6`
  (1,639,746 bytes). Independent inspection matches 192 source payloads plus
  standard DESCRIPTION build metadata. There are no atomic reference files,
  selected source rows, Git metadata, local downloads, symlinks, traversal paths,
  bytecode caches or plotting detritus. The only supplied scientific data are the
  explicitly fictional Saha CSV/JSON fixture. Preserved restricted-file hashes
  were checked against every archive payload.
- Full exact-archive `R CMD check --as-cran`: **0 errors, 0 warnings, 1 NOTE**;
  **821 passing assertions**, no test warnings or skips. The dependency-only
  check of the same tar has **0 errors, 0 warnings, 1 NOTE**, **582 passing
  assertions** and **43 explicit optional-package skips**: plotly (21), pls (18),
  e1071 (2), dbscan (1), ranger (1). Both NOTE texts are exactly “New submission”
  and “Version contains large components (0.1.0.9001)”; no URL or line-width NOTE
  remains. An earlier candidate's three overlong examples were wrapped and both
  checks repeated on this final tar.
- Coverage is **93.66053%**, measured on the same executable R code and byte-
  identical tests as the final archive. This change raises the published base's
  disabled (0%) coverage floor to 90%.
  House lint remains explicitly report-only: 226 findings (219 style, 7 warnings)
  include inherited vocabulary, output and condition conventions; no check was
  weakened or unexplained failure suppressed. Workflow syntax passes.
- **Six independent Python importer tests pass**, including actual Python 3.9.
  They cover units, unknown values, medium, estimated-energy syntax, truncated
  CSV quoting, source identity, hash receipts, overwrite preservation and failed
  receipt cleanup/retry. Root and runtime reviews independently reproduced three
  malformed-input/failure-path issues and verified the repairs.
- A fresh bounded NIST download outside this source tree returned seven rows.
  The installed converter and configured R reader preserved their medium and
  provenance; input/output hashes and the original download remain local only.
  A fresh required-dependency-only installation of the exact final archive passes
  **14 first-use checks**, covering teaching data, preprocessing/detection/plot,
  all-shot CSV and origin roundtrip, no-reference errors, calibration, the
  independent Saha fixture, and the installed converter/configuration path.
- Explorer qualification passes **114 focused assertions**, **14 initial real
  browser checks** and **6 final readback/layout checks**. Teaching origins are
  visible in the UI and detached peak/calibration CSVs; mixed inputs are labelled
  distinctly. Failed atomic annotation leaves raw detections and plots available.
  Three configured artificial-reference path checks also pass. The owned app
  server is closed.
- The final **55-page manual** has identical text, word geometry and all 557
  named destinations to the prior candidate reviewed visually on every page;
  zero words extend outside pages. New reference/example pages and the installed
  first-use plot received an additional independent visual check. The final
  first-use plot renders identically. No clipping or layout blocker remains.
- Final documentation generation completes with **86 HTML pages and 3,669 local
  references**, all targets/anchors present. The external-reference example is
  deliberately conditional and not executed without user data; pkgdown reports
  that false guard. Pandoc reports its own deprecated command-line option notices.
- Browser review found inherited scientific-image inversion and low-contrast code
  text. Scoped site CSS now preserves original plot colours on white and corrects
  the measured code-token categories; all 14 article figures have descriptive
  alternatives. All 43 article R chunks and original PNGs are unchanged. All
  **300 native pixel samples** match original PNG colours. Across the homepage
  and five articles, **1,421 code elements per theme** have minimum measured
  contrast **5.183:1 light / 5.327:1 dark**, with none below 4.5:1. Desktop/mobile
  navigation and the 390-pixel layout work without observed script errors.
  This is bounded verification, not whole-site accessibility certification.
- The site harness retains 24 passing checks and two initial failures. Code-text
  contrast was repaired and remeasured. A separate corrected-selector test
  confirms a shared first-focus search race when a query precedes the index:
  reentering after readiness returns 20 suggestions, and a clicked result opens
  the actual local API page. This common-script repair is deferred to the shared
  site audit. Existing white confusion-matrix labels on yellow maximum-count
  tiles also remain a contrast limitation; scientific images are unchanged.
  Canonical URLs were remapped only for local preview. The owned preview is
  closed, and no deployment is claimed.
- Final site CSS SHA256 is
  `1b9c3ca65e13f3f178168e73f431ece74e7b742c7edf4ad3dcdc591fd738cfcd`,
  identical in source and the reviewed generated asset. Only this excluded site
  asset changed after final archive generation; vignette, runtime and test bytes
  remain frozen.
- CFF 1.2.0 schema validation and metadata/version/author consistency pass. Zenodo
  metadata remain a draft; no API submission or acceptance is claimed. All sixteen
  carried scientific/core files retain identical executable syntax to the prior
  qualified local source; this adaptation does not undo those repairs.

## First use and remaining gates

The README provides exact R/Python prerequisites, installation, a reference-free
teaching workflow, and manual NIST download/settings plus the installed local
converter. Real identification and configured simulation require the user's own
reference; no atomic data or instrument qualification is silently supplied.

Local synthetic/software criteria above are satisfied, with the two site
limitations explicitly deferred. Hosted cross-platform results must be observed
against the eventual published commit; local checks do not establish those
results. A new CRAN/archival release, real-instrument validation, experimental plasma assumptions and clinical
performance remain outside this source-publication milestone. The final
independent site review is complete and the source is ready for the authorized
normal main publication. No release/tag, submission, manual deployment
or history rewrite is performed here.

Exact commands, hashes, successful results and superseded harness failures are
retained separately under `evidence/libscanR/user-reference`. Earlier data-bearing
local candidate receipts are historical and are not substituted for this final
archive's evidence. No restricted data-containing candidate history is merged.

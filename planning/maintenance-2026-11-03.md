# Maintenance audit and roadmap — 3 November 2026

Baseline: `338113cdba593a380028c6e431d1bf8cdf5934cb`, version 0.1.0.
The original clean checkout and its 222 tracked files are preserved. Work is on
an isolated branch; instrument data, reference-data provenance and historical
records must remain distinguishable from synthetic software verification.

## Purpose and acceptance criteria

Provide a dependable research workflow from LIBS spectra and sample metadata
through preprocessing, elemental analysis, calibrated prediction, exploratory
classification, mapping and export. Every exported value must retain its sample,
wavelength, processing and calibration meaning. An excellent implementation
reports the assumptions and validation basis of scientific estimates explicitly.
Synthetic demonstrations do not establish instrument, tissue or clinical validity.

## Evidence and priorities

Independent baseline probes confirm the following release blockers:

| Location | Evidence and user impact | Required repair |
| --- | --- | --- |
| `R/libs_spectrum-class.R` | Sorting wavelengths reorders intensities but leaves the baseline in its old order; duplicate/infinite axes are accepted. | Validate the spectrum contract and reorder all channel-aligned values together. |
| `R/libs_dataset-class.R` | Duplicate IDs are accepted; mismatched sample tables produce missing rows after only a warning. | Require unambiguous identities and exact matching, preserving supplied metadata order by identity. |
| `R/io-read.R`, `R/io-write.R` | The default writer's metadata comments make its own reader fail. | Verify exact multi-shot and metadata roundtrips, malformed input and vendor header boundaries. |
| `R/io-write.R` | Sample ID `../escaped` writes outside the export directory; `sample_info` overwrites its spectrum with metadata. | Validate every output name before writing and preserve existing destinations on failure. |
| `R/calibrate.R`, `R/quantify.R` | Tenfold instrument gain changes reported LOD tenfold although concentration predictions are identical; internal-standard fit predicts 5–25 but quantification returns 10–150. | Correct dimensions and retain the trained integration/standard/feature contract through prediction. |

Source inspection additionally identifies material scientific risks requiring
independent numerical reproduction before repair: PLS quantification supplies a
single peak instead of trained features; PLS-DA reports fitted predictions even
when cross-validation is requested; model scores are labeled probabilities;
classifier prediction does not check wavelength identity; singleton silhouette
values are inflated; and the nominal Saha-Boltzmann implementation does not use
electron density or species partition/statistical-weight information. Atomic
reference attribution and the reported physical meaning require verification
against primary sources. These are not validated concentration or tissue claims.

## Implementation milestones

1. **Essential file and sample integrity.** Repair constructors, readers,
   transformations and exports with independent ordering, identity, numerical
   and failure-preservation tests. Completion: valid ordinary workflows remain
   usable, invalid inputs fail explicitly, and no export escapes its destination.
2. **Scientific calibration and evaluation.** Preserve fit/predict feature
   contracts, correct units and validation predictions, and distinguish model
   scores, training performance and held-out estimates. Verify physical formulas
   and reference provenance; require missing scientific inputs explicitly rather
   than silently inventing constants. Completion: analytical or independent
   library oracles, scale invariance and fresh-data prediction checks pass, with
   assumptions and migration paths documented.
3. **Dependable everyday explorer.** Trace import, preprocessing, selection,
   analysis and download across actual UI state. Correct stale results, misleading
   labels and option/resource leaks. Completion: installed-app browser journeys,
   failures and export readbacks agree with the corresponding R workflow.
4. **Release preparation.** Align README, examples, citation/version, scientific
   scope and distribution claims; validate clean installation, full/minimal source
   checks, configured lint/coverage, website/manual, archive contents and independent
   review. Completion requires observed evidence; hosted CI and real instruments
   remain separately identified gates. Normal main publication is authorized.

New algorithm families, broad rewrites, instrument qualification studies and
clinical thresholds remain outside this maintenance release. Compatibility changes
must fix demonstrated unsafe or scientifically incorrect behavior, with explicit
migration instructions; checks will not be weakened to make the candidate pass.

## Baseline and current status

- Initial direct suite: 311 passing assertions, no failures/errors, two unhandled
  overwrite warnings and ten optional-PLS skips.
- Initial full package check: one error for missing optional packages, zero
  warnings and one incoming note. Installing the declared optional dependencies
  into an isolated evidence library is an environment repair, not a source fix.
- Latest observed hosted baseline: R check, lint, coverage and website workflows
  succeeded at the baseline SHA. No public release or open issue was observed.
- Implementation and final qualification are pending. Exact probes and executed
  logs are retained under the sibling audit evidence directory.

### File and sample integrity milestone

The optional dependencies were installed into the isolated evidence library.
The complete baseline then had 335 passing assertions, two export warnings and
no skips; the full source check had zero errors/warnings and four notes.

The first implementation milestone now has 431 passing assertions, zero
failures/errors/warnings/skips. A subsequent focused import/export run passed
71 assertions, including five new checks for named sample lists, processing
history roundtrips, source provenance and malformed rectangular input.

Repairs include aligned baseline sorting; finite axes and intensities; exact
sample/wavelength identity; stale-cache rejection; corrected integer subsetting;
shot-weighted combined baselines and source metadata; default CSV roundtrips;
first-row preservation in vendor/headerless imports; and staged exports with
portable filename checks and ordinary-failure rollback. All write-failure tests
use disposable fixtures; existing output hashes remain unchanged.

Numerical regressions cover simultaneous SNIP clipping (direction invariance),
Savitzky-Golay constant/polynomial preservation and agreement with `signal`,
sparse ALS agreement with a separate dense normal-equation solution, zero-divisor
handling, baseline provenance after normalization, constant replicate averaging,
normalized plot annotations, seeded example reproducibility and duplicate map
coordinates. A default 2,048-channel, ten-shot ALS example completed in 0.349
seconds locally. This is a bounded timing observation, not a scalability claim.

The numerical references consulted were the original
[Savitzky-Golay paper](https://doi.org/10.1021/ac60214a047),
[Morhac's ROOT implementation](https://root.cern.ch/doc/master/TSpectrum_8cxx_source.html),
and [Eilers' asymmetric smoothing documentation](https://search.r-project.org/CRAN/refmans/ptw/html/asysm.html).
No source data or atomic reference values have been changed.

Compatibility: incomplete/duplicate sample tables and mismatched axes now fail
instead of silently changing labels. Zero normalization divisors fail. Export
skips the entire bundle if any destination exists and overwrite is false; it
never updates metadata alone. CSV metadata use JSON values; named vectors are
represented as objects/lists, and R-specific attributes are not preserved.
Out-of-range peak centers and duplicate map positions are errors. The existing
coarse-channel integration expansion is now documented explicitly. These
changes require deliberate data alignment and adequate spectral resolution.
Scientific calibration, explorer journeys and final release qualification are
still pending; this checkpoint is not a release-readiness claim.


The follow-up review requires exact structural and metadata field names and
rejects non-converged Gaussian fits. A synthetic doublet previously returned an
area from a fit that exceeded its iteration limit; it now reports a named warning
and returns the measured trapezoidal result. Positive Gaussian and failure-path
regressions cover the change. These code-only repairs do not update atomic data;
the scientific/reference and explorer milestones remain under local qualification.

The isolated code-only candidate passes the complete direct suite: 446 assertions,
zero failures, errors, warnings or skips. Independent diff review found no material
issue in the exact-name and Gaussian-fit follow-up, and confirmed that no atomic
data files changed. The source-package check also identified two unqualified
`utils` calls; both now use explicit namespaces. Final source-package evidence
and the remote main receipt are retained in the maintenance audit directory.

The earlier DOI badge and release date were not confirmed: the DOI resolver and
CRAN package page returned HTTP404, while the Zenodo API returned403 (reservation
status unknown). Remove those unsupported release signals, retain the identifier
in draft archival notes and leave publication verification pending. No release
or submission is implied by this source-code milestone.

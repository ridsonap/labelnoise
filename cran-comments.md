## Submission

This is the first submission of labelnoise.

## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new release.

## Test environments

* local macOS (aarch64), R 4.6.1

## Method references

The methods are described in

* Northcutt, Jiang and Chuang (2021) <doi:10.1613/jair.1.12125>, and
* Kuan and Mueller (2022) <doi:10.5281/zenodo.18168246>,

both cited in the Description field.

## Notes for reviewers

* Tests that fit models with the suggested packages 'tune', 'mlr3' and
  'caret' are skipped on CRAN with `skip_on_cran()`; they run on continuous
  integration.
* The CSV files in `tests/testthat/fixtures/` are numerical reference
  outputs (simulated data and results) produced with the Python package
  'cleanlab'. They contain no third-party code.

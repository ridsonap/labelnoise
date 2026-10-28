# The confident joint

`confident_joint()` counts, for every pair of given label `i` and
(estimated) true label `j`, the examples labelled `i` that are confident
members of class `j` (Northcutt et al., 2021, Eq. 1 and Algorithm 1). An
example is a confident member of class `j` when its predicted
probability for `j` is at least the threshold of `j` (see
[`class_thresholds()`](https://ridsonap.is-a.dev/labelnoise/reference/class_thresholds.md)).
When it is a confident member of several classes, the one with the
largest predicted probability among them is used. Examples that are
confident members of no class are not counted.

With `calibrate = TRUE`, each row is rescaled so that it sums to the
number of examples with that given label (the numerator of Eq. 3). Rows
with no confident examples are treated as noise free.

Off-diagonal cells are label errors: examples given label `i` that look
like they belong to class `j`.

## Usage

``` r
confident_joint(x, ..., calibrate = TRUE)
```

## Arguments

- x:

  Labels or an object holding labels and predicted probabilities. See
  Description.

- ...:

  Passed to
  [`label_inputs()`](https://ridsonap.is-a.dev/labelnoise/reference/label_inputs.md):
  for example `pred_probs` when `x` is a label vector, or `truth` when
  `x` is a data frame.

- calibrate:

  Rescale rows to the observed class counts?

## Value

A square matrix with dimension names `given` (rows) and `true`
(columns). Integer counts when `calibrate = FALSE`; real-valued
calibrated counts otherwise.

## References

Northcutt, C., Jiang, L., & Chuang, I. (2021). Confident learning:
Estimating uncertainty in dataset labels. *Journal of Artificial
Intelligence Research*, 70, 1373–1411.
[doi:10.1613/jair.1.12125](https://doi.org/10.1613/jair.1.12125)

## See also

[`estimate_joint()`](https://ridsonap.is-a.dev/labelnoise/reference/estimate_joint.md),
[`noise_matrices()`](https://ridsonap.is-a.dev/labelnoise/reference/noise_matrices.md),
[`num_label_issues()`](https://ridsonap.is-a.dev/labelnoise/reference/num_label_issues.md)

## Examples

``` r
sim <- simulate_label_noise(n = 500, seed = 1)
confident_joint(sim, truth = given, calibrate = FALSE)
#>      true
#> given   A  B  C  D
#>     A 106  5  4  7
#>     B   9 77  6  3
#>     C   5  5 58  3
#>     D   4  7  3 32
confident_joint(sim, truth = given)
#>      true
#> given          A          B         C         D
#>     A 170.295082   8.032787  6.426230 11.245902
#>     B  13.547368 115.905263  9.031579  4.515789
#>     C   7.112676   7.112676 82.507042  4.267606
#>     D   5.217391   9.130435  3.913043 41.739130
```

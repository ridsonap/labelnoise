# Estimate the number of label errors

Two estimators are available:

- `"confident_joint"` (default) counts the examples in the off-diagonal
  cells of the uncalibrated confident joint, that is examples that are
  confident members of a class other than their given label, leaving out
  those whose most likely class is still their given label. This matches
  [`find_label_issues()`](https://ridsonap.is-a.dev/labelnoise/reference/find_label_issues.md)
  with `filter_by = "confident_learning"`.

- `"calibrated"` multiplies the off-diagonal mass of the estimated joint
  by the number of examples (Northcutt et al., 2021, Sec. 3.2).
  Calibration assumes that examples not counted in the confident joint
  are mislabelled at the same rate as those counted.

## Usage

``` r
num_label_issues(x, ..., method = c("confident_joint", "calibrated"))
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

- method:

  Estimator, see Description.

## Value

A single integer.

## References

Northcutt, C., Jiang, L., & Chuang, I. (2021). Confident learning:
Estimating uncertainty in dataset labels. *Journal of Artificial
Intelligence Research*, 70, 1373–1411.
[doi:10.1613/jair.1.12125](https://doi.org/10.1613/jair.1.12125)

## Examples

``` r
sim <- simulate_label_noise(n = 500, noise_rate = 0.2, seed = 1)
num_label_issues(sim, truth = given)
#> [1] 110
sum(sim$given != sim$true)
#> [1] 101
```

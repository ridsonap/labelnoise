# Estimate the joint distribution of given and true labels

Normalises the calibrated confident joint so that it sums to one
(Northcutt et al., 2021, Eq. 3 and Algorithm 2). Entry `[i, j]`
estimates the proportion of examples that have given label `i` and true
label `j`.

## Usage

``` r
estimate_joint(x, ...)
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

## Value

A square matrix with dimension names `given` and `true` that sums to
one. Its row sums equal the observed class proportions.

## References

Northcutt, C., Jiang, L., & Chuang, I. (2021). Confident learning:
Estimating uncertainty in dataset labels. *Journal of Artificial
Intelligence Research*, 70, 1373–1411.
[doi:10.1613/jair.1.12125](https://doi.org/10.1613/jair.1.12125)

## Examples

``` r
sim <- simulate_label_noise(n = 500, seed = 1)
round(estimate_joint(sim, truth = given), 3)
#>      true
#> given     A     B     C     D
#>     A 0.341 0.016 0.013 0.022
#>     B 0.027 0.232 0.018 0.009
#>     C 0.014 0.014 0.165 0.009
#>     D 0.010 0.018 0.008 0.083
```

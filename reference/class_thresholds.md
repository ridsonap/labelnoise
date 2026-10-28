# Per-class confidence thresholds

The threshold of class `j` is the mean predicted probability of class
`j` among examples whose given label is `j` (Northcutt et al., 2021, Eq.
2). An example is a confident member of class `j` when its predicted
probability for `j` reaches this threshold.

## Usage

``` r
class_thresholds(x, ...)
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

A named numeric vector with one threshold per class. Classes without any
given label get `Inf`, so no example is counted as a confident member of
them.

## References

Northcutt, C., Jiang, L., & Chuang, I. (2021). Confident learning:
Estimating uncertainty in dataset labels. *Journal of Artificial
Intelligence Research*, 70, 1373–1411.
[doi:10.1613/jair.1.12125](https://doi.org/10.1613/jair.1.12125)

## Examples

``` r
sim <- simulate_label_noise(n = 200, seed = 1)
class_thresholds(sim, truth = given)
#>         A         B         C         D 
#> 0.6617105 0.6006520 0.5993731 0.5576538 
```

# Noise transition matrices and class priors

Derives from the estimated joint (see
[`estimate_joint()`](https://ridsonap.github.io/labelnoise/reference/estimate_joint.md))
the quantities used to characterise label noise (Northcutt et al., 2021,
Sec. 3.1). Both matrices are oriented with given labels in rows and true
labels in columns.

## Usage

``` r
noise_matrices(x, ...)
```

## Arguments

- x:

  Labels or an object holding labels and predicted probabilities. See
  Description.

- ...:

  Passed to
  [`label_inputs()`](https://ridsonap.github.io/labelnoise/reference/label_inputs.md):
  for example `pred_probs` when `x` is a label vector, or `truth` when
  `x` is a data frame.

## Value

A list with

- `joint`: the estimated joint distribution `P(given = i, true = j)`.

- `prior_given`: observed class proportions `P(given = i)`.

- `prior_true`: estimated true class proportions `P(true = j)`.

- `noise_matrix`: `P(given = i | true = j)`; columns sum to one. The
  diagonal is the probability that an example of class `j` keeps its
  label.

- `inverse_noise_matrix`: `P(true = j | given = i)`; rows sum to one.
  The diagonal is the probability that a label `i` is correct.

A class with an estimated true prior of zero has `NA` in its column of
`noise_matrix`.

## References

Northcutt, C., Jiang, L., & Chuang, I. (2021). Confident learning:
Estimating uncertainty in dataset labels. *Journal of Artificial
Intelligence Research*, 70, 1373–1411.
[doi:10.1613/jair.1.12125](https://doi.org/10.1613/jair.1.12125)

## Examples

``` r
sim <- simulate_label_noise(n = 500, seed = 1)
nm <- noise_matrices(sim, truth = given)
round(nm$inverse_noise_matrix, 2)
#>      true
#> given    A    B    C    D
#>     A 0.87 0.04 0.03 0.06
#>     B 0.09 0.81 0.06 0.03
#>     C 0.07 0.07 0.82 0.04
#>     D 0.09 0.15 0.07 0.70
```

# Summarise label health by class

Gives a dataset-level and class-level overview of label quality from the
estimated joint distribution of given and true labels (see
[`noise_matrices()`](https://ridsonap.is-a.dev/labelnoise/reference/noise_matrices.md)):

- an overall label health score, one minus the estimated share of
  mislabelled examples;

- for every class, the estimated number and share of mislabelled
  examples, and the noise rates;

- the pairs of classes that are most often confused with each other,
  which point to unclear class definitions or coding guidelines.

## Usage

``` r
health_summary(x, ..., method = c("confident_joint", "calibrated"))
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

  Estimator of the number of label errors, see
  [`num_label_issues()`](https://ridsonap.is-a.dev/labelnoise/reference/num_label_issues.md).

## Value

An object of class `label_health`, a list with

- `score`: the overall label health score;

- `n`, `num_label_issues`: the number of examples and the estimated
  number of mislabelled examples;

- `classes`: a tibble with one row per class, sorted from worst to best
  `label_quality`. `label_noise` is the estimated share of examples
  truly in the class that were given another label;
  `inverse_label_noise` the estimated share of examples given the label
  that truly belong to another class; `label_quality` is
  `1 - inverse_label_noise`.

- `overlapping_classes`: a tibble of class pairs with the estimated
  number of examples confused in either direction, sorted from most to
  least confused. Pairs that are never confused are left out.

## References

Northcutt, C., Jiang, L., & Chuang, I. (2021). Confident learning:
Estimating uncertainty in dataset labels. *Journal of Artificial
Intelligence Research*, 70, 1373–1411.
[doi:10.1613/jair.1.12125](https://doi.org/10.1613/jair.1.12125)

## Examples

``` r
sim <- simulate_label_noise(n = 1000, noise_rate = 0.15, seed = 1)
health <- health_summary(sim, truth = given)
health
#> Label health
#> • Overall score: 0.808
#> • Estimated label issues: 192 of 1000 examples
#> 
#> Classes with the lowest label quality:
#> # A tibble: 4 × 7
#>   class     n num_label_issues label_issue_rate label_noise inverse_label_noise
#>   <fct> <int>            <int>            <dbl>       <dbl>               <dbl>
#> 1 D       147               45            0.306       0.525               0.388
#> 2 C       202               45            0.223       0.270               0.301
#> 3 B       281               51            0.181       0.253               0.257
#> 4 A       370               51            0.138       0.145               0.220
#> # ℹ 1 more variable: label_quality <dbl>
#> 
#> Most confused class pairs:
#> # A tibble: 5 × 4
#>   class_1 class_2 num_overlapping joint_probability
#>   <fct>   <fct>             <int>             <dbl>
#> 1 B       D                    71            0.0710
#> 2 A       D                    52            0.0518
#> 3 A       C                    43            0.0430
#> 4 B       C                    36            0.0364
#> 5 A       B                    36            0.0358
health$classes
#> # A tibble: 4 × 7
#>   class     n num_label_issues label_issue_rate label_noise inverse_label_noise
#>   <fct> <int>            <int>            <dbl>       <dbl>               <dbl>
#> 1 D       147               45            0.306       0.525               0.388
#> 2 C       202               45            0.223       0.270               0.301
#> 3 B       281               51            0.181       0.253               0.257
#> 4 A       370               51            0.138       0.145               0.220
#> # ℹ 1 more variable: label_quality <dbl>
```

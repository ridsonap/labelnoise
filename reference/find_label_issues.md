# Find examples with likely label errors

Flags examples whose given label is likely wrong, using one of the rank
and prune rules of confident learning (Northcutt et al., 2021, Sec.
3.2). Every rule needs out-of-sample predicted probabilities, for
example from cross-validation.

- `"prune_by_noise_rate"` (default): for every pair of given label `i`
  and true label `j`, the estimated number of examples in that cell of
  the joint (see
  [`estimate_joint()`](https://ridsonap.is-a.dev/labelnoise/reference/estimate_joint.md))
  is flagged among the examples labelled `i`, choosing those where
  `p[j] - p[i]` is largest.

- `"prune_by_class"`: for every given label `i`, the estimated number of
  mislabelled examples is flagged among the examples labelled `i`,
  choosing those with the lowest self-confidence `p[i]`.

- `"both"`: examples flagged by both rules above.

- `"confident_learning"`: examples in the off-diagonal cells of the
  confident joint (see
  [`confident_joint()`](https://ridsonap.is-a.dev/labelnoise/reference/confident_joint.md)).

- `"predicted_neq_given"`: examples whose most likely class differs from
  the given label. A simple baseline that ignores class imbalance.

As in the cleanlab Python package, an example whose most likely class is
its given label is never flagged, whichever rule is used: the classifier
then offers no evidence against the label.

Flagged examples are candidates for review, not proven errors: ambiguous
examples that genuinely fit several classes are flagged too.

## Usage

``` r
find_label_issues(
  x,
  ...,
  filter_by = c("prune_by_noise_rate", "prune_by_class", "both", "confident_learning",
    "predicted_neq_given"),
  rank_by = c("self_confidence", "normalized_margin", "confidence_weighted_entropy"),
  frac_noise = 1,
  min_examples_per_class = 1
)
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

- filter_by:

  Rule used to flag examples, see Description.

- rank_by:

  Label quality score reported in `label_quality`, see
  [`label_quality_scores()`](https://ridsonap.is-a.dev/labelnoise/reference/label_quality_scores.md).
  Sort by it to review the most suspicious examples first.

- frac_noise:

  Fraction of the estimated number of label errors to flag, between 0
  and 1. Only used by the `"prune_by_*"` and `"both"` rules. Lower
  values flag fewer, more certain examples.

- min_examples_per_class:

  The rules never flag so many examples of a given label that fewer than
  this number would remain unflagged.

## Value

A [tibble](https://tibble.tidyverse.org/reference/tibble.html) with one
row per example, in the order of the input, and columns

- `.row`: the row identifier (the `.row` of resampled predictions, or
  the position in the input);

- `given`: the given label;

- `predicted`: the class with the largest predicted probability;

- `label_quality`: the label quality score chosen by `rank_by`;

- `is_label_issue`: whether the example is flagged.

## References

Northcutt, C., Jiang, L., & Chuang, I. (2021). Confident learning:
Estimating uncertainty in dataset labels. *Journal of Artificial
Intelligence Research*, 70, 1373–1411.
[doi:10.1613/jair.1.12125](https://doi.org/10.1613/jair.1.12125)

## See also

[`health_summary()`](https://ridsonap.is-a.dev/labelnoise/reference/health_summary.md)
for a class-level overview.

## Examples

``` r
sim <- simulate_label_noise(n = 500, noise_rate = 0.1, seed = 1)
issues <- find_label_issues(sim, truth = given)
issues
#> # A tibble: 500 × 5
#>     .row given predicted label_quality is_label_issue
#>    <int> <fct> <fct>             <dbl> <lgl>         
#>  1     1 A     A                 0.722 FALSE         
#>  2     2 A     C                 0.188 FALSE         
#>  3     3 B     B                 0.432 FALSE         
#>  4     4 D     D                 0.690 FALSE         
#>  5     5 A     C                 0.223 TRUE          
#>  6     6 C     C                 0.516 FALSE         
#>  7     7 D     D                 0.483 FALSE         
#>  8     8 B     B                 0.834 FALSE         
#>  9     9 B     B                 0.637 FALSE         
#> 10    10 A     A                 0.484 FALSE         
#> # ℹ 490 more rows

# Review the most suspicious examples first
flagged <- issues[issues$is_label_issue, ]
head(flagged[order(flagged$label_quality), ])
#> # A tibble: 6 × 5
#>    .row given predicted label_quality is_label_issue
#>   <int> <fct> <fct>             <dbl> <lgl>         
#> 1   424 B     A               0.00428 TRUE          
#> 2   234 A     D               0.00632 TRUE          
#> 3   370 C     B               0.00650 TRUE          
#> 4   392 B     A               0.00956 TRUE          
#> 5   376 C     B               0.0105  TRUE          
#> 6    53 A     B               0.0121  TRUE          

# How well did it do on this simulation?
table(flagged = issues$is_label_issue, mislabelled = sim$given != sim$true)
#>        mislabelled
#> flagged FALSE TRUE
#>   FALSE   408   11
#>   TRUE     34   47
```

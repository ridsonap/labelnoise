# Label quality scores

Scores how likely each given label is to be correct, from 0 (probably
wrong) to 1 (probably right). Scores depend only on the predicted
probabilities `p` of an example and its given label `y` (Kuan and
Mueller, 2022):

- `"self_confidence"`: `p[y]`, the predicted probability of the given
  label.

- `"normalized_margin"`: `(p[y] - max(p[-y]) + 1) / 2`, the gap between
  the given label and the most likely other class, rescaled to `[0, 1]`.
  Low when another class is clearly preferred.

- `"confidence_weighted_entropy"`: `ratio / (1 + ratio)` with
  `ratio = p[y] / H(p)`, where `H` is the entropy of `p` divided by
  `log(K)`. Also low for examples whose predictions are spread over many
  classes, such as examples that belong to none of the classes.

With `adjust = TRUE`, each class threshold `t` (see
[`class_thresholds()`](https://ridsonap.is-a.dev/labelnoise/reference/class_thresholds.md))
is subtracted from the predicted probabilities before scoring. This
corrects for a classifier that systematically favours some classes. The
adjusted probabilities are `(p - t + max(t)) / sum(p - t + max(t))`,
which are non-negative and sum to one.

## Usage

``` r
label_quality_scores(
  x,
  ...,
  method = c("self_confidence", "normalized_margin", "confidence_weighted_entropy"),
  adjust = FALSE
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

- method:

  Scoring method, see Description.

- adjust:

  Adjust predicted probabilities by the class thresholds before scoring?
  Not available for `"confidence_weighted_entropy"`.

## Value

A numeric vector with one score per example, in the order of
`label_inputs(x, ...)$row_id`.

## References

Kuan, J., & Mueller, J. (2022). Model-agnostic label quality scoring to
detect real-world label errors. *ICML DataPerf Workshop*.
[doi:10.5281/zenodo.18168246](https://doi.org/10.5281/zenodo.18168246)

## Examples

``` r
sim <- simulate_label_noise(n = 300, seed = 1)
scores <- label_quality_scores(sim, truth = given)
# Mislabelled examples get lower scores
tapply(scores, sim$given != sim$true, mean)
#>     FALSE      TRUE 
#> 0.6094508 0.1968347 
```

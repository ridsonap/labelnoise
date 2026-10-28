# Standardise labels and predicted probabilities

`label_inputs()` converts the many ways of supplying given labels and
out-of-sample predicted probabilities into one validated object. Every
other function in labelnoise calls it, so anything accepted here is
accepted everywhere:

- a label vector (factor, character or integer) plus a probability
  matrix or data frame in `pred_probs`;

- a data frame of predictions in the yardstick convention: a `truth`
  column and one `.pred_<level>` column per class (as returned by
  [`tune::collect_predictions()`](https://tune.tidymodels.org/reference/collect_predictions.html)
  or `augment()`);

- a `tune_results` object from
  [`tune::fit_resamples()`](https://tune.tidymodels.org/reference/fit_resamples.html)
  or
  [`tune::tune_grid()`](https://tune.tidymodels.org/reference/tune_grid.html)
  fitted with `control_resamples(save_pred = TRUE)`;

- an mlr3 `PredictionClassif` or `ResampleResult` with
  `predict_type = "prob"`;

- a caret `train` object fitted with `classProbs = TRUE` and
  `savePredictions = "final"` (or `"all"`).

Predicted probabilities must be out-of-sample (for example from
cross-validation). In-sample probabilities from a model that has seen
the labels will hide most label errors.

When an example has several out-of-sample predictions (repeated
cross-validation), its probabilities are averaged.

Other packages can add methods for their own prediction objects. A
method should end by calling `label_inputs()` on a label vector and a
probability matrix.

## Usage

``` r
label_inputs(x, ...)

# S3 method for class 'labelnoise_inputs'
label_inputs(x, ...)

# Default S3 method
label_inputs(x, pred_probs, ..., row_id = NULL)

# S3 method for class 'data.frame'
label_inputs(x, truth, ..., pred_probs = NULL)

# S3 method for class 'tune_results'
label_inputs(x, ..., parameters = NULL)

# S3 method for class 'PredictionClassif'
label_inputs(x, ...)

# S3 method for class 'ResampleResult'
label_inputs(x, ...)

# S3 method for class 'train'
label_inputs(x, ...)
```

## Arguments

- x:

  Labels or an object holding labels and predicted probabilities. See
  Description.

- ...:

  Passed on to methods. For data frames, a tidyselect specification of
  the probability columns.

- pred_probs:

  A numeric matrix or data frame with one row per example and one column
  per class. Rows must sum to one. Columns are matched to labels by name
  when both have names, otherwise by position.

- row_id:

  Integer identifiers returned in the `.row` column of
  [`find_label_issues()`](https://ridsonap.github.io/labelnoise/reference/find_label_issues.md).
  Defaults to `seq_along(x)`.

- truth:

  For data frames, the column holding the given labels.

- parameters:

  For `tune_results` with several candidate models, a one-row data frame
  of tuning parameters, such as the output of
  [`tune::select_best()`](https://tune.tidymodels.org/reference/show_best.html).

## Value

An object of class `labelnoise_inputs`: a list with `labels` (factor),
`pred_probs` (numeric matrix with one column per level of `labels`) and
`row_id` (integer).

## Examples

``` r
labels <- factor(c("a", "b", "b", "a"))
probs <- matrix(
  c(0.9, 0.1,
    0.2, 0.8,
    0.7, 0.3,
    0.6, 0.4),
  ncol = 2, byrow = TRUE, dimnames = list(NULL, c("a", "b"))
)
label_inputs(labels, probs)
#> <labelnoise_inputs>: 4 examples, 2 classes

# The yardstick convention
preds <- data.frame(class = labels, .pred_a = probs[, 1], .pred_b = probs[, 2])
label_inputs(preds, truth = class)
#> <labelnoise_inputs>: 4 examples, 2 classes
```

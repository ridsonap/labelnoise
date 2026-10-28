# labelnoise

labelnoise finds examples in classification data whose given label is
probably wrong. It works with any classifier: all it needs are the labels
and out-of-sample predicted probabilities, for example from
cross-validation.

It implements *confident learning* (Northcutt, Jiang and Chuang, 2021):

- per-class confidence thresholds and the **confident joint** of given and
  true labels;
- calibrated estimates of the **joint distribution** and the **noise
  transition matrices**;
- the five **rank-and-prune rules** for flagging label issues;
- model-agnostic **label quality scores** (Kuan and Mueller, 2022);
- a class-level **health summary** that shows which classes are most often
  confused.

## Installation

Install the released version from CRAN:

``` r
install.packages("labelnoise")
```

Or the development version from GitHub:

``` r
# install.packages("remotes")
remotes::install_github("ridsonap/labelnoise")
```

## Example

``` r
library(labelnoise)

# Simulated data with known errors, in the yardstick convention
sim <- simulate_label_noise(n = 1000, noise_rate = 0.1, signal = 3, seed = 1)

issues <- find_label_issues(sim, truth = given)
flagged <- issues[issues$is_label_issue, ]
head(flagged[order(flagged$label_quality), ])

health_summary(sim, truth = given)
```

## Works with your modelling framework

Every function accepts the same inputs:

| Input | Example |
|----|----|
| Labels and a probability matrix | `find_label_issues(labels, pred_probs = probs)` |
| Data frame of predictions (`.pred_*` columns) | `find_label_issues(preds, truth = class)` |
| tidymodels resampling results | `find_label_issues(fit_resamples(..., control = control_resamples(save_pred = TRUE)))` |
| mlr3 | `find_label_issues(resample(task, lrn("classif.rpart", predict_type = "prob"), rsmp("cv")))` |
| caret | `find_label_issues(train(..., trControl = trainControl(classProbs = TRUE, savePredictions = "final")))` |

Results come back as a tibble with one row per example, in the original row
order, so they can be joined back to the data for review.

## Caveats

- Probabilities must be out-of-sample; in-sample predictions hide errors.
- Results are only as good as the classifier. With a weak model, correct
  labels get flagged and the number of errors is overestimated.
- A flag is a reason to look, not a verdict.

## Relation to cleanlab

labelnoise is an independent implementation in R from the published
papers, not a port of the Python package
[cleanlab](https://github.com/cleanlab/cleanlab). Its tests compare results
with cleanlab 2.9.0, run as a black box on simulated data: the confident
joint, all five filtering rules, the estimated number of issues and the
self-confidence and normalised-margin scores agree exactly.

## References

Northcutt, C., Jiang, L., & Chuang, I. (2021). Confident learning:
Estimating uncertainty in dataset labels. *Journal of Artificial
Intelligence Research*, 70, 1373–1411.
<https://doi.org/10.1613/jair.1.12125>

Kuan, J., & Mueller, J. (2022). Model-agnostic label quality scoring to
detect real-world label errors. *ICML DataPerf Workshop*.
<https://doi.org/10.5281/zenodo.18168246>

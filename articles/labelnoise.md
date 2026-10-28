# Finding label errors with labelnoise

Labels in real data are often wrong: a coder picks the neighbouring
category, a respondent’s answer is ambiguous, a form is keyed in badly.
Wrong labels in training data cost accuracy; wrong labels in test data
make the reported accuracy meaningless.

labelnoise finds examples whose given label is probably wrong. It needs
only two things:

1.  the given labels, and
2.  **out-of-sample** predicted class probabilities from any classifier,
    for example from cross-validation.

It then applies *confident learning* (Northcutt, Jiang and Chuang,
2021): per-class confidence thresholds decide which examples confidently
belong to another class than their label, and the counts are used to
estimate how many labels are wrong and which ones.

``` r

library(labelnoise)
```

## A first look with simulated data

[`simulate_label_noise()`](https://ridsonap.is-a.dev/labelnoise/reference/simulate_label_noise.md)
creates a dataset where we know which labels are wrong. It returns
predictions in the yardstick convention: a label column and one
`.pred_<class>` column per class.

``` r

sim <- simulate_label_noise(n = 1000, noise_rate = 0.1, signal = 3, seed = 1)
sim
#> # A tibble: 1,000 × 6
#>    true  given .pred_A .pred_B .pred_C .pred_D
#>    <fct> <fct>   <dbl>   <dbl>   <dbl>   <dbl>
#>  1 A     A     0.813    0.116  0.0338  0.0381 
#>  2 A     A     0.924    0.0235 0.0146  0.0376 
#>  3 B     B     0.0300   0.876  0.0180  0.0759 
#>  4 D     D     0.00662  0.0108 0.0194  0.963  
#>  5 A     A     0.713    0.142  0.0844  0.0603 
#>  6 C     B     0.0186   0.0481 0.929   0.00397
#>  7 D     D     0.0132   0.0263 0.00723 0.953  
#>  8 B     B     0.159    0.762  0.00888 0.0701 
#>  9 B     B     0.0161   0.928  0.0251  0.0312 
#> 10 A     A     0.846    0.0200 0.0186  0.115  
#> # ℹ 990 more rows
```

[`find_label_issues()`](https://ridsonap.is-a.dev/labelnoise/reference/find_label_issues.md)
returns one row per example:

``` r

issues <- find_label_issues(sim, truth = given)
issues
#> # A tibble: 1,000 × 5
#>     .row given predicted label_quality is_label_issue
#>    <int> <fct> <fct>             <dbl> <lgl>         
#>  1     1 A     A                0.813  FALSE         
#>  2     2 A     A                0.924  FALSE         
#>  3     3 B     B                0.876  FALSE         
#>  4     4 D     D                0.963  FALSE         
#>  5     5 A     A                0.713  FALSE         
#>  6     6 B     C                0.0481 TRUE          
#>  7     7 D     D                0.953  FALSE         
#>  8     8 B     B                0.762  FALSE         
#>  9     9 B     B                0.928  FALSE         
#> 10    10 A     A                0.846  FALSE         
#> # ℹ 990 more rows
```

Sort the flagged examples by `label_quality` to review the most
suspicious ones first:

``` r

flagged <- issues[issues$is_label_issue, ]
head(flagged[order(flagged$label_quality), ])
#> # A tibble: 6 × 5
#>    .row given predicted label_quality is_label_issue
#>   <int> <fct> <fct>             <dbl> <lgl>         
#> 1   638 C     A               0.00189 TRUE          
#> 2   385 D     A               0.00328 TRUE          
#> 3   509 D     C               0.00392 TRUE          
#> 4    51 A     B               0.00463 TRUE          
#> 5   846 C     B               0.00493 TRUE          
#> 6   482 B     A               0.00503 TRUE
```

Because this is a simulation, we can check the result:

``` r

table(flagged = issues$is_label_issue, mislabelled = sim$given != sim$true)
#>        mislabelled
#> flagged FALSE TRUE
#>   FALSE   879   14
#>   TRUE      7  100
```

## With tidymodels

In practice the probabilities come from resampling a model. Fit it with
[`tune::fit_resamples()`](https://tune.tidymodels.org/reference/fit_resamples.html)
and save the predictions; labelnoise reads them directly and puts every
example back in its original row.

We add a few errors to `iris` to see whether they are found.

``` r

library(parsnip)
library(workflows)

iris_noisy <- iris
flipped <- c(5, 30, 60, 80, 110, 140)
iris_noisy$Species[flipped] <- c(
  "versicolor", "virginica", "setosa", "virginica", "setosa", "versicolor"
)

wf <- workflow(Species ~ ., multinom_reg() |> set_engine("nnet"))
set.seed(1)
folds <- rsample::vfold_cv(iris_noisy, v = 5)
res <- tune::fit_resamples(
  wf, folds,
  control = tune::control_resamples(save_pred = TRUE)
)

issues <- find_label_issues(res)
which(issues$is_label_issue)
#> [1]   5  30  60  80 110 134 140
```

The flagged row numbers refer to rows of `iris_noisy`, so you can join
them back to the data for review. If you tuned several models with
[`tune::tune_grid()`](https://tune.tidymodels.org/reference/tune_grid.html),
choose one with `parameters = tune::select_best(...)`.

Any data frame of predictions works too, for example the output of
[`tune::collect_predictions()`](https://tune.tidymodels.org/reference/collect_predictions.html)
or [`augment()`](https://generics.r-lib.org/reference/augment.html):
name the label column in `truth`, and the `.pred_*` columns are found
automatically.

## Is the dataset healthy?

[`health_summary()`](https://ridsonap.is-a.dev/labelnoise/reference/health_summary.md)
gives the overall picture: how many labels look wrong, which classes are
affected most, and which pairs of classes get confused. Confused pairs
often point to an unclear definition or coding guideline rather than to
individual mistakes.

``` r

health_summary(sim, truth = given)
#> Label health
#> • Overall score: 0.915
#> • Estimated label issues: 85 of 1000 examples
#> 
#> Classes with the lowest label quality:
#> # A tibble: 4 × 7
#>   class     n num_label_issues label_issue_rate label_noise inverse_label_noise
#>   <fct> <int>            <int>            <dbl>       <dbl>               <dbl>
#> 1 D       125               19           0.152       0.173               0.194 
#> 2 C       207               28           0.135       0.130               0.169 
#> 3 B       280               22           0.0786      0.116               0.103 
#> 4 A       388               16           0.0412      0.0800              0.0602
#> # ℹ 1 more variable: label_quality <dbl>
#> 
#> Most confused class pairs:
#> # A tibble: 5 × 4
#>   class_1 class_2 num_overlapping joint_probability
#>   <fct>   <fct>             <int>             <dbl>
#> 1 A       C                    26            0.0262
#> 2 B       D                    22            0.0220
#> 3 B       C                    22            0.0218
#> 4 A       B                    18            0.0181
#> 5 C       D                    13            0.0126
```

The underlying estimates are available separately:
[`confident_joint()`](https://ridsonap.is-a.dev/labelnoise/reference/confident_joint.md),
[`estimate_joint()`](https://ridsonap.is-a.dev/labelnoise/reference/estimate_joint.md),
[`noise_matrices()`](https://ridsonap.is-a.dev/labelnoise/reference/noise_matrices.md)
and
[`num_label_issues()`](https://ridsonap.is-a.dev/labelnoise/reference/num_label_issues.md).

## Choosing a rule

[`find_label_issues()`](https://ridsonap.is-a.dev/labelnoise/reference/find_label_issues.md)
implements the five rank-and-prune rules of the paper through
`filter_by`. The default, `"prune_by_noise_rate"`, flags in each cell of
the estimated joint distribution the examples with the largest margin
towards the other class. In our simulations its accuracy was close to
that of `"both"` and `"prune_by_class"`; `"predicted_neq_given"` is a
simple baseline that flags every disagreement with the model. Use
`frac_noise` below 1 to flag fewer, more certain examples.

## Other modelling frameworks

The same functions accept

- a label vector plus a probability matrix:
  `find_label_issues(labels, pred_probs = probs)`;
- an mlr3 `ResampleResult` or `PredictionClassif` from a learner with
  `predict_type = "prob"`;
- a caret `train` object fitted with
  `trainControl(classProbs = TRUE, savePredictions = "final")`.

Repeated cross-validation is fine: predictions of the same example are
averaged. Bootstrap resampling is not, because some rows never get an
out-of-sample prediction.

Without any framework, cross-validation takes a few lines:

``` r

set.seed(1)
fold <- sample(rep(1:5, length.out = nrow(iris)))
probs <- matrix(NA_real_, nrow(iris), 3, dimnames = list(NULL, levels(iris$Species)))
for (k in 1:5) {
  fit <- nnet::multinom(Species ~ ., data = iris[fold != k, ], trace = FALSE)
  probs[fold == k, ] <- predict(fit, iris[fold == k, ], type = "probs")
}
num_label_issues(iris$Species, pred_probs = probs)
#> [1] 4
```

## Text classification: coding open answers

A common use is checking coded open-ended answers, such as industry or
occupation codes assigned to free-text descriptions. The sketch below
uses textrecipes for TF-IDF features and a penalised multinomial model.
It is not run when this vignette is built, because it needs extra
packages and a dataset `survey` with a `description` text column and a
`code` factor.

``` r

library(tidymodels)
library(textrecipes)

rec <- recipe(code ~ description, data = survey) |>
  step_tokenize(description) |>
  step_tokenfilter(description, max_tokens = 5000) |>
  step_tfidf(description)
wf <- workflow(rec, multinom_reg(penalty = 0.01) |> set_engine("glmnet"))

folds <- vfold_cv(survey, v = 5, strata = code)
res <- fit_resamples(wf, folds, control = control_resamples(save_pred = TRUE))

review <- survey |>
  bind_cols(find_label_issues(res) |> select(-given)) |>
  filter(is_label_issue) |>
  arrange(label_quality)

health_summary(res)$overlapping_classes
```

With many fine-grained codes, start at a coarser level of the
classification, where every class has enough examples for stable
thresholds, and move down once the coarse level is clean.

## Caveats

- **Probabilities must be out-of-sample.** A model that has seen a label
  will usually agree with it, hiding the error.
- **Results are only as good as the classifier.** With a weak
  classifier, many correct labels are flagged and the number of errors
  is overestimated. In our simulations with a weak classifier and 5%
  wrong labels, the estimated number of errors was several times the
  true number. Check the model’s cross-validated accuracy first.
- **A flag is a reason to look, not a verdict.** Ambiguous examples that
  fit several classes are flagged too. Use the output to prioritise
  manual review.
- Confident learning assumes that the chance of a wrong label depends on
  the true class, not on the individual example. Real errors often
  depend on how ambiguous the example is, so treat the ranking as a
  strong heuristic.

## Relation to cleanlab

labelnoise is an independent implementation from the published papers,
not a port of the Python package
[cleanlab](https://github.com/cleanlab/cleanlab). Its test suite
compares results with cleanlab 2.9.0 on simulated data: the confident
joint, the five filtering rules,
[`num_label_issues()`](https://ridsonap.is-a.dev/labelnoise/reference/num_label_issues.md)
and the self-confidence and normalised-margin scores agree exactly. The
calibrated joint differs only by cleanlab’s rounding to whole counts,
and the confidence-weighted entropy uses a different map to `[0, 1]`
with the same ranking.

## References

Northcutt, C., Jiang, L., & Chuang, I. (2021). Confident learning:
Estimating uncertainty in dataset labels. *Journal of Artificial
Intelligence Research*, 70, 1373–1411.
<https://doi.org/10.1613/jair.1.12125>

Kuan, J., & Mueller, J. (2022). Model-agnostic label quality scoring to
detect real-world label errors. *ICML DataPerf Workshop*.
<https://doi.org/10.5281/zenodo.18168246>

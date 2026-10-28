noisy_iris <- function() {
  data <- datasets::iris
  flipped <- c(5L, 30L, 60L, 80L, 110L, 140L)
  data$Species[flipped] <- c("versicolor", "virginica", "setosa", "virginica", "setosa", "versicolor")
  list(data = data, flipped = flipped)
}

expect_finds_flips <- function(issues, flipped) {
  expect_identical(issues$.row, 1:150)
  found <- intersect(which(issues$is_label_issue), flipped)
  expect_gte(length(found), 5)
}

test_that("tune resampling results are accepted", {
  skip_if_not_installed(c("tune", "parsnip", "rsample", "workflows", "nnet"))
  iris_noisy <- noisy_iris()
  wf <- workflows::workflow(
    Species ~ .,
    parsnip::set_engine(parsnip::multinom_reg(), "nnet")
  )
  set.seed(1)
  folds <- rsample::vfold_cv(iris_noisy$data, v = 5)
  res <- tune::fit_resamples(
    wf, folds,
    control = tune::control_resamples(save_pred = TRUE)
  )
  issues <- find_label_issues(res)
  expect_identical(issues$given, iris_noisy$data$Species)
  expect_finds_flips(issues, iris_noisy$flipped)

  no_pred <- tune::fit_resamples(wf, folds)
  expect_error(find_label_issues(no_pred), "save_pred = TRUE")
})

test_that("tune_results with several candidates need parameters", {
  skip_if_not_installed(c("tune", "parsnip", "rsample", "workflows", "nnet"))
  iris_noisy <- noisy_iris()
  wf <- workflows::workflow(
    Species ~ .,
    parsnip::set_engine(parsnip::multinom_reg(penalty = tune::tune()), "nnet")
  )
  set.seed(1)
  folds <- rsample::vfold_cv(iris_noisy$data, v = 5)
  res <- tune::tune_grid(
    wf, folds,
    grid = data.frame(penalty = c(0.001, 0.1)),
    control = tune::control_grid(save_pred = TRUE)
  )
  expect_error(find_label_issues(res), "2 candidate models")
  best <- tune::select_best(res, metric = "roc_auc")
  issues <- find_label_issues(res, parameters = best)
  expect_finds_flips(issues, iris_noisy$flipped)
})

test_that("bootstrap resamples that miss rows are rejected", {
  skip_if_not_installed(c("tune", "parsnip", "rsample", "workflows", "nnet"))
  iris_noisy <- noisy_iris()
  wf <- workflows::workflow(
    Species ~ .,
    parsnip::set_engine(parsnip::multinom_reg(), "nnet")
  )
  set.seed(2)
  boots <- rsample::bootstraps(iris_noisy$data, times = 2)
  res <- tune::fit_resamples(wf, boots, control = tune::control_resamples(save_pred = TRUE))
  expect_error(find_label_issues(res), "no out-of-sample prediction")
})

test_that("mlr3 predictions and resample results are accepted", {
  skip_if_not_installed("mlr3")
  logger <- lgr::get_logger("mlr3")
  old_threshold <- logger$threshold
  logger$set_threshold("warn")
  withr::defer(logger$set_threshold(old_threshold))
  iris_noisy <- noisy_iris()
  task <- mlr3::as_task_classif(iris_noisy$data, target = "Species")
  learner <- mlr3::lrn("classif.rpart", predict_type = "prob")
  set.seed(1)
  rr <- mlr3::resample(task, learner, mlr3::rsmp("repeated_cv", folds = 5, repeats = 2))
  issues <- find_label_issues(rr)
  expect_identical(issues$given, iris_noisy$data$Species)
  expect_finds_flips(issues, iris_noisy$flipped)
  expect_identical(find_label_issues(rr$prediction()), issues)

  learner_response <- mlr3::lrn("classif.rpart")
  rr_response <- mlr3::resample(task, learner_response, mlr3::rsmp("cv", folds = 3))
  expect_error(find_label_issues(rr_response), "predict_type")
})

test_that("caret train objects are accepted", {
  skip_if_not_installed(c("caret", "nnet"))
  iris_noisy <- noisy_iris()
  set.seed(1)
  fit <- caret::train(
    Species ~ ., data = iris_noisy$data, method = "multinom", trace = FALSE,
    trControl = caret::trainControl(
      method = "repeatedcv", number = 5, repeats = 2,
      classProbs = TRUE, savePredictions = "final"
    )
  )
  issues <- find_label_issues(fit)
  expect_identical(issues$given, iris_noisy$data$Species)
  expect_finds_flips(issues, iris_noisy$flipped)

  fit_none <- caret::train(
    Species ~ ., data = iris_noisy$data, method = "multinom", trace = FALSE,
    trControl = caret::trainControl(method = "cv", number = 3, classProbs = TRUE)
  )
  expect_error(find_label_issues(fit_none), "savePredictions")
})

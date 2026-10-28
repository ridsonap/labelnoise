test_that("find_label_issues returns one row per example in input order", {
  sim <- simulate_label_noise(n = 200, seed = 5)
  issues <- find_label_issues(sim, truth = given)
  expect_s3_class(issues, "tbl_df")
  expect_named(issues, c(".row", "given", "predicted", "label_quality", "is_label_issue"))
  expect_identical(issues$.row, 1:200)
  expect_identical(issues$given, sim$given)
  expect_type(issues$is_label_issue, "logical")
})

test_that("every rule flags the hand-computed error", {
  rules <- c("prune_by_noise_rate", "prune_by_class", "both", "confident_learning", "predicted_neq_given")
  for (rule in rules) {
    issues <- find_label_issues(toy_labels, toy_probs, filter_by = rule)
    expect_identical(which(issues$is_label_issue), 3L, info = rule)
  }
})

test_that("examples predicted as their given label are never flagged", {
  sim <- simulate_label_noise(n = 500, noise_rate = 0.3, signal = 1, seed = 6)
  for (rule in c("prune_by_noise_rate", "prune_by_class", "both", "confident_learning")) {
    issues <- find_label_issues(sim, truth = given, filter_by = rule)
    expect_false(any(issues$is_label_issue & issues$predicted == issues$given), info = rule)
  }
})

test_that("frac_noise scales the number of flagged examples", {
  sim <- simulate_label_noise(n = 500, noise_rate = 0.2, seed = 7)
  full <- sum(find_label_issues(sim, truth = given)$is_label_issue)
  half <- sum(find_label_issues(sim, truth = given, frac_noise = 0.5)$is_label_issue)
  none <- sum(find_label_issues(sim, truth = given, frac_noise = 0)$is_label_issue)
  expect_lt(half, full)
  expect_identical(none, 0L)
})

test_that("min_examples_per_class keeps examples of every class", {
  sim <- simulate_label_noise(n = 200, noise_rate = 0.5, signal = 0.5, seed = 8)
  for (rule in c("prune_by_noise_rate", "prune_by_class")) {
    issues <- find_label_issues(sim, truth = given, filter_by = rule, min_examples_per_class = 40)
    kept <- table(issues$given[!issues$is_label_issue])
    small <- table(issues$given) < 40
    expect_true(all(kept[!small] >= 40), info = rule)
  }
})

test_that("rank_by changes the reported score", {
  issues <- find_label_issues(toy_labels, toy_probs, rank_by = "confidence_weighted_entropy")
  expect_equal(
    issues$label_quality,
    label_quality_scores(toy_labels, toy_probs, method = "confidence_weighted_entropy")
  )
})

test_that("arguments are validated", {
  expect_error(find_label_issues(toy_labels, toy_probs, frac_noise = 2), "between 0 and 1")
  expect_error(find_label_issues(toy_labels, toy_probs, min_examples_per_class = -1), "whole number")
  expect_error(find_label_issues(toy_labels, toy_probs, filter_by = "nope"))
})

test_that("flagged examples are mostly real errors on easy simulated data", {
  sim <- simulate_label_noise(n = 2000, noise_rate = 0.1, signal = 4, seed = 9)
  issues <- find_label_issues(sim, truth = given)
  error <- sim$given != sim$true
  expect_gt(mean(error[issues$is_label_issue]), 0.8)
  expect_gt(mean(issues$is_label_issue[error]), 0.8)
})

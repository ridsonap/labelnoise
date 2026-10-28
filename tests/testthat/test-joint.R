test_that("thresholds are the mean self-confidence per class", {
  expect_equal(
    class_thresholds(toy_labels, toy_probs),
    c(A = 0.5, B = 0.75)
  )
})

test_that("confident joint matches a hand-computed example", {
  expected <- matrix(
    c(2L, 1L,
      0L, 1L),
    nrow = 2, byrow = TRUE,
    dimnames = list(given = c("A", "B"), true = c("A", "B"))
  )
  expect_identical(confident_joint(toy_labels, toy_probs, calibrate = FALSE), expected)
})

test_that("calibration rescales rows to the class counts", {
  cal <- confident_joint(toy_labels, toy_probs)
  expect_equal(unname(rowSums(cal)), c(3, 2))
  expect_equal(unname(cal), matrix(c(2, 1, 0, 2), nrow = 2, byrow = TRUE))
})

test_that("collisions go to the most likely confident class", {
  labels <- factor(c("A", "A", "A", "B", "C", "C"), levels = c("A", "B", "C"))
  probs <- matrix(
    c(0.45, 0.00, 0.55,
      0.55, 0.03, 0.42,
      0.30, 0.60, 0.10,
      0.10, 0.80, 0.10,
      0.20, 0.10, 0.70,
      0.60, 0.30, 0.10),
    ncol = 3, byrow = TRUE, dimnames = list(NULL, c("A", "B", "C"))
  )
  # Thresholds: A = 1.3 / 3, B = 0.8, C = 0.4.
  # Row 1 is confident for A and C and goes to C (0.55 > 0.45).
  # Row 2 is confident for A and C and goes to A (0.55 > 0.42).
  # Row 3 is confident for no class and is not counted.
  expected <- matrix(
    c(1L, 0L, 1L,
      0L, 1L, 0L,
      1L, 0L, 1L),
    nrow = 3, byrow = TRUE,
    dimnames = list(given = c("A", "B", "C"), true = c("A", "B", "C"))
  )
  expect_identical(confident_joint(labels, probs, calibrate = FALSE), expected)
})

test_that("joint and noise matrices have the right margins", {
  sim <- simulate_label_noise(n = 300, seed = 3)
  nm <- noise_matrices(sim, truth = given)
  expect_equal(sum(nm$joint), 1)
  expect_equal(unname(rowSums(nm$joint)), as.numeric(table(sim$given)) / 300)
  expect_equal(unname(colSums(nm$noise_matrix)), rep(1, 4))
  expect_equal(unname(rowSums(nm$inverse_noise_matrix)), rep(1, 4))
  expect_equal(nm$prior_true, colSums(nm$joint))
  expect_identical(names(dimnames(nm$joint)), c("given", "true"))
})

test_that("hand-computed joint and noise matrices", {
  nm <- noise_matrices(toy_labels, toy_probs)
  expect_equal(unname(nm$joint), matrix(c(0.4, 0.2, 0, 0.4), 2, byrow = TRUE))
  expect_equal(unname(nm$noise_matrix), matrix(c(1, 1 / 3, 0, 2 / 3), 2, byrow = TRUE))
  expect_equal(unname(nm$inverse_noise_matrix), matrix(c(2 / 3, 1 / 3, 0, 1), 2, byrow = TRUE))
})

test_that("num_label_issues offers two estimators", {
  expect_identical(num_label_issues(toy_labels, toy_probs), 1L)
  expect_identical(num_label_issues(toy_labels, toy_probs, method = "calibrated"), 1L)
  expect_error(num_label_issues(toy_labels, toy_probs, method = "nope"))
})

test_that("a class without given labels warns and is never a true class", {
  labels <- factor(c("A", "A", "B", "B"), levels = c("A", "B", "C"))
  probs <- matrix(
    c(0.8, 0.1, 0.1,
      0.1, 0.1, 0.8,
      0.1, 0.8, 0.1,
      0.2, 0.7, 0.1),
    ncol = 3, byrow = TRUE, dimnames = list(NULL, c("A", "B", "C"))
  )
  expect_warning(th <- class_thresholds(labels, probs), "no examples")
  expect_identical(th[["C"]], Inf)
  cj <- suppressWarnings(confident_joint(labels, probs, calibrate = FALSE))
  expect_equal(sum(cj[, "C"]), 0)
})

test_that("a class without given labels gets an empty calibrated row", {
  labels <- factor(c("A", "A", "B", "B"), levels = c("A", "B", "C"))
  probs <- matrix(
    c(0.8, 0.1, 0.1,
      0.1, 0.1, 0.8,
      0.1, 0.8, 0.1,
      0.2, 0.7, 0.1),
    ncol = 3, byrow = TRUE, dimnames = list(NULL, c("A", "B", "C"))
  )
  joint <- suppressWarnings(estimate_joint(labels, probs))
  expect_false(anyNA(joint))
  expect_equal(unname(joint["C", ]), c(0, 0, 0))
  expect_equal(sum(joint), 1)
})

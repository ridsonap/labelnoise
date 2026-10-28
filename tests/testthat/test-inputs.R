test_that("labels can be factor, character or 1-based integers", {
  from_factor <- label_inputs(toy_labels, toy_probs)
  from_char <- label_inputs(as.character(toy_labels), toy_probs)
  from_int <- label_inputs(as.integer(toy_labels), toy_probs)
  expect_identical(from_char$labels, from_factor$labels)
  expect_identical(from_int$labels, from_factor$labels)
  expect_identical(from_factor$row_id, 1:5)
})

test_that("logical labels map to FALSE/TRUE columns", {
  probs <- matrix(c(0.8, 0.2, 0.3, 0.7), 2, byrow = TRUE)
  inputs <- label_inputs(c(FALSE, TRUE), probs)
  expect_identical(levels(inputs$labels), c("FALSE", "TRUE"))
})

test_that("columns are matched to labels by name", {
  swapped <- toy_probs[, c("B", "A")]
  expect_equal(
    label_inputs(toy_labels, swapped)$pred_probs,
    label_inputs(toy_labels, toy_probs)$pred_probs
  )
  expect_identical(levels(label_inputs(toy_labels, swapped)$labels), c("A", "B"))
  expect_identical(levels(label_inputs(as.character(toy_labels), swapped)$labels), c("B", "A"))
  expect_equal(
    find_label_issues(toy_labels, swapped)$is_label_issue,
    find_label_issues(toy_labels, toy_probs)$is_label_issue
  )
})

test_that("unnamed columns follow factor levels", {
  inputs <- label_inputs(toy_labels, unname(toy_probs))
  expect_identical(colnames(inputs$pred_probs), c("A", "B"))
})

test_that("unused factor levels without a column are dropped", {
  labels <- factor(c("A", "B"), levels = c("A", "B", "Z"))
  probs <- matrix(c(0.9, 0.1, 0.2, 0.8), 2, byrow = TRUE, dimnames = list(NULL, c("A", "B")))
  expect_identical(levels(label_inputs(labels, probs)$labels), c("A", "B"))
})

test_that("invalid inputs give informative errors", {
  expect_error(label_inputs(toy_labels), "is missing")
  expect_error(label_inputs(toy_labels, toy_probs[1:3, ]), "3 rows, but 5 labels")
  expect_error(label_inputs(c(0L, 1L, 1L, 0L, 1L), toy_probs), "1-based")
  expect_error(label_inputs(c(1L, 3L, 1L, 2L, 2L), toy_probs), "between 1 and 2")
  expect_error(label_inputs(c("A", "A", "A", "B", "Q"), toy_probs), "no matching column")
  bad <- toy_probs
  bad[1, 1] <- 0.9
  expect_error(label_inputs(toy_labels, bad), "sum to 1")
  bad[1, ] <- c(NA, 0.3)
  expect_error(label_inputs(toy_labels, bad), "missing values")
  expect_error(label_inputs(factor(c("A", NA, "A", "B", "B")), toy_probs), "missing values")
  expect_error(label_inputs(toy_labels, toy_probs[, 1, drop = FALSE]), "at least two")
  expect_error(label_inputs(list(1), toy_probs), "Can't use labels")
  expect_snapshot(label_inputs(toy_labels, toy_probs[1:3, ]), error = TRUE)
})

test_that("small rounding errors in probabilities are tolerated", {
  probs <- toy_probs
  probs[1, ] <- c(0.7 + 1e-5, 0.3)
  inputs <- label_inputs(toy_labels, probs)
  expect_equal(unname(rowSums(inputs$pred_probs)), rep(1, 5))
})

test_that("data frames follow the yardstick convention", {
  preds <- data.frame(
    id = 1:5,
    class = toy_labels,
    .pred_class = toy_labels,
    .pred_A = toy_probs[, "A"],
    .pred_B = toy_probs[, "B"]
  )
  inputs <- label_inputs(preds, truth = class)
  expect_equal(inputs$pred_probs, label_inputs(toy_labels, toy_probs)$pred_probs)

  # Explicit selection with tidyselect
  names(preds)[4:5] <- c("prob_A", "prob_B")
  expect_error(label_inputs(preds, truth = class), "Can't find probability columns")
  probs <- preds[c("prob_A", "prob_B")]
  names(probs) <- c("A", "B")
  renamed <- cbind(preds["class"], probs)
  expect_equal(label_inputs(renamed, truth = class, A, B)$pred_probs, inputs$pred_probs)
  expect_error(label_inputs(renamed), "truth")
})

test_that("data frames with repeated .row are averaged", {
  preds <- data.frame(
    .row = c(1L, 2L, 1L, 2L),
    class = factor(c("A", "B", "A", "B")),
    .pred_A = c(0.8, 0.4, 0.6, 0.2),
    .pred_B = c(0.2, 0.6, 0.4, 0.8)
  )
  inputs <- label_inputs(preds, truth = class)
  expect_identical(inputs$row_id, 1:2)
  expect_equal(unname(inputs$pred_probs[, "A"]), c(0.7, 0.3))

  preds$class[3] <- "B"
  expect_error(label_inputs(preds, truth = class), "different given labels")
})

test_that("labelnoise_inputs pass through and print", {
  inputs <- label_inputs(toy_labels, toy_probs)
  expect_identical(label_inputs(inputs), inputs)
  expect_snapshot(print(inputs))
})

test_that("misspelled arguments are caught", {
  expect_error(label_inputs(toy_labels, toy_probs, pred_prob = 1), "must be empty")
})

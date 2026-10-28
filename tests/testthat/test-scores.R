test_that("self-confidence is the probability of the given label", {
  expect_equal(label_quality_scores(toy_labels, toy_probs), c(0.7, 0.6, 0.2, 0.9, 0.6))
})

test_that("normalized margin is rescaled to [0, 1]", {
  labels <- factor(c("A", "B"), levels = c("A", "B", "C"))
  probs <- matrix(
    c(0.5, 0.3, 0.2,
      0.6, 0.1, 0.3),
    ncol = 3, byrow = TRUE, dimnames = list(NULL, c("A", "B", "C"))
  )
  scores <- suppressWarnings(label_quality_scores(labels, probs, method = "normalized_margin"))
  expect_equal(scores, c((0.5 - 0.3 + 1) / 2, (0.1 - 0.6 + 1) / 2))
})

test_that("confidence weighted entropy follows its definition", {
  labels <- factor(c("A", "B"), levels = c("A", "B", "C"))
  probs <- matrix(
    c(0.5, 0.3, 0.2,
      0.6, 0.1, 0.3),
    ncol = 3, byrow = TRUE, dimnames = list(NULL, c("A", "B", "C"))
  )
  entropy <- -rowSums(probs * log(probs)) / log(3)
  ratio <- c(0.5, 0.1) / entropy
  scores <- suppressWarnings(
    label_quality_scores(labels, probs, method = "confidence_weighted_entropy")
  )
  expect_equal(scores, ratio / (1 + ratio))
})

test_that("confidence weighted entropy handles one-hot predictions", {
  probs <- matrix(c(1, 0, 0, 1), 2, dimnames = list(NULL, c("A", "B")))
  scores <- label_quality_scores(factor(c("A", "A")), probs, method = "confidence_weighted_entropy")
  expect_true(all(is.finite(scores)))
  expect_gt(scores[1], scores[2])
})

test_that("adjusted scores subtract class thresholds", {
  # thresholds 0.5 and 0.75; row 1 becomes (0.95, 0.30) / 1.25
  scores <- label_quality_scores(toy_labels, toy_probs, adjust = TRUE)
  expect_equal(scores[1], 0.95 / 1.25)
  expect_error(
    label_quality_scores(toy_labels, toy_probs, method = "confidence_weighted_entropy", adjust = TRUE),
    "not available"
  )
})

test_that("all scores lie in [0, 1]", {
  sim <- simulate_label_noise(n = 300, seed = 4)
  for (method in c("self_confidence", "normalized_margin", "confidence_weighted_entropy")) {
    scores <- label_quality_scores(sim, truth = given, method = method)
    expect_true(all(scores >= 0 & scores <= 1), info = method)
  }
})

# Reference outputs from the Python cleanlab package, used as a black-box
# oracle. See data-raw/make-fixtures.py.

for (name in c("k3", "k4", "k6")) {
  probs <- read_fixture(name, "probs")
  labels <- as.integer(read_fixture(name, "labels"))
  oracle <- read_oracle(name)

  test_that(paste("confident joint matches cleanlab:", name), {
    cj <- unname(confident_joint(labels, probs, calibrate = FALSE))
    expected <- read_fixture(name, "cj-raw")
    storage.mode(expected) <- "integer"
    expect_identical(cj, expected)
  })

  test_that(paste("calibrated joint matches cleanlab up to rounding:", name), {
    # cleanlab rounds the calibrated counts to integers (keeping row sums);
    # we keep them exact.
    cal <- unname(confident_joint(labels, probs))
    expect_lt(max(abs(cal - read_fixture(name, "cj-calibrated"))), 1)
    joint <- unname(estimate_joint(labels, probs))
    expect_lte(max(abs(joint - read_fixture(name, "joint"))), 1 / length(labels))
  })

  test_that(paste("noise matrices match cleanlab up to rounding:", name), {
    nm <- noise_matrices(labels, probs)
    expect_lte(max(abs(unname(nm$noise_matrix) - read_fixture(name, "noise-matrix"))), 0.05)
    # cleanlab orients the inverse noise matrix as [true, given].
    expect_lte(
      max(abs(t(unname(nm$inverse_noise_matrix)) - read_fixture(name, "inverse-noise-matrix"))),
      0.05
    )
  })

  test_that(paste("num_label_issues matches cleanlab:", name), {
    expect_identical(num_label_issues(labels, probs), as.integer(read_fixture(name, "num-label-issues")))
  })

  test_that(paste("label quality scores match cleanlab:", name), {
    for (method in c("self_confidence", "normalized_margin")) {
      for (adjust in c(FALSE, TRUE)) {
        column <- paste0("score-", method, if (adjust) "-adjusted")
        expect_equal(
          label_quality_scores(labels, probs, method = method, adjust = adjust),
          oracle[[column]],
          tolerance = 1e-10,
          info = column
        )
      }
    }
    # Our confidence weighted entropy uses a different monotone map to [0, 1],
    # so only the ranking is compared.
    ours <- label_quality_scores(labels, probs, method = "confidence_weighted_entropy")
    expect_identical(rank(ours), rank(oracle[["score-confidence_weighted_entropy"]]))
  })

  test_that(paste("every filter matches cleanlab:", name), {
    rules <- c("prune_by_noise_rate", "prune_by_class", "both", "confident_learning", "predicted_neq_given")
    for (rule in rules) {
      ours <- find_label_issues(labels, probs, filter_by = rule)$is_label_issue
      expect_identical(ours, as.logical(oracle[[paste0("issue-", rule)]]), info = rule)
    }
  })
}

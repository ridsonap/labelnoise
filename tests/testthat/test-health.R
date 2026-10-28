test_that("health_summary is consistent with num_label_issues", {
  sim <- simulate_label_noise(n = 600, noise_rate = 0.15, seed = 10)
  health <- health_summary(sim, truth = given)
  expect_s3_class(health, "label_health")
  expect_identical(health$num_label_issues, num_label_issues(sim, truth = given))
  expect_equal(health$score, 1 - health$num_label_issues / 600)
  expect_identical(sum(health$classes$num_label_issues), health$num_label_issues)
  expect_identical(sum(health$classes$n), 600L)
  expect_true(all(diff(health$classes$label_quality) >= 0))
  expect_true(all(diff(health$overlapping_classes$joint_probability) <= 0))
  expect_true(all(health$overlapping_classes$joint_probability > 0))

  calibrated <- health_summary(sim, truth = given, method = "calibrated")
  expect_identical(calibrated$num_label_issues, num_label_issues(sim, truth = given, method = "calibrated"))
})

test_that("health_summary matches the hand-computed example", {
  health <- health_summary(toy_labels, toy_probs)
  expect_equal(health$score, 0.8)
  classes <- health$classes[order(health$classes$class), ]
  expect_equal(classes$label_noise, c(0, 1 / 3))
  expect_equal(classes$inverse_label_noise, c(1 / 3, 0))
  expect_equal(health$overlapping_classes$num_overlapping, 1L)
})

test_that("health_summary prints", {
  sim <- simulate_label_noise(n = 300, seed = 11)
  expect_snapshot(health_summary(sim, truth = given))
})

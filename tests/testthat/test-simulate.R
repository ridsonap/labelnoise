test_that("simulate_label_noise is reproducible and leaves the RNG alone", {
  set.seed(1)
  before <- .Random.seed
  a <- simulate_label_noise(n = 50, seed = 99)
  expect_identical(.Random.seed, before)
  b <- simulate_label_noise(n = 50, seed = 99)
  expect_identical(a, b)
})

test_that("simulate_label_noise returns the documented shape", {
  sim <- simulate_label_noise(n = 100, n_classes = 3, noise_rate = 0, seed = 1)
  expect_named(sim, c("true", "given", ".pred_A", ".pred_B", ".pred_C"))
  expect_identical(sim$true, sim$given)
  expect_equal(rowSums(sim[3:5]), rep(1, 100))
  expect_error(simulate_label_noise(n_classes = 1), "at least 2")
  expect_error(simulate_label_noise(prior = 1:2), "prior")
})

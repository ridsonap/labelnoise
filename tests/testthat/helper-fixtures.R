read_fixture <- function(name, what) {
  path <- test_path("fixtures", paste0(name, "-", what, ".csv"))
  unname(as.matrix(utils::read.csv(path, header = FALSE)))
}

read_oracle <- function(name) {
  utils::read.csv(test_path("fixtures", paste0(name, "-oracle.csv")), check.names = FALSE)
}

# A small example that can be checked by hand.
#   thresholds: A = mean(0.7, 0.6, 0.2) = 0.5, B = mean(0.9, 0.6) = 0.75
#   row 3 (given A) is a confident B (0.8 >= 0.75) and not a confident A.
#   row 5 (given B) is confident for neither class, so it is not counted.
toy_labels <- factor(c("A", "A", "A", "B", "B"), levels = c("A", "B"))
toy_probs <- matrix(
  c(0.7, 0.3,
    0.6, 0.4,
    0.2, 0.8,
    0.1, 0.9,
    0.4, 0.6),
  ncol = 2, byrow = TRUE,
  dimnames = list(NULL, c("A", "B"))
)

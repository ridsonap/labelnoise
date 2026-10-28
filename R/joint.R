#' Per-class confidence thresholds
#'
#' The threshold of class `j` is the mean predicted probability of class `j`
#' among examples whose given label is `j` (Northcutt et al., 2021, Eq. 2).
#' An example is a confident member of class `j` when its predicted
#' probability for `j` reaches this threshold.
#'
#' @inheritParams label_inputs
#' @param ... Passed to [label_inputs()]: for example `pred_probs` when `x`
#'   is a label vector, or `truth` when `x` is a data frame.
#'
#' @return A named numeric vector with one threshold per class. Classes
#'   without any given label get `Inf`, so no example is counted as a
#'   confident member of them.
#'
#' @references
#' Northcutt, C., Jiang, L., & Chuang, I. (2021). Confident learning:
#' Estimating uncertainty in dataset labels. *Journal of Artificial
#' Intelligence Research*, 70, 1373–1411. \doi{10.1613/jair.1.12125}
#'
#' @export
#' @examples
#' sim <- simulate_label_noise(n = 200, seed = 1)
#' class_thresholds(sim, truth = given)
class_thresholds <- function(x, ...) {
  inputs <- label_inputs(x, ...)
  thresholds_impl(as.integer(inputs$labels), inputs$pred_probs)
}

#' The confident joint
#'
#' @description
#' `confident_joint()` counts, for every pair of given label `i` and
#' (estimated) true label `j`, the examples labelled `i` that are confident
#' members of class `j` (Northcutt et al., 2021, Eq. 1 and Algorithm 1). An
#' example is a confident member of class `j` when its predicted probability
#' for `j` is at least the threshold of `j` (see [class_thresholds()]). When
#' it is a confident member of several classes, the one with the largest
#' predicted probability among them is used. Examples that are confident
#' members of no class are not counted.
#'
#' With `calibrate = TRUE`, each row is rescaled so that it sums to the
#' number of examples with that given label (the numerator of Eq. 3). Rows
#' with no confident examples are treated as noise free.
#'
#' Off-diagonal cells are label errors: examples given label `i` that look
#' like they belong to class `j`.
#'
#' @inheritParams class_thresholds
#' @param calibrate Rescale rows to the observed class counts?
#'
#' @return A square matrix with dimension names `given` (rows) and `true`
#'   (columns). Integer counts when `calibrate = FALSE`; real-valued
#'   calibrated counts otherwise.
#'
#' @inherit class_thresholds references
#' @seealso [estimate_joint()], [noise_matrices()], [num_label_issues()]
#' @export
#' @examples
#' sim <- simulate_label_noise(n = 500, seed = 1)
#' confident_joint(sim, truth = given, calibrate = FALSE)
#' confident_joint(sim, truth = given)
confident_joint <- function(x, ..., calibrate = TRUE) {
  inputs <- label_inputs(x, ...)
  cj <- confident_joint_impl(as.integer(inputs$labels), inputs$pred_probs)
  if (calibrate) {
    calibrate_joint(cj$counts, as.integer(inputs$labels))
  } else {
    cj$counts
  }
}

#' Estimate the joint distribution of given and true labels
#'
#' Normalises the calibrated confident joint so that it sums to one
#' (Northcutt et al., 2021, Eq. 3 and Algorithm 2). Entry `[i, j]` estimates
#' the proportion of examples that have given label `i` and true label `j`.
#'
#' @inheritParams class_thresholds
#' @return A square matrix with dimension names `given` and `true` that sums
#'   to one. Its row sums equal the observed class proportions.
#'
#' @inherit class_thresholds references
#' @export
#' @examples
#' sim <- simulate_label_noise(n = 500, seed = 1)
#' round(estimate_joint(sim, truth = given), 3)
estimate_joint <- function(x, ...) {
  inputs <- label_inputs(x, ...)
  joint_impl(as.integer(inputs$labels), inputs$pred_probs)
}

#' Noise transition matrices and class priors
#'
#' Derives from the estimated joint (see [estimate_joint()]) the
#' quantities used to characterise label noise (Northcutt et al., 2021,
#' Sec. 3.1). Both matrices are oriented with given labels in rows and true
#' labels in columns.
#'
#' @inheritParams class_thresholds
#' @return A list with
#'   * `joint`: the estimated joint distribution `P(given = i, true = j)`.
#'   * `prior_given`: observed class proportions `P(given = i)`.
#'   * `prior_true`: estimated true class proportions `P(true = j)`.
#'   * `noise_matrix`: `P(given = i | true = j)`; columns sum to one. The
#'     diagonal is the probability that an example of class `j` keeps its
#'     label.
#'   * `inverse_noise_matrix`: `P(true = j | given = i)`; rows sum to one.
#'     The diagonal is the probability that a label `i` is correct.
#'
#'   A class with an estimated true prior of zero has `NA` in its column of
#'   `noise_matrix`.
#'
#' @inherit class_thresholds references
#' @export
#' @examples
#' sim <- simulate_label_noise(n = 500, seed = 1)
#' nm <- noise_matrices(sim, truth = given)
#' round(nm$inverse_noise_matrix, 2)
noise_matrices <- function(x, ...) {
  inputs <- label_inputs(x, ...)
  noise_matrices_impl(joint_impl(as.integer(inputs$labels), inputs$pred_probs))
}

#' Estimate the number of label errors
#'
#' @description
#' Two estimators are available:
#'
#' * `"confident_joint"` (default) counts the examples in the off-diagonal
#'   cells of the uncalibrated confident joint, that is examples that are
#'   confident members of a class other than their given label, leaving out
#'   those whose most likely class is still their given label. This matches
#'   [find_label_issues()] with `filter_by = "confident_learning"`.
#' * `"calibrated"` multiplies the off-diagonal mass of the estimated joint
#'   by the number of examples (Northcutt et al., 2021, Sec. 3.2). Calibration
#'   assumes that examples not counted in the confident joint are
#'   mislabelled at the same rate as those counted.
#'
#' @inheritParams class_thresholds
#' @param method Estimator, see Description.
#' @return A single integer.
#'
#' @inherit class_thresholds references
#' @export
#' @examples
#' sim <- simulate_label_noise(n = 500, noise_rate = 0.2, seed = 1)
#' num_label_issues(sim, truth = given)
#' sum(sim$given != sim$true)
num_label_issues <- function(x, ..., method = c("confident_joint", "calibrated")) {
  method <- rlang::arg_match(method)
  inputs <- label_inputs(x, ...)
  y <- as.integer(inputs$labels)
  per_class <- issues_per_class(y, inputs$pred_probs, method)
  as.integer(sum(per_class))
}

# Implementation ------------------------------------------------------------

thresholds_impl <- function(y, probs) {
  k <- ncol(probs)
  counts <- tabulate(y, nbins = k)
  sums <- vapply(seq_len(k), function(j) sum(probs[y == j, j]), numeric(1))
  thresholds <- ifelse(counts > 0, sums / pmax(counts, 1), Inf)
  names(thresholds) <- colnames(probs)
  empty <- colnames(probs)[counts == 0]
  if (length(empty) > 0L) {
    cli::cli_warn(c(
      "Class{?es} {.val {empty}} {?has/have} no examples with that given label.",
      i = "No example will be estimated to truly belong to such a class."
    ))
  }
  thresholds
}

# Returns the confident joint counts and, for every example, the class it is
# a confident member of (NA when none).
confident_joint_impl <- function(y, probs) {
  k <- ncol(probs)
  thresholds <- thresholds_impl(y, probs)
  above <- sweep(probs, 2L, thresholds, `>=`)
  masked <- probs
  masked[!above] <- -Inf
  true_guess <- max.col(masked, ties.method = "first")
  true_guess[rowSums(above) == 0] <- NA_integer_

  counted <- !is.na(true_guess)
  counts <- table(
    factor(y[counted], levels = seq_len(k)),
    factor(true_guess[counted], levels = seq_len(k))
  )
  counts <- matrix(
    as.integer(counts),
    nrow = k,
    dimnames = list(given = colnames(probs), true = colnames(probs))
  )
  list(counts = counts, true_guess = true_guess, thresholds = thresholds)
}

calibrate_joint <- function(counts, y) {
  k <- nrow(counts)
  n_given <- tabulate(y, nbins = k)
  totals <- rowSums(counts)
  calibrated <- counts / ifelse(totals > 0, totals, 1) * n_given
  # Rows with no confident examples carry no evidence of noise.
  empty <- totals == 0
  calibrated[empty, ] <- 0
  diag(calibrated)[empty] <- n_given[empty]
  calibrated[] <- as.numeric(calibrated)
  calibrated
}

joint_impl <- function(y, probs) {
  counts <- confident_joint_impl(y, probs)$counts
  calibrated <- calibrate_joint(counts, y)
  calibrated / sum(calibrated)
}

noise_matrices_impl <- function(joint) {
  prior_given <- rowSums(joint)
  prior_true <- colSums(joint)
  noise <- sweep(joint, 2L, prior_true, `/`)
  noise[, prior_true == 0] <- NA_real_
  inverse <- sweep(joint, 1L, prior_given, `/`)
  list(
    joint = joint,
    prior_given = prior_given,
    prior_true = prior_true,
    noise_matrix = noise,
    inverse_noise_matrix = inverse
  )
}

# Estimated number of mislabelled examples for each given label.
issues_per_class <- function(y, probs, method) {
  cj <- confident_joint_impl(y, probs)
  k <- ncol(probs)
  if (method == "calibrated") {
    calibrated <- calibrate_joint(cj$counts, y)
    return(round(rowSums(calibrated) - diag(calibrated)))
  }
  off_diagonal <- !is.na(cj$true_guess) & cj$true_guess != y &
    max.col(probs, ties.method = "first") != y
  tabulate(y[off_diagonal], nbins = k)
}

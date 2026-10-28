#' Label quality scores
#'
#' @description
#' Scores how likely each given label is to be correct, from 0 (probably
#' wrong) to 1 (probably right). Scores depend only on the predicted
#' probabilities `p` of an example and its given label `y` (Kuan and
#' Mueller, 2022):
#'
#' * `"self_confidence"`: `p[y]`, the predicted probability of the given
#'   label.
#' * `"normalized_margin"`: `(p[y] - max(p[-y]) + 1) / 2`, the gap between
#'   the given label and the most likely other class, rescaled to `[0, 1]`.
#'   Low when another class is clearly preferred.
#' * `"confidence_weighted_entropy"`: `ratio / (1 + ratio)` with
#'   `ratio = p[y] / H(p)`, where `H` is the entropy of `p` divided by
#'   `log(K)`. Also low for examples whose predictions are spread over many
#'   classes, such as examples that belong to none of the classes.
#'
#' With `adjust = TRUE`, each class threshold `t` (see
#' [class_thresholds()]) is subtracted from the predicted probabilities
#' before scoring. This corrects for a classifier that systematically
#' favours some classes. The adjusted probabilities are
#' `(p - t + max(t)) / sum(p - t + max(t))`, which are non-negative and sum
#' to one.
#'
#' @inheritParams class_thresholds
#' @param method Scoring method, see Description.
#' @param adjust Adjust predicted probabilities by the class thresholds
#'   before scoring? Not available for `"confidence_weighted_entropy"`.
#'
#' @return A numeric vector with one score per example, in the order of
#'   `label_inputs(x, ...)$row_id`.
#'
#' @references
#' Kuan, J., & Mueller, J. (2022). Model-agnostic label quality scoring to
#' detect real-world label errors. *ICML DataPerf Workshop*.
#' \doi{10.5281/zenodo.18168246}
#'
#' @export
#' @examples
#' sim <- simulate_label_noise(n = 300, seed = 1)
#' scores <- label_quality_scores(sim, truth = given)
#' # Mislabelled examples get lower scores
#' tapply(scores, sim$given != sim$true, mean)
label_quality_scores <- function(x,
                                 ...,
                                 method = c("self_confidence", "normalized_margin", "confidence_weighted_entropy"),
                                 adjust = FALSE) {
  method <- rlang::arg_match(method)
  inputs <- label_inputs(x, ...)
  scores_impl(as.integer(inputs$labels), inputs$pred_probs, method, adjust)
}

scores_impl <- function(y, probs, method, adjust = FALSE) {
  if (adjust) {
    if (method == "confidence_weighted_entropy") {
      cli::cli_abort("{.code adjust = TRUE} is not available for {.val confidence_weighted_entropy}.")
    }
    probs <- adjust_probs(y, probs)
  }
  idx <- cbind(seq_along(y), y)
  p_given <- probs[idx]

  switch(
    method,
    self_confidence = p_given,
    normalized_margin = {
      others <- probs
      others[idx] <- -Inf
      (p_given - apply(others, 1L, max) + 1) / 2
    },
    confidence_weighted_entropy = {
      clipped <- pmax(probs, 1e-12)
      entropy <- -rowSums(clipped * log(clipped)) / log(ncol(probs))
      ratio <- p_given / pmax(entropy, 1e-12)
      ratio / (1 + ratio)
    }
  )
}

adjust_probs <- function(y, probs) {
  thresholds <- suppressWarnings(thresholds_impl(y, probs))
  # Classes without examples get no adjustment.
  thresholds[!is.finite(thresholds)] <- 0
  shifted <- sweep(probs, 2L, thresholds, `-`) + max(thresholds)
  shifted / rowSums(shifted)
}

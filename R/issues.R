#' Find examples with likely label errors
#'
#' @description
#' Flags examples whose given label is likely wrong, using one of the rank
#' and prune rules of confident learning (Northcutt et al., 2021, Sec. 3.2).
#' Every rule needs out-of-sample predicted probabilities, for example from
#' cross-validation.
#'
#' * `"prune_by_noise_rate"` (default): for every pair of given label `i`
#'   and true label `j`, the estimated number of examples in that cell of
#'   the joint (see [estimate_joint()]) is flagged among the examples
#'   labelled `i`, choosing those where `p[j] - p[i]` is largest.
#' * `"prune_by_class"`: for every given label `i`, the estimated number of
#'   mislabelled examples is flagged among the examples labelled `i`,
#'   choosing those with the lowest self-confidence `p[i]`.
#' * `"both"`: examples flagged by both rules above.
#' * `"confident_learning"`: examples in the off-diagonal cells of the
#'   confident joint (see [confident_joint()]).
#' * `"predicted_neq_given"`: examples whose most likely class differs from
#'   the given label. A simple baseline that ignores class imbalance.
#'
#' As in the cleanlab Python package, an example whose most likely class is
#' its given label is never flagged, whichever rule is used: the classifier
#' then offers no evidence against the label.
#'
#' Flagged examples are candidates for review, not proven errors:
#' ambiguous examples that genuinely fit several classes are flagged too.
#'
#' @inheritParams class_thresholds
#' @param filter_by Rule used to flag examples, see Description.
#' @param rank_by Label quality score reported in `label_quality`, see
#'   [label_quality_scores()]. Sort by it to review the most suspicious
#'   examples first.
#' @param frac_noise Fraction of the estimated number of label errors to
#'   flag, between 0 and 1. Only used by the `"prune_by_*"` and `"both"`
#'   rules. Lower values flag fewer, more certain examples.
#' @param min_examples_per_class The rules never flag so many examples of a
#'   given label that fewer than this number would remain unflagged.
#'
#' @return A [tibble][tibble::tibble] with one row per example, in the order
#'   of the input, and columns
#'   * `.row`: the row identifier (the `.row` of resampled predictions, or
#'     the position in the input);
#'   * `given`: the given label;
#'   * `predicted`: the class with the largest predicted probability;
#'   * `label_quality`: the label quality score chosen by `rank_by`;
#'   * `is_label_issue`: whether the example is flagged.
#'
#' @inherit class_thresholds references
#' @seealso [health_summary()] for a class-level overview.
#' @export
#' @examples
#' sim <- simulate_label_noise(n = 500, noise_rate = 0.1, seed = 1)
#' issues <- find_label_issues(sim, truth = given)
#' issues
#'
#' # Review the most suspicious examples first
#' flagged <- issues[issues$is_label_issue, ]
#' head(flagged[order(flagged$label_quality), ])
#'
#' # How well did it do on this simulation?
#' table(flagged = issues$is_label_issue, mislabelled = sim$given != sim$true)
find_label_issues <- function(x,
                              ...,
                              filter_by = c("prune_by_noise_rate", "prune_by_class", "both", "confident_learning", "predicted_neq_given"),
                              rank_by = c("self_confidence", "normalized_margin", "confidence_weighted_entropy"),
                              frac_noise = 1,
                              min_examples_per_class = 1) {
  filter_by <- rlang::arg_match(filter_by)
  rank_by <- rlang::arg_match(rank_by)
  check_fraction(frac_noise)
  check_count(min_examples_per_class)

  inputs <- label_inputs(x, ...)
  y <- as.integer(inputs$labels)
  probs <- inputs$pred_probs

  flagged <- flag_issues(y, probs, filter_by, frac_noise, min_examples_per_class)
  levs <- colnames(probs)

  tibble::tibble(
    .row = inputs$row_id,
    given = inputs$labels,
    predicted = factor(levs[max.col(probs, ties.method = "first")], levels = levs),
    label_quality = scores_impl(y, probs, rank_by),
    is_label_issue = flagged
  )
}

flag_issues <- function(y, probs, filter_by, frac_noise = 1, min_examples_per_class = 1) {
  # An example whose most likely class is its given label is never flagged.
  disagrees <- max.col(probs, ties.method = "first") != y
  if (filter_by == "predicted_neq_given") {
    return(disagrees)
  }

  cj <- confident_joint_impl(y, probs)
  if (filter_by == "confident_learning") {
    return(!is.na(cj$true_guess) & cj$true_guess != y & disagrees)
  }

  # calibrated / n is the joint, so n * joint is the calibrated count.
  to_flag <- calibrate_joint(cj$counts, y) * frac_noise
  diag(to_flag) <- 0

  flagged <- switch(
    filter_by,
    prune_by_class = prune_by_class(y, probs, to_flag, min_examples_per_class),
    prune_by_noise_rate = prune_by_noise_rate(y, probs, to_flag, min_examples_per_class),
    both = prune_by_class(y, probs, to_flag, min_examples_per_class) &
      prune_by_noise_rate(y, probs, to_flag, min_examples_per_class)
  )
  flagged & disagrees
}

prune_by_class <- function(y, probs, to_flag, min_keep) {
  flagged <- logical(length(y))
  for (i in seq_len(ncol(probs))) {
    members <- which(y == i)
    k <- min(round(sum(to_flag[i, ])), length(members) - min_keep)
    if (k <= 0) {
      next
    }
    self_conf <- probs[members, i]
    flagged[members[order(self_conf)[seq_len(k)]]] <- TRUE
  }
  flagged
}

prune_by_noise_rate <- function(y, probs, to_flag, min_keep) {
  flagged <- logical(length(y))
  for (i in seq_len(ncol(probs))) {
    members <- which(y == i)
    budget <- length(members) - min_keep
    if (budget <= 0) {
      next
    }
    picked <- logical(length(members))
    for (j in which(round(to_flag[i, ]) > 0)) {
      margin <- probs[members, j] - probs[members, i]
      k <- min(round(to_flag[i, j]), length(members))
      picked[order(margin, decreasing = TRUE)[seq_len(k)]] <- TRUE
    }
    if (sum(picked) > budget) {
      # Keep the flags on the least self-confident examples.
      self_conf <- probs[members, i]
      keep <- order(ifelse(picked, self_conf, Inf))[seq_len(budget)]
      picked <- logical(length(members))
      picked[keep] <- TRUE
    }
    flagged[members[picked]] <- TRUE
  }
  flagged
}

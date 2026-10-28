#' Summarise label health by class
#'
#' @description
#' Gives a dataset-level and class-level overview of label quality from the
#' estimated joint distribution of given and true labels (see
#' [noise_matrices()]):
#'
#' * an overall label health score, one minus the estimated share of
#'   mislabelled examples;
#' * for every class, the estimated number and share of mislabelled
#'   examples, and the noise rates;
#' * the pairs of classes that are most often confused with each other,
#'   which point to unclear class definitions or coding guidelines.
#'
#' @inheritParams num_label_issues
#' @param method Estimator of the number of label errors, see
#'   [num_label_issues()].
#'
#' @return An object of class `label_health`, a list with
#'   * `score`: the overall label health score;
#'   * `n`, `num_label_issues`: the number of examples and the estimated
#'     number of mislabelled examples;
#'   * `classes`: a tibble with one row per class, sorted from worst to
#'     best `label_quality`. `label_noise` is the estimated share of
#'     examples truly in the class that were given another label;
#'     `inverse_label_noise` the estimated share of examples given the
#'     label that truly belong to another class; `label_quality` is
#'     `1 - inverse_label_noise`.
#'   * `overlapping_classes`: a tibble of class pairs with the estimated
#'     number of examples confused in either direction, sorted from most to
#'     least confused. Pairs that are never confused are left out.
#'
#' @inherit class_thresholds references
#' @export
#' @examples
#' sim <- simulate_label_noise(n = 1000, noise_rate = 0.15, seed = 1)
#' health <- health_summary(sim, truth = given)
#' health
#' health$classes
health_summary <- function(x, ..., method = c("confident_joint", "calibrated")) {
  method <- rlang::arg_match(method)
  inputs <- label_inputs(x, ...)
  y <- as.integer(inputs$labels)
  probs <- inputs$pred_probs
  levs <- colnames(probs)
  n <- length(y)

  nm <- noise_matrices_impl(joint_impl(y, probs))
  issues <- issues_per_class(y, probs, method)
  n_given <- tabulate(y, nbins = length(levs))

  classes <- tibble::tibble(
    class = factor(levs, levels = levs),
    n = n_given,
    num_label_issues = as.integer(issues),
    label_issue_rate = ifelse(n_given > 0, issues / pmax(n_given, 1), NA_real_),
    label_noise = 1 - unname(diag(nm$noise_matrix)),
    inverse_label_noise = 1 - unname(diag(nm$inverse_noise_matrix)),
    label_quality = unname(diag(nm$inverse_noise_matrix))
  )
  classes <- classes[order(classes$label_quality), , drop = FALSE]

  structure(
    list(
      score = 1 - sum(issues) / n,
      n = n,
      num_label_issues = as.integer(sum(issues)),
      classes = classes,
      overlapping_classes = overlapping_classes(nm$joint, n)
    ),
    class = "label_health"
  )
}

overlapping_classes <- function(joint, n) {
  levs <- rownames(joint)
  pairs <- which(upper.tri(joint), arr.ind = TRUE)
  both <- joint[pairs] + joint[pairs[, c(2, 1), drop = FALSE]]
  out <- tibble::tibble(
    class_1 = factor(levs[pairs[, 1]], levels = levs),
    class_2 = factor(levs[pairs[, 2]], levels = levs),
    num_overlapping = as.integer(round(both * n)),
    joint_probability = both
  )
  out <- out[out$joint_probability > 0, , drop = FALSE]
  out[order(out$joint_probability, decreasing = TRUE), , drop = FALSE]
}

#' @export
print.label_health <- function(x, ..., n_classes = 10) {
  cli::cli_text("{.strong Label health}")
  cli::cli_bullets(c(
    "*" = "Overall score: {format(x$score, digits = 3)}",
    "*" = "Estimated label issues: {x$num_label_issues} of {x$n} example{?s}"
  ))
  shown <- utils::head(x$classes, n_classes)
  cli::cli_text("")
  cli::cli_text("Classes with the lowest label quality:")
  print(shown, n = n_classes)
  if (nrow(x$overlapping_classes) > 0L) {
    cli::cli_text("")
    cli::cli_text("Most confused class pairs:")
    print(utils::head(x$overlapping_classes, 5), n = 5)
  }
  invisible(x)
}

#' Simulate a classification dataset with label errors
#'
#' Generates true classes, given labels in which a share of examples have
#' been switched to another class at random, and predicted probabilities
#' from a softmax of noisy logits that favour the true class. Useful for
#' examples, teaching and checking how well the methods recover known
#' errors.
#'
#' @param n Number of examples.
#' @param n_classes Number of classes, at least two.
#' @param noise_rate Probability that an example's given label is switched
#'   to a different, uniformly chosen class.
#' @param signal How much the logit of the true class is raised. Larger
#'   values give a more accurate classifier.
#' @param prior Class probabilities of the true classes. Defaults to a
#'   moderately imbalanced distribution.
#' @param seed Optional random seed. The global random number generator is
#'   restored afterwards.
#'
#' @return A tibble in the yardstick convention with columns `true`,
#'   `given` (factors) and one `.pred_<class>` probability column per class.
#'
#' @export
#' @examples
#' sim <- simulate_label_noise(n = 10, seed = 42)
#' sim
simulate_label_noise <- function(n = 1000,
                                 n_classes = 4,
                                 noise_rate = 0.1,
                                 signal = 2,
                                 prior = NULL,
                                 seed = NULL) {
  check_count(n, min = 1)
  check_count(n_classes, min = 2)
  check_fraction(noise_rate)
  if (is.null(prior)) {
    prior <- rev(seq_len(n_classes))
  }
  if (length(prior) != n_classes || any(prior < 0) || sum(prior) <= 0) {
    cli::cli_abort("{.arg prior} must be {n_classes} non-negative numbers with a positive sum.")
  }
  if (!is.null(seed)) {
    # Leave the caller's random number stream untouched.
    old_seed <- if (exists(".Random.seed", globalenv())) get(".Random.seed", globalenv())
    on.exit(
      if (is.null(old_seed)) {
        rm(".Random.seed", envir = globalenv())
      } else {
        assign(".Random.seed", old_seed, envir = globalenv())
      },
      add = TRUE
    )
    set.seed(seed)
  }

  levs <- LETTERS[seq_len(n_classes)]
  if (n_classes > length(LETTERS)) {
    levs <- paste0("C", seq_len(n_classes))
  }
  true <- sample.int(n_classes, n, replace = TRUE, prob = prior)
  given <- true
  switched <- stats::runif(n) < noise_rate
  shift <- sample.int(n_classes - 1L, sum(switched), replace = TRUE)
  given[switched] <- (true[switched] + shift - 1L) %% n_classes + 1L

  logits <- matrix(stats::rnorm(n * n_classes), nrow = n)
  logits[cbind(seq_len(n), true)] <- logits[cbind(seq_len(n), true)] + signal
  probs <- exp(logits - apply(logits, 1L, max))
  probs <- probs / rowSums(probs)
  colnames(probs) <- paste0(".pred_", levs)

  tibble::as_tibble(cbind(
    tibble::tibble(
      true = factor(levs[true], levels = levs),
      given = factor(levs[given], levels = levs)
    ),
    as.data.frame(probs)
  ))
}

#' Standardise labels and predicted probabilities
#'
#' @description
#' `label_inputs()` converts the many ways of supplying given labels and
#' out-of-sample predicted probabilities into one validated object. Every
#' other function in labelnoise calls it, so anything accepted here is
#' accepted everywhere:
#'
#' * a label vector (factor, character or integer) plus a probability
#'   matrix or data frame in `pred_probs`;
#' * a data frame of predictions in the yardstick convention: a `truth`
#'   column and one `.pred_<level>` column per class (as returned by
#'   `tune::collect_predictions()` or `augment()`);
#' * a `tune_results` object from `tune::fit_resamples()` or
#'   `tune::tune_grid()` fitted with `control_resamples(save_pred = TRUE)`;
#' * an mlr3 `PredictionClassif` or `ResampleResult` with
#'   `predict_type = "prob"`;
#' * a caret `train` object fitted with `classProbs = TRUE` and
#'   `savePredictions = "final"` (or `"all"`).
#'
#' Predicted probabilities must be out-of-sample (for example from
#' cross-validation). In-sample probabilities from a model that has seen the
#' labels will hide most label errors.
#'
#' When an example has several out-of-sample predictions (repeated
#' cross-validation), its probabilities are averaged.
#'
#' Other packages can add methods for their own prediction objects. A method
#' should end by calling `label_inputs()` on a label vector and a probability
#' matrix.
#'
#' @param x Labels or an object holding labels and predicted probabilities.
#'   See Description.
#' @param ... Passed on to methods. For data frames, a tidyselect
#'   specification of the probability columns.
#' @param pred_probs A numeric matrix or data frame with one row per example
#'   and one column per class. Rows must sum to one. Columns are matched to
#'   labels by name when both have names, otherwise by position.
#' @param truth For data frames, the column holding the given labels.
#' @param row_id Integer identifiers returned in the `.row` column of
#'   [find_label_issues()]. Defaults to `seq_along(x)`.
#' @param parameters For `tune_results` with several candidate models, a
#'   one-row data frame of tuning parameters, such as the output of
#'   `tune::select_best()`.
#'
#' @return An object of class `labelnoise_inputs`: a list with `labels`
#'   (factor), `pred_probs` (numeric matrix with one column per level of
#'   `labels`) and `row_id` (integer).
#'
#' @export
#' @examples
#' labels <- factor(c("a", "b", "b", "a"))
#' probs <- matrix(
#'   c(0.9, 0.1,
#'     0.2, 0.8,
#'     0.7, 0.3,
#'     0.6, 0.4),
#'   ncol = 2, byrow = TRUE, dimnames = list(NULL, c("a", "b"))
#' )
#' label_inputs(labels, probs)
#'
#' # The yardstick convention
#' preds <- data.frame(class = labels, .pred_a = probs[, 1], .pred_b = probs[, 2])
#' label_inputs(preds, truth = class)
label_inputs <- function(x, ...) {
  UseMethod("label_inputs")
}

#' @rdname label_inputs
#' @export
label_inputs.labelnoise_inputs <- function(x, ...) {
  x
}

#' @rdname label_inputs
#' @export
label_inputs.default <- function(x, pred_probs, ..., row_id = NULL) {
  check_dots_empty_inputs(...)
  if (missing(pred_probs)) {
    cli::cli_abort(c(
      "{.arg pred_probs} is missing.",
      i = "Supply a matrix of out-of-sample predicted probabilities, one column per class."
    ))
  }
  if (!is.factor(x) && !is.character(x) && !is.numeric(x) && !is.logical(x)) {
    cli::cli_abort(
      "Can't use labels of class {.cls {class(x)}}. Supply a factor, character or integer vector."
    )
  }

  probs <- as_prob_matrix(pred_probs)
  n <- length(x)
  if (nrow(probs) != n) {
    cli::cli_abort(
      "{.arg pred_probs} has {nrow(probs)} row{?s}, but {n} label{?s} {?was/were} supplied."
    )
  }
  if (anyNA(x)) {
    cli::cli_abort("Labels must not contain missing values.")
  }

  labels <- match_labels(x, probs)
  probs <- labels$probs
  labels <- labels$labels

  probs <- check_probs(probs)

  if (is.null(row_id)) {
    row_id <- seq_len(n)
  }
  if (length(row_id) != n) {
    cli::cli_abort("{.arg row_id} must have one value per label.")
  }

  structure(
    list(labels = labels, pred_probs = probs, row_id = as.integer(row_id)),
    class = "labelnoise_inputs"
  )
}

#' @rdname label_inputs
#' @export
label_inputs.data.frame <- function(x, truth, ..., pred_probs = NULL) {
  if (!is.null(pred_probs)) {
    cli::cli_abort(c(
      "{.arg pred_probs} can't be used with a data frame.",
      i = "Select the probability columns through {.arg ...} instead."
    ))
  }
  truth <- rlang::enquo(truth)
  if (rlang::quo_is_missing(truth)) {
    cli::cli_abort(c(
      "{.arg truth} is missing.",
      i = "Name the column that holds the given labels, e.g. {.code truth = class}."
    ))
  }
  truth_col <- tidyselect::eval_select(truth, x, allow_rename = FALSE)
  if (length(truth_col) != 1L) {
    cli::cli_abort("{.arg truth} must select exactly one column.")
  }

  dots <- rlang::enquos(...)
  if (length(dots) == 0L) {
    prob_names <- grep("^\\.pred_", names(x), value = TRUE)
    prob_names <- setdiff(prob_names, ".pred_class")
    if (length(prob_names) == 0L) {
      cli::cli_abort(c(
        "Can't find probability columns.",
        i = "Name them in {.arg ...} or use the {.code .pred_<level>} convention."
      ))
    }
    prob_cols <- match(prob_names, names(x))
  } else {
    prob_cols <- tidyselect::eval_select(rlang::expr(c(!!!dots)), x, allow_rename = FALSE)
  }
  prob_cols <- setdiff(prob_cols, truth_col)

  probs <- as.matrix(x[prob_cols])
  colnames(probs) <- sub("^\\.pred_", "", colnames(probs))

  labels <- x[[truth_col]]
  row_id <- NULL
  if (".row" %in% names(x)) {
    row_id <- x[[".row"]]
    if (anyDuplicated(row_id)) {
      agg <- average_by_row(row_id, labels, probs)
      return(label_inputs(agg$labels, agg$probs, row_id = agg$row_id))
    }
  }
  label_inputs(labels, probs, row_id = row_id)
}

#' @rdname label_inputs
#' @export
label_inputs.tune_results <- function(x, ..., parameters = NULL) {
  check_dots_empty_inputs(...)
  rlang::check_installed("tune", reason = "to read resampled predictions.")

  if (!".predictions" %in% names(x)) {
    cli::cli_abort(c(
      "{.arg x} does not contain saved predictions.",
      i = "Refit with {.code control = tune::control_resamples(save_pred = TRUE)}."
    ))
  }
  preds <- tune::collect_predictions(x, summarize = TRUE, parameters = parameters)
  if (".config" %in% names(preds) && length(unique(preds$.config)) > 1L) {
    cli::cli_abort(c(
      "{.arg x} holds predictions for {length(unique(preds$.config))} candidate models.",
      i = "Pick one with {.code parameters = tune::select_best(x, metric = ...)}."
    ))
  }

  outcome <- tune::.get_tune_outcome_names(x)
  if (length(outcome) != 1L) {
    cli::cli_abort("Can't determine the outcome column of {.arg x}.")
  }
  n <- nrow(x$splits[[1]]$data)
  missing_rows <- setdiff(seq_len(n), preds$.row)
  if (length(missing_rows) > 0L) {
    cli::cli_abort(c(
      "{length(missing_rows)} of {n} rows have no out-of-sample prediction.",
      i = "Use a resampling scheme that predicts every row, such as {.fn rsample::vfold_cv}."
    ))
  }

  preds <- preds[order(preds$.row), , drop = FALSE]
  levs <- levels(preds[[outcome]])
  prob_names <- paste0(".pred_", levs)
  if (!all(prob_names %in% names(preds))) {
    cli::cli_abort(c(
      "Can't find class probabilities in the saved predictions.",
      i = "Fit a classification model that predicts probabilities."
    ))
  }
  probs <- as.matrix(preds[prob_names])
  colnames(probs) <- levs
  label_inputs(preds[[outcome]], probs, row_id = preds$.row)
}

#' @rdname label_inputs
#' @export
label_inputs.PredictionClassif <- function(x, ...) {
  check_dots_empty_inputs(...)
  probs <- x$prob
  if (is.null(probs)) {
    cli::cli_abort(c(
      "{.arg x} has no class probabilities.",
      i = "Set {.code learner$predict_type <- \"prob\"} before resampling."
    ))
  }
  truth <- x$truth
  row_id <- x$row_ids
  if (anyDuplicated(row_id)) {
    agg <- average_by_row(row_id, truth, probs)
    return(label_inputs(agg$labels, agg$probs, row_id = agg$row_id))
  }
  ord <- order(row_id)
  label_inputs(truth[ord], probs[ord, , drop = FALSE], row_id = row_id[ord])
}

#' @rdname label_inputs
#' @export
label_inputs.ResampleResult <- function(x, ...) {
  check_dots_empty_inputs(...)
  label_inputs(x$prediction(), ...)
}

#' @rdname label_inputs
#' @export
label_inputs.train <- function(x, ...) {
  check_dots_empty_inputs(...)
  preds <- x$pred
  if (is.null(preds)) {
    cli::cli_abort(c(
      "{.arg x} does not contain saved predictions.",
      i = "Refit with {.code trainControl(savePredictions = \"final\", classProbs = TRUE)}."
    ))
  }
  levs <- x$levels
  if (is.null(levs) || !all(levs %in% names(preds))) {
    cli::cli_abort(c(
      "Can't find class probabilities in the saved predictions.",
      i = "Refit with {.code trainControl(classProbs = TRUE)}."
    ))
  }

  # savePredictions = "all" keeps every candidate: keep the selected one.
  best <- x$bestTune
  if (!is.null(best) && all(names(best) %in% names(preds))) {
    keep <- rep(TRUE, nrow(preds))
    for (nm in names(best)) {
      keep <- keep & preds[[nm]] == best[[nm]]
    }
    preds <- preds[keep, , drop = FALSE]
  }

  n <- length(x$trainingData$.outcome)
  missing_rows <- setdiff(seq_len(n), preds$rowIndex)
  if (length(missing_rows) > 0L) {
    cli::cli_abort(c(
      "{length(missing_rows)} of {n} rows have no out-of-sample prediction.",
      i = "Use {.code trainControl(method = \"cv\")} or {.code \"repeatedcv\"}."
    ))
  }

  agg <- average_by_row(preds$rowIndex, preds$obs, as.matrix(preds[levs]))
  label_inputs(agg$labels, agg$probs, row_id = agg$row_id)
}

#' @export
print.labelnoise_inputs <- function(x, ...) {
  cli::cli_text(
    "{.cls labelnoise_inputs}: {length(x$labels)} example{?s}, ",
    "{nlevels(x$labels)} class{?es}"
  )
  invisible(x)
}

# Helpers ---------------------------------------------------------------

as_prob_matrix <- function(pred_probs) {
  if (is.data.frame(pred_probs)) {
    is_num <- vapply(pred_probs, is.numeric, logical(1))
    if (!all(is_num)) {
      cli::cli_abort("Every column of {.arg pred_probs} must be numeric.")
    }
    pred_probs <- as.matrix(pred_probs)
  }
  if (!is.matrix(pred_probs) || !is.numeric(pred_probs)) {
    cli::cli_abort("{.arg pred_probs} must be a numeric matrix or data frame.")
  }
  if (ncol(pred_probs) < 2L) {
    cli::cli_abort("{.arg pred_probs} must have at least two columns (classes).")
  }
  storage.mode(pred_probs) <- "double"
  rownames(pred_probs) <- NULL
  pred_probs
}

match_labels <- function(x, probs) {
  k <- ncol(probs)
  cols <- colnames(probs)

  if (is.factor(x) || is.character(x) || is.logical(x)) {
    if (is.logical(x)) {
      x <- factor(x, levels = c(FALSE, TRUE))
    }
    if (is.character(x)) {
      levs <- if (is.null(cols)) sort(unique(x)) else cols
      x <- factor(x, levels = levs)
    }
    levs <- levels(x)
    if (is.null(cols)) {
      if (length(levs) != k) {
        cli::cli_abort(c(
          "Labels have {length(levs)} level{?s} but {.arg pred_probs} has {k} column{?s}.",
          i = "Name the columns of {.arg pred_probs} after the classes."
        ))
      }
      colnames(probs) <- levs
    } else {
      if (anyDuplicated(cols)) {
        cli::cli_abort("Column names of {.arg pred_probs} must be unique.")
      }
      unknown <- setdiff(as.character(unique(x)), cols)
      if (length(unknown) > 0L) {
        cli::cli_abort(
          "Label{?s} {.val {unknown}} {?has/have} no matching column in {.arg pred_probs}."
        )
      }
      # Keep the order of factor levels; classes only present as columns go last.
      levs <- c(intersect(levs, cols), setdiff(cols, levs))
      probs <- probs[, levs, drop = FALSE]
      x <- factor(as.character(x), levels = levs)
    }
    return(list(labels = x, probs = probs))
  }

  # Integer labels index the columns of pred_probs.
  if (any(x != round(x))) {
    cli::cli_abort("Numeric labels must be whole numbers indexing the columns of {.arg pred_probs}.")
  }
  if (min(x) == 0 && max(x) <= k - 1) {
    cli::cli_abort(c(
      "Numeric labels must be 1-based column indices, but a label is 0.",
      i = "Zero-based labels (as in Python) can be converted with {.code labels + 1}."
    ))
  }
  if (min(x) < 1 || max(x) > k) {
    cli::cli_abort("Numeric labels must lie between 1 and {k}, the number of columns of {.arg pred_probs}.")
  }
  if (is.null(cols)) {
    cols <- as.character(seq_len(k))
    colnames(probs) <- cols
  }
  list(labels = factor(cols[x], levels = cols), probs = probs)
}

check_probs <- function(probs, tol = 1e-3) {
  if (anyNA(probs)) {
    cli::cli_abort("{.arg pred_probs} must not contain missing values.")
  }
  if (any(probs < -tol) || any(probs > 1 + tol)) {
    cli::cli_abort("{.arg pred_probs} must lie between 0 and 1.")
  }
  sums <- rowSums(probs)
  bad <- which(abs(sums - 1) > tol)
  if (length(bad) > 0L) {
    cli::cli_abort(c(
      "Each row of {.arg pred_probs} must sum to 1.",
      x = "{length(bad)} row{?s} {?does/do} not, e.g. row {bad[1]} sums to {format(sums[bad[1]], digits = 4)}."
    ))
  }
  # Remove rounding error so downstream logs and ratios are well defined.
  probs <- pmin(pmax(probs, 0), 1)
  probs / rowSums(probs)
}

average_by_row <- function(row_id, labels, probs) {
  labels <- as.factor(labels)
  ids <- sort(unique(row_id))
  idx <- match(row_id, ids)
  first <- match(seq_along(ids), idx)
  given <- labels[first]
  conflict <- labels != given[idx]
  if (any(conflict)) {
    cli::cli_abort("The same row has different given labels across predictions.")
  }
  counts <- tabulate(idx, nbins = length(ids))
  summed <- rowsum(probs, idx, reorder = TRUE)
  list(
    labels = given,
    probs = summed / counts,
    row_id = ids
  )
}

check_dots_empty_inputs <- function(...) {
  if (...length() > 0L) {
    cli::cli_abort(c(
      "{.arg ...} must be empty.",
      i = "Check for misspelled argument names."
    ))
  }
}

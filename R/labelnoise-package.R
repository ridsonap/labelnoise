#' @keywords internal
"_PACKAGE"

check_fraction <- function(x, arg = rlang::caller_arg(x), call = rlang::caller_env()) {
  if (!is.numeric(x) || length(x) != 1L || is.na(x) || x < 0 || x > 1) {
    cli::cli_abort("{.arg {arg}} must be a single number between 0 and 1.", call = call)
  }
  invisible(x)
}

check_count <- function(x, min = 0, arg = rlang::caller_arg(x), call = rlang::caller_env()) {
  if (!is.numeric(x) || length(x) != 1L || is.na(x) || x < min || x != round(x)) {
    cli::cli_abort("{.arg {arg}} must be a single whole number of at least {min}.", call = call)
  }
  invisible(x)
}

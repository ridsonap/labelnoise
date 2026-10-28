# Package index

## Find label issues

- [`find_label_issues()`](https://ridsonap.is-a.dev/labelnoise/reference/find_label_issues.md)
  : Find examples with likely label errors
- [`label_quality_scores()`](https://ridsonap.is-a.dev/labelnoise/reference/label_quality_scores.md)
  : Label quality scores
- [`health_summary()`](https://ridsonap.is-a.dev/labelnoise/reference/health_summary.md)
  : Summarise label health by class

## Confident learning estimates

The quantities behind the label issues: per-class thresholds, the
confident joint, the estimated joint distribution of given and true
labels, and the noise transition matrices.

- [`class_thresholds()`](https://ridsonap.is-a.dev/labelnoise/reference/class_thresholds.md)
  : Per-class confidence thresholds
- [`confident_joint()`](https://ridsonap.is-a.dev/labelnoise/reference/confident_joint.md)
  : The confident joint
- [`estimate_joint()`](https://ridsonap.is-a.dev/labelnoise/reference/estimate_joint.md)
  : Estimate the joint distribution of given and true labels
- [`noise_matrices()`](https://ridsonap.is-a.dev/labelnoise/reference/noise_matrices.md)
  : Noise transition matrices and class priors
- [`num_label_issues()`](https://ridsonap.is-a.dev/labelnoise/reference/num_label_issues.md)
  : Estimate the number of label errors

## Inputs

- [`label_inputs()`](https://ridsonap.is-a.dev/labelnoise/reference/label_inputs.md)
  : Standardise labels and predicted probabilities

## Simulation

- [`simulate_label_noise()`](https://ridsonap.is-a.dev/labelnoise/reference/simulate_label_noise.md)
  : Simulate a classification dataset with label errors

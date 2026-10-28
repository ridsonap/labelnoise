# Simulate a classification dataset with label errors

Generates true classes, given labels in which a share of examples have
been switched to another class at random, and predicted probabilities
from a softmax of noisy logits that favour the true class. Useful for
examples, teaching and checking how well the methods recover known
errors.

## Usage

``` r
simulate_label_noise(
  n = 1000,
  n_classes = 4,
  noise_rate = 0.1,
  signal = 2,
  prior = NULL,
  seed = NULL
)
```

## Arguments

- n:

  Number of examples.

- n_classes:

  Number of classes, at least two.

- noise_rate:

  Probability that an example's given label is switched to a different,
  uniformly chosen class.

- signal:

  How much the logit of the true class is raised. Larger values give a
  more accurate classifier.

- prior:

  Class probabilities of the true classes. Defaults to a moderately
  imbalanced distribution.

- seed:

  Optional random seed. The global random number generator is restored
  afterwards.

## Value

A tibble in the yardstick convention with columns `true`, `given`
(factors) and one `.pred_<class>` probability column per class.

## Examples

``` r
sim <- simulate_label_noise(n = 10, seed = 42)
sim
#> # A tibble: 10 × 6
#>    true  given .pred_A .pred_B .pred_C .pred_D
#>    <fct> <fct>   <dbl>   <dbl>   <dbl>   <dbl>
#>  1 D     D     0.245   0.0488  0.105   0.602  
#>  2 D     D     0.573   0.00980 0.118   0.300  
#>  3 A     A     0.241   0.110   0.369   0.280  
#>  4 C     C     0.0877  0.390   0.466   0.0560 
#>  5 B     B     0.0168  0.946   0.0319  0.00490
#>  6 B     B     0.224   0.571   0.0213  0.183  
#>  7 C     C     0.141   0.145   0.631   0.0832 
#>  8 A     A     0.0969  0.0320  0.0797  0.791  
#>  9 B     B     0.00695 0.934   0.00714 0.0518 
#> 10 C     C     0.270   0.0380  0.553   0.139  
```

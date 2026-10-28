# labelnoise: Find Label Errors in Classification Data with Confident Learning

Finds examples whose given class label is likely wrong, using
out-of-sample predicted probabilities from any classifier. Implements
confident learning (Northcutt, Jiang and Chuang, 2021)
[doi:10.1613/jair.1.12125](https://doi.org/10.1613/jair.1.12125) :
per-class confidence thresholds, the confident joint, calibrated
estimates of the joint distribution of given and true labels, noise
transition matrices, and five rank-and-prune rules for flagging label
issues. Also provides model-agnostic label quality scores (Kuan and
Mueller, 2022)
[doi:10.5281/zenodo.18168246](https://doi.org/10.5281/zenodo.18168246)
and a per-class label health summary. Inputs can be a label vector with
a probability matrix, a data frame of predictions, resampling results
from 'tune', predictions from 'mlr3', or a fitted 'caret' model.

## See also

Useful links:

- <https://github.com/ridsonap/labelnoise>

- Report bugs at <https://github.com/ridsonap/labelnoise/issues>

## Author

**Maintainer**: Ridson Al Farizal P <ridsonalfarizal15@gmail.com>
([ORCID](https://orcid.org/0000-0003-0617-0214)) \[copyright holder\]

Authors:

- Ridson Al Farizal P <ridsonalfarizal15@gmail.com>
  ([ORCID](https://orcid.org/0000-0003-0617-0214)) \[copyright holder\]

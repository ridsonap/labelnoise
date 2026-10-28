"""Generate reference outputs from the Python cleanlab package.

cleanlab is used only as a black-box oracle through its public API; no code
is translated from it. Run from the package root:

    python -I data-raw/make-fixtures.py

Writes CSV files to tests/testthat/fixtures/. Labels are written 1-based.
"""

import csv
import pathlib
import warnings

import numpy as np
import cleanlab
from cleanlab.count import (
    compute_confident_joint,
    estimate_joint,
    estimate_py_and_noise_matrices_from_probabilities,
    num_label_issues,
)
from cleanlab.filter import find_label_issues
from cleanlab.rank import get_label_quality_scores

warnings.filterwarnings("ignore")
OUT = pathlib.Path("tests/testthat/fixtures")
OUT.mkdir(parents=True, exist_ok=True)

DATASETS = {
    "k4": dict(seed=1, n=400, k=4, noise=0.15, signal=2.0, prior=[0.4, 0.3, 0.2, 0.1]),
    "k6": dict(seed=2, n=1000, k=6, noise=0.20, signal=1.5, prior=[0.35, 0.25, 0.15, 0.1, 0.1, 0.05]),
    "k3": dict(seed=3, n=150, k=3, noise=0.10, signal=3.0, prior=[0.5, 0.3, 0.2]),
}
FILTERS = ["prune_by_noise_rate", "prune_by_class", "both", "confident_learning", "predicted_neq_given"]


def simulate(seed, n, k, noise, signal, prior):
    rng = np.random.default_rng(seed)
    y_true = rng.choice(k, size=n, p=prior)
    labels = y_true.copy()
    flip = rng.random(n) < noise
    labels[flip] = (y_true[flip] + rng.integers(1, k, flip.sum())) % k
    logits = rng.normal(0, 1, (n, k))
    logits[np.arange(n), y_true] += signal
    probs = np.exp(logits) / np.exp(logits).sum(1, keepdims=True)
    return y_true, labels, probs


def save(name, what, arr):
    np.savetxt(OUT / f"{name}-{what}.csv", np.atleast_2d(arr), delimiter=",", fmt="%.17g")


for name, spec in DATASETS.items():
    y_true, labels, probs = simulate(**spec)
    save(name, "probs", probs)
    save(name, "labels", labels + 1)
    save(name, "true", y_true + 1)
    save(name, "cj-raw", compute_confident_joint(labels, probs, calibrate=False))
    save(name, "cj-calibrated", compute_confident_joint(labels, probs, calibrate=True))
    save(name, "joint", estimate_joint(labels, probs))
    py, nm, inm, _ = estimate_py_and_noise_matrices_from_probabilities(labels, probs)
    save(name, "noise-matrix", nm)
    save(name, "inverse-noise-matrix", inm)
    columns = {}
    for method in ["self_confidence", "normalized_margin", "confidence_weighted_entropy"]:
        for adjust in [False, True]:
            if adjust and method == "confidence_weighted_entropy":
                continue
            key = method + ("-adjusted" if adjust else "")
            columns["score-" + key] = get_label_quality_scores(
                labels, probs, method=method, adjust_pred_probs=adjust
            )
    for f in FILTERS:
        columns["issue-" + f] = find_label_issues(labels, probs, filter_by=f, n_jobs=1).astype(int)
    with open(OUT / f"{name}-oracle.csv", "w", newline="") as fh:
        writer = csv.writer(fh)
        writer.writerow(columns.keys())
        for row in zip(*columns.values()):
            writer.writerow([repr(float(v)) if isinstance(v, float) else int(v) for v in row])
    (OUT / f"{name}-num-label-issues.csv").write_text(f"{int(num_label_issues(labels, probs))}\n")

(OUT / "cleanlab-version.txt").write_text(cleanlab.__version__ + "\n")
print("cleanlab", cleanlab.__version__, "fixtures written to", OUT)

"""Optional figure rebuild. Requires matplotlib; reads independent-check CSV."""
from pathlib import Path
import csv
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
root = Path(__file__).resolve().parents[1]
with (root / "results" / "counterexample_ratios.csv").open(newline="") as f:
    rows = list(csv.DictReader(f))
fig, ax = plt.subplots(figsize=(7.1, 3.8))
for name, label in (("log", "Logarithm"), ("exp", "Exponential"), ("sqrt", "Square root"), ("reciprocal", "Reciprocal")):
    ax.plot([int(r["t"]) for r in rows], [abs(float(r[name + "_error_over_x2"])) for r in rows], marker="o", label=label)
ax.set_xlabel(r"$t=-\log x$ (so $x=e^{-t}\to0^+$)")
ax.set_ylabel(r"$|\mathrm{error}|/x^2$")
ax.set_title("Nonlinear boundary errors are not bounded multiples of $x^2$")
ax.legend(frameon=False)
ax.grid(True, alpha=0.25)
fig.tight_layout()
fig.savefig(root / "article" / "nonlinear-witness.pdf")
fig.savefig(root / "article" / "nonlinear-witness.png", dpi=150)

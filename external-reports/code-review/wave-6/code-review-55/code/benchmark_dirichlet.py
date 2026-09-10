"""Independent Python prototype timings; never a Wolfram/Mathics benchmark."""
import json
import platform
import statistics
import sys
import time
from dirichlet_jet import DirichletJet, dense_retained_pair_count

rows = []
for n in [64, 256, 1024, 4096]:
    a = DirichletJet.zeta(n)
    durations = []
    for _ in range(5):
        start = time.perf_counter()
        product = a.multiply(a)
        durations.append(time.perf_counter() - start)
    rows.append({"known_through": n,
                 "retained_pairs": dense_retained_pair_count(n),
                 "unfiltered_square_pairs": n * n,
                 "median_seconds": statistics.median(durations),
                 "minimum_seconds": min(durations),
                 "repetitions": 5,
                 "nonzero_output_coefficients": len(product.coefficients)})
print(json.dumps({"scope": "Independent exact-rational Python prototype only; input construction excluded",
                  "python": sys.version, "platform": platform.platform(), "results": rows}, indent=2))

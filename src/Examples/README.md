# Package examples

These Wolfram Language scripts demonstrate the maintained package. Each
loads the modular kernel using its own file location. Run them in a fresh
kernel: they assign example variables and helper definitions in the current
session.

| Script | Content |
| --- | --- |
| [Examples.wl](Examples.wl) | The two motivating questions, forward and inverse expansions, remainder properties, residuals, and numerical comparisons. |
| [Arithmetic.wl](Arithmetic.wl) | Ordinary arithmetic, held `SeriesNormalize`, precision propagation, and combinations of different inverse cores. |
| [SpecialFunctions.wl](SpecialFunctions.wl) | Bessel, Airy, zeta, and Lerch expansions with explicit finite-expression comparisons. |

From the repository root, run one script at a time:

```powershell
wolfram.exe -noinit -script src/Examples/Examples.wl
wolfram.exe -noinit -script src/Examples/Arithmetic.wl
wolfram.exe -noinit -script src/Examples/SpecialFunctions.wl
```

For interactive exploration, first load the package explicitly:

```wolfram
Get["src/Kernel/AsymptoticAnalysis.wl"];
```

Then evaluate selected expressions from a script. Its file-relative loading
statement uses `$InputFileName`, which is available during file loading but
need not identify the script when pasted into a notebook.
`SpecialFunctions.wl` calls `Exit` at the end,
returning a nonzero status when one of its checks fails; run that complete
script in a separate kernel. The other scripts are demonstrations, and their
printed output is not an aggregate test report.

For the analytic results demonstrated here, `Normal[s]` gives the retained
finite expression and `s["Remainder"]` exposes its remainder. Keep both when
assessing an approximation. Native-backend results have a separate contract;
see the guide's [native examples](../Documentation/UserGuide.md#native-backend-expansions).
Supported branches,
cutoff conventions, and the limits of residual and numerical checks are
explained in the [user guide](../Documentation/UserGuide.md).

See the [test directory](../Tests/README.md) and
[validation instructions](../../validation/README.md) for focused acceptance
checks. Return to the [package README](../README.md).

Mathics users should start with the [compatibility guide](../../docs/Mathics/COMPATIBILITY.md)
and its selected portable tests. The presence of an example script does not
establish that every example has passed on each supported interpreter.

# Empty-list mapping in Mathics

Mathics3 10.0.1 can invalidate the internal evaluation cache of an empty list
when `Map` visits it. A later use of the same list inside a numeric list can
terminate the interpreter with a Python `AssertionError`. This reproduces
without loading AsymptoticAnalysis:

```wl
b = {};
f /@ b;
{b, 2, 0}
```

Empty coefficient lists are valid and common in this package. For example,
truncating away the finite coefficient in a flat sector leaves an empty jet
with a finite error bound. A successful Fourier residual check similarly
returns an empty list of residual blocks. These empty lists must remain safe
to store, inspect, and combine with their numerical metadata.

`MathicsLists.wl` redirects `Map` references in package-private function
definitions to an adapter. It handles exactly the two-argument form with an
empty list by returning an empty list directly. In that case there are no
applications of the mapped function. The function expression and input retain
ordinary argument evaluation, including any effects of evaluating the function
expression itself. Nonempty lists, other expression heads, explicit level
specifications, options, and invalid argument forms delegate to ``System`Map``.

The installer holds every inspected symbol, including symbols with stored or
effectful values. Reapplying the installer leaves already redirected function
definitions unchanged. It does not replace public definitions, stored values,
or Mathics' ``System`Map``, and it does not modify the installed interpreter.
The official Wolfram kernel does not load this adapter.

The public regression checks cover flat-sector truncation, scalar
multiplication, polynomial observables, and differentiation, including separate
inner and omitted-sector remainders. They also cover Fourier coefficient
extraction and an independently composed residual with no nonzero blocks.

I'm trying to find an asymptotic expansion of a function containing irrational exponents in the form of a power series (which also might contain irrational exponents). It works correctly if I request only the leading term:

    Asymptotic[(1 + x + x^√2)^√2, x -> ∞]
    (* x^2 *)
But if I request more terms, unfortunately, it just returns the original function rather than a power series expansion:

    Asymptotic[(1 + x + x^√2)^√2, x -> ∞, SeriesTermGoal -> 7]
    (* (1 + x + x^√2)^√2 *)
So far, I had to write this function myself as a workaround for this problem:

    asymptotic[f_, n_] :=
      f - Nest[s |-> 
        s - (x^# Limit[s/x^#, x -> ∞] &)@Simplify@Limit[x D[s, x]/s, x -> ∞], f, n];

    asymptotic[(1 + x + x^√2)^√2, 7]
    (* x^2 + (13 - 9 √2)/12 x^(6 - 4 √2) + 
         (-1 + 2 √2/3) x^(5 - 3 √2) + (2 - √2) x^(3 - 2 √2) + 
         (1 - 1/√2) x^(4 - 2 √2) + √2 x^(2 - √2) + √2 x^(3 - √2) *)

It's obviously very limited because it cannot handle functions with more complicated asymptotics (such as a power series plus/times an additional exponential or logarithmic term).

Is there a better/simpler way to do this? Why can't the built-in [`Asymptotic`](https://reference.wolfram.com/language/ref/Asymptotic.html) handle these cases?

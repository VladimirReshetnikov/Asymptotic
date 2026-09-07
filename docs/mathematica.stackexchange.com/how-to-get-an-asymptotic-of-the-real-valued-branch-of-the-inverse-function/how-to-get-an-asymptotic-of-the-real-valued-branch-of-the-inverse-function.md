Consider function $f:\mathbb R^+\to\mathbb R^+$, defined as $f(x) = x + x^2\left(1 + \log x\right)$. I need to find an asymptotic approximation of its inverse function $f^{\small(-1)}\!:\mathbb R^+\to\mathbb R^+$, satisfying $f^{\small(-1)}\!\left(x + x^2\left(1 + \log x\right)\right)=x$, for $x\to0^+$. I made a few attempts:

    AsymptoticSolve[x + x^2 (1 + Log[x]) == y, {x}, y -> 0, Direction -> -1,
        Assumptions -> y > 0, SeriesTermGoal -> 2]

This returns unevaluated (I'm not sure if I use it correctly). Let's try to use `InverseFunction`:

    Series[InverseFunction[Function[x, x + x^2 (1 + Log[x])]][y], y -> 0,
        Assumptions -> y > 0, SeriesTermGoal -> 2]

    (* E^(-1 + ProductLog[-1, -E]) + y/(-1 + E^(-1 + ProductLog[-1, -E])) - 
        ((3 + 2 ProductLog[-1, -E]) y^2)/(2 (-1 + E^(-1 + ProductLog[-1, -E]))^3) + O[y]^3 *)
This is better. It's a correct asymptotic, but for a non-real branch of the inverse function. I'm interested in the real-valued branch. If we replace `Series` with `Asymptotic`, we get the same result, just without `O[y]^3` at the end.

Let's try to explicitly say the function is only defined for real arguments:

    Series[InverseFunction[Function[x, ConditionalExpression[x + x^2 (1 + Log[x]), Im[x] == 0]]][y], y -> 0,
        Assumptions -> y > 0, SeriesTermGoal -> 2]

    (* InverseFunction[Function[x, ConditionalExpression[x + x^2 (1 + Log[x]), Im[x] == 0]]][0] + 
        Undefined y + Undefined y^2 + O[y]^3 *)
Not helpful. If we replace `Series` with `Asymptotic`, we just get plain `Undefined`.

    InverseFunction[Function[x, ConditionalExpression[x + x^2 (1 + Log[x]), Im[x] == 0]]][y] + O[y]^3

    (* InverseFunction[Function[x, ConditionalExpression[x + x^2 (1 + Log[x]), Im[x] == 0]]][0] + 
        Undefined y + Undefined y^2 + O[y]^3 *)
The same.

    InverseSeries[x + x^2 (1 + Log[x]) + O[x]^3, y]

It returns unevaluated.

How do I get an asymptotic of the real-valued branch of $f^{\small(-1)}\!\left(y\right)$?

---
_Update_: An example from the documentation for [`ConditionalExpression`](https://reference.wolfram.com/language/ref/ConditionalExpression.html#58532008) that shows how to use it with [`InverseFunction`](https://reference.wolfram.com/language/ref/InverseFunction.html#87576981), which I tried to follow:
[![Example from ConditionalExpression documentation][1]][1]

---
_Update:_ Another class of elementary functions in asymptotic of whose inverses I'm interested in is similar to this: 

    Asymptotic[InverseFunction[ConditionalExpression[# + #^Sqrt[2], # >= 0] &][z], z -> 0,
        Assumptions -> z > 0, SeriesTermGoal -> 4]
Expected result:
$${\small\left(x\mapsto x+x^{\sqrt2}\right)^{(-1)}}(z)=z-z^{\small\unicode{x202f}\sqrt2}+{\small\sqrt2}\;z^{\small\unicode{x202f}2\unicode{x202f}\sqrt2-1}-\tfrac{6-\sqrt2}2\;z^{\small\unicode{x202f}3\unicode{x202f}\sqrt2-2}+\mathcal O\!\left(z^{\small\unicode{x202f}4\unicode{x202f}\sqrt2-3}\right)$$

  [1]: https://i.sstatic.net/solg5.png

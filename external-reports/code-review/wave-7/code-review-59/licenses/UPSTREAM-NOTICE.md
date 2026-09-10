# Upstream fixture provenance

`code/bootstrap_reference.py` manually transcribes the executable bodies of two
functions from `validation/build_standalone.py` in VladimirReshetnikov/Asymptotic,
commit `efa1aeec4845a9c35e140963a0333d0c9ec33b05`. Comments were shortened and an
independent decoding helper added. It is not a downloaded or byte-verified copy,
and the rest of the builder is not included. The patch and its anchors reproduce
two lines from `src/Kernel/CorePerturbation.wl` at the same snapshot.

The pinned repository LICENSE states:

MIT No Attribution License

Copyright 2026 Asymptotic Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy of this
software and associated documentation files (the "Software"), to deal in the Software
without restriction, including without limitation the rights to use, copy, modify,
merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR
THE USE OR OTHER DEALINGS IN THE SOFTWARE.

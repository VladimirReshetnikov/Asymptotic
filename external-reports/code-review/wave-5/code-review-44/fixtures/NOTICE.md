# Source-fragment provenance and license

`upstream_fragments.py` was manually transcribed from files read through the
GitHub connector at commit `8e859961d7d37f008b826f3a8cad406460271614` of
VladimirReshetnikov/Asymptotic:

* `validation/summarize_mathics_tests.py`: `reconcile`.
* `validation/build_proveit_pdfs.py`: `write_json`, `receipt_matches`,
  `recorder_inputs`, and the file-digest helper.
* `validation/sync_proveit_pdfs.py`: the mkstemp/write/fsync/replace subsequence
  of `sync_article`, wrapped as `sync_publish_fragment` for the fixture.

The complete programs were not fetched into a local checkout or executed.
Imports, exception declarations, and safe ordinary-POSIX fixture path adapters
are supplied locally. The synchronization fixture omits the real function's
validation and concurrency rechecks. Those checks do not restore the temporary
file's permissions; the article limits the witness to the publication sequence.
The recorder fixture uses the actual fetched parser on genuine TeX recorder
files. The ledger witness executes the writer with two stale in-memory states;
it is not a concurrent full-builder stress test.

The source repository's LICENSE at the reviewed commit reads:

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

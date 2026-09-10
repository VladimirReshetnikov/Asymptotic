# Preserved upstream source

`check_documentation.py` is the retrieved, unmodified UTF-8 source from:

- Repository: `VladimirReshetnikov/Asymptotic`
- Commit: `8cee870994f506b501bae3ea6bd4a3a7edb895c1`
- Path: `validation/check_documentation.py`
- Source URL: https://github.com/VladimirReshetnikov/Asymptotic/blob/8cee870994f506b501bae3ea6bd4a3a7edb895c1/validation/check_documentation.py

The repository distributes its source under MIT No Attribution (SPDX `MIT-0`);
its pinned license is at
https://github.com/VladimirReshetnikov/Asymptotic/blob/8cee870994f506b501bae3ea6bd4a3a7edb895c1/LICENSE.

The checker is preserved as evidence, not as the recommended implementation. It
intentionally demonstrates the N02/N03 defects on negative fixtures. Its imports
refer to repository modules not copied here; `tests/documentation_fixture.py`
supplies explicit deterministic substitutes only for the controlled experiments.
The emitted repair is in `code/check_documentation_candidate.py`, and the
integration patch is `code/documentation-candidate.patch`.

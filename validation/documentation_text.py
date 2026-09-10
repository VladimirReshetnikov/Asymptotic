"""Check encoding of maintained prose without changing imported source records."""

from pathlib import Path
import re


# These are UTF-8 punctuation bytes accidentally decoded as Windows-1252.
# Match complete known sequences; individual accented letters are legitimate.
_DAMAGED_PUNCTUATION = tuple(
    character.encode("utf-8").decode("cp1252")
    for character in "\u2013\u2014\u2018\u2019\u201c\u2026\u00a0"
)
_CONTROL = re.compile(r"[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]")


def check_text_encoding(paths: list[Path]) -> dict:
    """Report file/line diagnostics for invalid UTF-8 and recognizable damage."""
    errors = []
    unique_paths = sorted(set(paths))
    for path in unique_paths:
        raw = path.read_bytes()
        try:
            source = raw.decode("utf-8-sig")
        except UnicodeDecodeError as error:
            line = raw[:error.start].count(b"\n") + 1
            errors.append(f"{path}:{line}: invalid UTF-8 at byte {error.start}")
            continue
        # splitlines() treats some forbidden controls as line separators and
        # would remove them before they can be diagnosed.
        for line_number, line in enumerate(source.split("\n"), 1):
            if "\ufffd" in line:
                errors.append(f"{path}:{line_number}: Unicode replacement character")
            if any(sequence in line for sequence in _DAMAGED_PUNCTUATION):
                errors.append(f"{path}:{line_number}: misdecoded UTF-8 punctuation")
            if _CONTROL.search(line):
                errors.append(f"{path}:{line_number}: unexpected control character")
    if errors:
        raise AssertionError("Documentation encoding errors:\n" + "\n".join(errors))
    return {"FilesChecked": len(unique_paths), "EncodingErrors": 0}

"""Mask TeX line comments so cross-reference scans read only active text.

A ``%`` that is not escaped starts a comment running to the end of the line
under the standard catcodes. Comment bytes are replaced by spaces and line
boundaries are preserved, so line numbers in diagnostics stay valid. This is
not a TeX parser: verbatim environments, changed catcodes and macro-generated
definitions are outside its scope, and raw source bytes must still be used for
encoding and archive comparisons (wave-6 report 47 N03).
"""

from __future__ import annotations


def strip_tex_comments(text: str) -> str:
    """Return ``text`` with every unescaped ``%`` comment blanked out.

    Backslash parity decides whether a percent sign is escaped: ``\\%`` is a
    literal percent, while ``\\\\%`` is a control-symbol backslash followed by
    a comment start.
    """
    if not isinstance(text, str):
        raise TypeError("text must be a string")
    result: list[str] = []
    backslashes = 0
    comment = False
    for char in text:
        if char in "\r\n":
            result.append(char)
            comment = False
            backslashes = 0
        elif comment:
            result.append(" ")
        elif char == "%" and backslashes % 2 == 0:
            result.append(" ")
            comment = True
            backslashes = 0
        else:
            result.append(char)
            backslashes = backslashes + 1 if char == "\\" else 0
    return "".join(result)


def require(condition: bool, message: str) -> None:
    """Raise ``AssertionError`` unless ``condition`` holds.

    A bare ``assert`` is removed by ``python -O`` and ``-OO``; a documentation
    gate must stay active under every interpreter flag (wave-6 report 47 N02).
    """
    if not condition:
        raise AssertionError(message)

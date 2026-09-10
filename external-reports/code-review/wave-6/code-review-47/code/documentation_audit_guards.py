"""Narrow candidate guards for validation/check_documentation.py.

This is not a complete TeX parser. It masks ordinary TeX percent comments
under standard catcodes, preserving line boundaries. Existing macro, input-depth,
verbatim and catcode limitations are intentionally not claimed solved.
"""
from __future__ import annotations

def require(condition: bool, message: str) -> None:
    """A production gate must remain active under Python -O and -OO."""
    if not condition:
        raise AssertionError(message)

def strip_tex_comments(text: str) -> str:
    """Mask a standard TeX line comment, except an escaped percent sign.

    Backslash parity matters: \\% is an escaped percent, but two backslashes
    followed by percent start a comment after a control-symbol backslash.
    Spaces replace comment bytes to avoid inventing adjacent control words.
    Original source bytes must still be used for encoding/archive checks.
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

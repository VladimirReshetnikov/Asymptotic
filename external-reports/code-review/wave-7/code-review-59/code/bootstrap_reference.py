"""Manually transcribed audit fixture; NOT a downloaded repository file.

The two functions below reproduce executable_text and mathics_bootstrap from
VladimirReshetnikov/Asymptotic, validation/build_standalone.py, commit
 efa1aeec4845a9c35e140963a0333d0c9ec33b05.
Only these functions are exercised, not the repository's complete builder.
Upstream license: MIT-0. See ../licenses/UPSTREAM-NOTICE.md.
"""
import json


def executable_text(text: str) -> str:
    """Mask strings and nested comments before checking dependency tokens."""
    result = list(text)
    i, depth, quoted = 0, 0, False
    while i < len(text):
        if depth:
            if text.startswith("(*", i):
                result[i:i + 2] = "  "
                depth += 1
                i += 2
            elif text.startswith("*)", i):
                result[i:i + 2] = "  "
                depth -= 1
                i += 2
            else:
                result[i] = "\n" if text[i] == "\n" else " "
                i += 1
        elif quoted:
            result[i] = "\n" if text[i] == "\n" else " "
            if text[i] == "\\":
                if i + 1 >= len(text):
                    raise ValueError("Unterminated string escape")
                result[i + 1] = " "
                i += 2
            else:
                if text[i] == '"':
                    quoted = False
                i += 1
        elif text.startswith("(*", i):
            result[i:i + 2] = "  "
            depth = 1
            i += 2
        elif text[i] == '"':
            result[i] = " "
            quoted = True
            i += 1
        else:
            i += 1
    if depth or quoted:
        raise ValueError("Unterminated Wolfram comment or string")
    return "".join(result)


def mathics_bootstrap(source: str) -> str:
    code = executable_text(source)
    statements, start, depth = [], 0, 0
    i = 0
    while i < len(code):
        char = code[i]
        if code[i:i + 2] in {"/;", ";;"}:
            i += 2
            continue
        if char in "[{(":
            depth += 1
        elif char in "]})":
            depth -= 1
            if depth < 0:
                raise ValueError("Unbalanced Mathics bootstrap source")
        elif char == ";" and depth == 0:
            statements.append(source[start:i + 1])
            start = i + 1
        i += 1
    if depth:
        raise ValueError("Unbalanced Mathics bootstrap source")
    if code[start:].strip():
        statements.append(source[start:])
    quoted = ",\n".join(json.dumps(s, ensure_ascii=False) for s in statements)
    return ('If[StringContainsQ[$Version, "Mathics"], Scan[ToExpression, {\n'
            + quoted + '\n}]];')


def decode_statements(generated: str) -> list[str]:
    """Audit-only decoding helper; not part of the upstream fixture."""
    body = generated.split('Scan[ToExpression, {\n', 1)[1].rsplit('\n}]];', 1)[0]
    return json.loads('[' + body + ']')

import pytest
from apply_truncation_fix import OLD, NEW, patched_bytes

@pytest.mark.parametrize("newline", ["\n", "\r\n"])
def test_patch_preserves_line_endings(newline):
    before = ("before\n" + OLD + "\nafter\n").replace("\n", newline).encode()
    after = patched_bytes(before)
    assert after == ("before\n" + NEW + "\nafter\n").replace("\n", newline).encode()

@pytest.mark.parametrize("source", ["wrong source", OLD + "\n" + OLD, NEW])
def test_mismatched_or_repeated_patch_is_refused(source):
    with pytest.raises(ValueError, match="exactly one"):
        patched_bytes(source.encode())

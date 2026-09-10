"""Encoding regressions: readable Unicode, damaged punctuation, and raw bytes."""

from pathlib import Path
import tempfile
import unittest

from documentation_text import check_text_encoding


class DocumentationTextTests(unittest.TestCase):
    def test_unicode_and_windows_line_endings_remain_valid(self):
        with tempfile.TemporaryDirectory() as directory:
            page = Path(directory) / "guide.md"
            page.write_bytes("\ufeff# R\u00e9sum\u00e9 \u2014 \u03b1 \u2264 \u03b2\r\n\t\u4e2d\u6587 \u2018quote\u2019\r\n".encode("utf-8"))
            self.assertEqual(check_text_encoding([page, page]),
                             {"FilesChecked": 1, "EncodingErrors": 0})

    def test_actual_damaged_range_and_replacement_report_lines(self):
        with tempfile.TemporaryDirectory() as directory:
            page = Path(directory) / "validation.md"
            page.write_text("# Review\nPages 1\u00e2\u20ac\u201c12\nLost \ufffd\n", encoding="utf-8")
            with self.assertRaises(AssertionError) as failure:
                check_text_encoding([page])
            self.assertIn(f"{page}:2: misdecoded", str(failure.exception))
            self.assertIn(f"{page}:3: Unicode replacement", str(failure.exception))

    def test_invalid_bytes_and_hidden_controls_are_not_silently_repaired(self):
        with tempfile.TemporaryDirectory() as directory:
            invalid = Path(directory) / "invalid.md"
            control = Path(directory) / "control.tex"
            invalid.write_bytes(b"# Heading\nBad \xff\n")
            control.write_bytes(b"Line one\nHidden\x00value\nPage\x0bbreak\x0c\n")
            with self.assertRaises(AssertionError) as failure:
                check_text_encoding([invalid, control])
            self.assertIn(f"{invalid}:2: invalid UTF-8", str(failure.exception))
            self.assertIn(f"{control}:2: unexpected control", str(failure.exception))
            self.assertIn(f"{control}:3: unexpected control", str(failure.exception))
            self.assertEqual(invalid.read_bytes(), b"# Heading\nBad \xff\n")


if __name__ == "__main__":
    unittest.main()

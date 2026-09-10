"""Comment masking and optimization-proof gates for the documentation checker."""

import subprocess
import sys
import textwrap
import unittest

from documentation_tex import require, strip_tex_comments


class DocumentationTexTests(unittest.TestCase):
    def test_comments_are_blanked_and_line_structure_is_kept(self):
        source = "\\label{a} % \\label{hidden}\r\n\\ref{a}%\\ref{b}\n50\\% done \\\\% tail\n"
        masked = strip_tex_comments(source)
        self.assertEqual(masked.count("\n"), source.count("\n"))
        self.assertEqual(len(masked), len(source))
        self.assertIn("\\label{a}", masked)
        self.assertNotIn("hidden", masked)
        self.assertNotIn("\\ref{b}", masked)
        self.assertIn("50\\% done", masked)
        self.assertNotIn("tail", masked)

    def test_non_string_input_is_rejected(self):
        with self.assertRaises(TypeError):
            strip_tex_comments(b"%")

    def test_require_raises_and_passes(self):
        require(True, "unused")
        with self.assertRaisesRegex(AssertionError, "gate"):
            require(False, "gate")

    def test_require_survives_python_optimization(self):
        program = textwrap.dedent("""
            import sys
            sys.path.insert(0, sys.argv[1])
            from documentation_tex import require
            assert False, "a bare assert is removed by -O"
            try:
                require(False, "active")
            except AssertionError:
                sys.exit(3)
            sys.exit(0)
            """)
        from pathlib import Path
        here = str(Path(__file__).resolve().parent)
        completed = subprocess.run([sys.executable, "-O", "-c", program, here], capture_output=True)
        self.assertEqual(completed.returncode, 3, completed.stderr.decode("utf-8", "replace"))


if __name__ == "__main__":
    unittest.main()

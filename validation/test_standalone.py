"""Focused, offline checks for the generated single-file package builder.

Run with: python -m unittest discover -s validation -p test_standalone.py
All fixture sources and output artifacts live in temporary directories.
"""

from __future__ import annotations

from contextlib import redirect_stdout
import hashlib
import importlib.util
import io
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch


SPEC = importlib.util.spec_from_file_location(
    "standalone_builder_under_test", Path(__file__).with_name("build_standalone.py")
)
assert SPEC is not None and SPEC.loader is not None
builder = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(builder)


def load(name: str) -> str:
    return f'Get[FileNameJoin[{{$kernelDirectory, "{name}"}}]];\n'


class StandaloneBuilderTests(unittest.TestCase):
    def setUp(self) -> None:
        temporary = tempfile.TemporaryDirectory(prefix="standalone-builder-")
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.kernel = self.root / "src" / "Kernel"
        self.kernel.mkdir(parents=True)
        self.target = self.root / "AsymptoticAnalysis.wl"
        globals_patch = patch.multiple(
            builder, ROOT=self.root, KERNEL=self.kernel, TARGET=self.target
        )
        globals_patch.start()
        self.addCleanup(globals_patch.stop)
        self.entry()

    def write(self, name: str, text: str) -> None:
        (self.kernel / name).write_text(text, encoding="utf-8", newline="\n")

    def entry(self, body: str = "value = 1;\n") -> None:
        self.write(
            "AsymptoticAnalysis.wl",
            'BeginPackage["Fixture`"];\n'
            '$kernelDirectory = DirectoryName[$InputFileName];\n'
            + body
            + "EndPackage[];\n",
        )

    def build(self, check: bool = False) -> dict:
        with redirect_stdout(io.StringIO()):
            return builder.build(check=check)

    def test_inlining_preserves_early_and_nested_load_order(self) -> None:
        self.entry(
            "rootBefore = 1;\n"
            + load("ExactTermination.wl")
            + "rootMiddle = 2;\n"
            + load("Middle.wl")
            + load("Late.wl")
            + "rootAfter = 3;\n"
        )
        self.write("ExactTermination.wl", "early = 4;\n")
        self.write("Middle.wl", "middleBefore = 5;\n" + load("Nested.wl") + "middleAfter = 6;\n")
        self.write("Nested.wl", "nested = 7;\n")
        self.write("Late.wl", "late = 8;\n")
        data, sources = builder.assemble()
        self.assertEqual(sources, ["AsymptoticAnalysis.wl", "ExactTermination.wl", "Middle.wl", "Nested.wl", "Late.wl"])
        text = data.decode("utf-8")
        statements = ["rootBefore = 1;", "early = 4;", "rootMiddle = 2;", "middleBefore = 5;", "nested = 7;", "middleAfter = 6;", "late = 8;", "rootAfter = 3;"]
        self.assertEqual([text.index(s) for s in statements], sorted(text.index(s) for s in statements))
        self.assertNotIn("Get[", builder.executable_text(text))
        self.assertEqual(text.count('BeginPackage["Fixture`"];'), 1)
        self.assertEqual(text.count("EndPackage[];"), 1)

    def test_unknown_external_and_outside_dependencies_are_rejected(self) -> None:
        for source in (
            'Get["Other.wl"];',
            'Get["https://example.invalid/Other.wl"];',
            'Needs["Other`"];',
            'System`Get["Other.wl"];',
            'Get[FileNameJoin[{$kernelDirectory, "../Other.wl"}]];',
            'Get[FileNameJoin[{$kernelDirectory, "nested/Other.wl"}]];',
        ):
            with self.subTest(source=source):
                self.entry(source + "\n")
                with self.assertRaisesRegex(ValueError, "Unresolved load|outside"):
                    builder.assemble()

    def test_missing_companion_fails_without_replacing_existing_artifact(self) -> None:
        self.entry(load("Missing.wl"))
        self.target.write_bytes(b"previous usable artifact\n")
        with self.assertRaises(FileNotFoundError):
            self.build()
        self.assertEqual(self.target.read_bytes(), b"previous usable artifact\n")
        self.assertFalse(self.target.with_suffix(".wl.tmp").exists())

    def test_cycles_and_repeated_dependencies_are_rejected(self) -> None:
        for child in (load("AsymptoticAnalysis.wl"), load("Child.wl")):
            with self.subTest(child=child):
                self.entry(load("Child.wl"))
                self.write("Child.wl", child)
                with self.assertRaisesRegex(ValueError, "Repeated or cyclic"):
                    builder.assemble()
        self.entry(load("Child.wl") + load("Child.wl"))
        self.write("Child.wl", "value = 2;\n")
        with self.assertRaisesRegex(ValueError, "Repeated or cyclic"):
            builder.assemble()

    def test_dependency_text_in_nested_comments_and_strings_is_inert(self) -> None:
        text = (
            "(* outer comment\n(* nested comment\n"
            + load("CommentedOutMissing.wl")
            + "*)\nNeeds[\"NotAPackage`\"]; $InputFileName\n*)\n"
            + r'label = "escaped quote: \"; Get[ghost]; $Input; (* text *)";'
            + "\nrealValue = 19;\n"
        )
        self.entry(text)
        data, sources = builder.assemble()
        self.assertEqual(sources, ["AsymptoticAnalysis.wl"])
        self.assertIn(text.rstrip(), data.decode("utf-8"))
        masked = builder.executable_text(text)
        self.assertEqual(len(masked), len(text))
        self.assertEqual(masked.count("\n"), text.count("\n"))
        self.assertNotIn("Get", masked)
        self.assertNotIn("$Input", masked)
        self.assertIn("realValue = 19;", masked)

    def test_future_companion_location_and_runtime_file_dependencies_fail(self) -> None:
        self.entry(load("Child.wl"))
        for expression in (
            "origin = $InputFileName;", "origin = $Input;",
            "origin = $kernelDirectory;", 'Import["data.json"];',
            'OpenRead["data.wl"];', 'ReadList["data.wl"];',
            'URLRead["https://example.invalid/data"];',
        ):
            with self.subTest(expression=expression):
                self.write("Child.wl", expression + "\n")
                with self.assertRaisesRegex(ValueError, "file-dependent code in Child.wl"):
                    builder.assemble()

    def test_unterminated_comments_and_strings_are_rejected(self) -> None:
        for text in ('(* never closed', '"never closed', '"dangling escape\\'):
            with self.subTest(text=text):
                with self.assertRaisesRegex(ValueError, "Unterminated"):
                    builder.executable_text(text)

    def test_changed_entry_directory_setup_requires_review(self) -> None:
        self.write("AsymptoticAnalysis.wl", "value = 1;\n")
        with self.assertRaisesRegex(ValueError, "directory setup"):
            builder.assemble()

    def test_output_bytes_are_deterministic_utf8_lf_and_track_source_changes(self) -> None:
        self.entry(load("Child.wl"))
        self.write("Child.wl", 'label = "λ";\nvalue = 1;\n')
        first, sources = builder.assemble()
        second, repeated_sources = builder.assemble()
        self.assertEqual(first, second)
        self.assertEqual(sources, repeated_sources)
        self.assertIn('label = "λ";', first.decode("utf-8"))
        self.assertNotIn(b"\r", first)
        self.assertNotIn(str(self.root).encode("utf-8"), first)
        (self.kernel / "Child.wl").write_bytes('label = "λ";\r\nvalue = 1;\r\n'.encode("utf-8"))
        self.assertEqual(builder.assemble()[0], first)
        self.write("Child.wl", 'label = "λ";\nvalue = 2;\n')
        self.assertNotEqual(builder.assemble()[0], first)

    def test_freshness_check_is_read_only_and_reports_the_artifact_digest(self) -> None:
        result = self.build()
        before = self.target.read_bytes()
        mtime = self.target.stat().st_mtime_ns
        with patch.object(Path, "write_bytes", side_effect=AssertionError("check attempted a write")):
            checked = self.build(check=True)
        self.assertEqual(result, checked)
        self.assertEqual(checked["SHA256"], hashlib.sha256(before).hexdigest())
        self.assertEqual(checked["Bytes"], len(before))
        self.assertEqual(checked["SourceFiles"], 1)
        self.assertTrue(checked["MatchesSources"])
        self.assertEqual(self.target.stat().st_mtime_ns, mtime)

    def test_stale_or_missing_check_never_writes_an_artifact(self) -> None:
        with self.assertRaisesRegex(SystemExit, "stale"):
            self.build(check=True)
        self.assertFalse(self.target.exists())
        self.build()
        before = self.target.read_bytes()
        mtime = self.target.stat().st_mtime_ns
        self.entry("changedValue = 20;\n")
        with patch.object(Path, "write_bytes", side_effect=AssertionError("check attempted a write")):
            with self.assertRaisesRegex(SystemExit, "stale"):
                self.build(check=True)
        self.assertEqual(self.target.read_bytes(), before)
        self.assertEqual(self.target.stat().st_mtime_ns, mtime)
        self.assertFalse(self.target.with_suffix(".wl.tmp").exists())


    def test_mathics_bootstrap_defers_parsing_and_preserves_streaming_statements(self) -> None:
        self.entry('If[StringContainsQ[$Version, "Mathics"], '
                   'Get[FileNameJoin[{$kernelDirectory, "MathicsFixture.wl"}]]];\n')
        self.write("MathicsFixture.wl", 'Begin["Fixture`Mathics`"];\n'
                   'f[x_] := Module[{}, Print["a;b"]; x]; (* ; nested (* ; *) *)\n'
                   'End[];\n')
        data, sources = builder.assemble()
        text = data.decode("utf-8")
        code = builder.executable_text(text)
        self.assertEqual(sources, ["AsymptoticAnalysis.wl", "MathicsFixture.wl"])
        self.assertIn("Scan[ToExpression", code)
        self.assertNotIn("Module[", code)
        self.assertNotIn("Print[", code)
        self.assertNotIn("Get[", code)
        import json
        encoded = text.split("Scan[ToExpression, {\n", 1)[1].split("\n}]];", 1)[0]
        statements = json.loads("[" + encoded + "]")
        self.assertEqual(len(statements), 3)
        self.assertIn('Begin["Fixture`Mathics`"];', statements[0])
        self.assertIn('Print["a;b"]; x]', statements[1])
        self.assertIn('End[];', statements[2])

    def test_mathics_bootstrap_rejects_unbalanced_source(self) -> None:
        for text in ("f[x;", "f[x]];", "Module[{x}, x;", "f[x};", "<|a -> 1;", "g := (a -> 1|>;"):
            with self.subTest(text=text), self.assertRaisesRegex(ValueError, "Unbalanced"):
                builder.mathics_bootstrap(text)

    def test_mathics_bootstrap_keeps_association_statements_whole(self) -> None:
        # Wave-5/7 report 59 N02: a semicolon inside an association is not a
        # statement terminator, in ASCII, long-name and private-use spelling.
        import json
        for opening, closing in (("<|", "|>"), ("\\[LeftAssociation]", "\\[RightAssociation]"), ("", "")):
            source = (f'f := {opening}"k" -> 1; 2, "n" -> {opening}"m" -> (a; b){closing}{closing};\n'
                      'g := 3;\n')
            with self.subTest(opening=opening):
                encoded = builder.mathics_bootstrap(source).split('Scan[ToExpression, {\n', 1)[1].rsplit('\n}]];', 1)[0]
                statements = json.loads('[' + encoded + ']')
                self.assertEqual([statement.strip() for statement in statements],
                                 [line.strip() for line in source.splitlines()])

    def test_mathics_bootstrap_preserves_condition_and_span_operators(self) -> None:
        import json
        source = ('f[x_] /; x > 0 := x;\n'
                  'g[x_] := x /; x < 0;\n'
                  'span = 1;;3;\n'
                  'openSpan = 1;;;\n'
                  'h[x_] := Module[{}, x /; x > 0];\n')
        encoded = builder.mathics_bootstrap(source).split('Scan[ToExpression, {\n', 1)[1].rsplit('\n}]];', 1)[0]
        statements = json.loads('[' + encoded + ']')
        self.assertEqual([statement.strip() for statement in statements],
                         [line.strip() for line in source.splitlines()])


if __name__ == "__main__":
    unittest.main()

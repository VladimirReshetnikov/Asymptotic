"""Regression checks for documentation discovery and actual GFM links."""

from pathlib import Path
import tempfile
import unittest

from documentation_links import check_local_links, maintained_pages, markdown_targets


class DocumentationLinksTests(unittest.TestCase):
    def test_gfm_targets_and_code_exclusion(self):
        anchors, links = markdown_targets('''# A `code` heading!
# A `code` heading!
<a id="ExplicitAnchor"></a>
[balanced](file(1).md#part)
[reference][target]
![image](image.png)

[target]: other.md
```markdown
# Hidden heading
[not a link](missing.md)
```
''')
        self.assertEqual(anchors, {"a-code-heading", "a-code-heading-1", "ExplicitAnchor"})
        self.assertEqual(links, ["file(1).md#part", "other.md", "image.png"])

    def test_same_page_and_html_fragments_are_checked(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            page = root / "README.md"
            (root / "guide.html").write_text('<h2 id="present">Heading</h2>', encoding="utf-8")
            page.write_text("# Here\n[local](#here) [html](guide.html#present)", encoding="utf-8")
            self.assertEqual(check_local_links([page])["LocalFragments"], 2)
            page.write_text("[local](#absent) [html](guide.html#absent)", encoding="utf-8")
            with self.assertRaisesRegex(AssertionError, "Missing anchor") as failure:
                check_local_links([page])
            self.assertEqual(str(failure.exception).count("Missing anchor"), 2)

    def test_encoded_destinations_and_missing_images(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            page = root / "README.md"
            (root / "with space.md").write_text("# Target", encoding="utf-8")
            page.write_text("[ok](with%20space.md#target)", encoding="utf-8")
            self.assertEqual(check_local_links([page])["BrokenLocalLinks"], 0)
            page.write_text("![missing](absent.png)", encoding="utf-8")
            with self.assertRaisesRegex(AssertionError, "Missing destination"):
                check_local_links([page])

    def test_new_notes_and_review_waves_are_discovered(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            examples = ["docs/Mathics/NEW.md", "docs/development/NEW.md",
                        "external-reports/code-review/wave-4/README.md",
                        "external-reports/code-review/wave-4/code-review-28/README.md",
                        "docs/mathematica.stackexchange.com/question/snapshot.md"]
            for name in examples:
                path = root / name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.touch()
            found = maintained_pages(root)
            for name in examples[:3]:
                self.assertIn(root / name, found)
            for name in examples[3:]:
                self.assertNotIn(root / name, found)


if __name__ == "__main__":
    unittest.main()

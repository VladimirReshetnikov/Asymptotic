import unittest
from ci_inventory import discover_cases, workflow_shards, verify_partition

class InventoryTests(unittest.TestCase):
    def test_whitespace_and_nested_comments(self):
        text = '''(* portableTest["fake", "g", 0, 0]; (* nested *) *)
        portableTest["a", "forward", 1, 1];
portableTest[\n "b",(* comment *)"forward", 1, 1];
portableTest["c","forward",1,1];'''
        self.assertEqual(discover_cases(text), [("a", "forward"), ("b", "forward"), ("c", "forward")])

    def test_definition_and_strings_not_cases(self):
        text = '''portableTest[id_String, group_String, actual_, expected_] :=
If[id === selection, Print["portableTest[not a call]"]];
portableTest["a", "forward", Hold[foo[1]], 1];'''
        self.assertEqual(discover_cases(text), [("a", "forward")])

    def test_unclosed_comment_and_string_fail(self):
        for text in ['(* never closed', 'portableTest["unclosed']:
            with self.assertRaises(ValueError):
                discover_cases(text)

    def test_computed_registration_is_refused(self):
        with self.assertRaises(ValueError):
            discover_cases('portableTest[makeID[1], "forward", 1, 1];')

    def test_duplicate_id_is_refused(self):
        with self.assertRaises(ValueError):
            discover_cases('portableTest["a", "forward", 1, 1];portableTest["a", "inverse", 1, 1];')

    def test_matrix_reader(self):
        text = '''suite: [one, two]
 one) groups=(forward inverse) ;;
 two) groups=(loading) ;;'''
        self.assertEqual(workflow_shards(text), {"one": ("forward", "inverse"), "two": ("loading",)})

    def test_matrix_mismatch_refused(self):
        with self.assertRaises(ValueError):
            workflow_shards('suite: [one, two]\n one) groups=(forward) ;;')

    def test_new_group_missing(self):
        with self.assertRaises(ValueError):
            verify_partition([("a", "forward"), ("b", "recurrence")], {"one": ("forward",)})

    def test_exact_partition(self):
        self.assertTrue(verify_partition([("a", "forward"), ("b", "loading")],
                                        {"one": ("forward",), "two": ("loading",)})["exactly_once_per_entry"])

if __name__ == "__main__":
    unittest.main(verbosity=2)

"""Synthetic-anchor fixtures only. No real checkout or package is loaded."""
import unittest
from emit_affine_lerch_patch import START,END,EDITS,patch_text

def fixture():
    return 'untouched prefix\n'+START+'\n'+'\n'.join(x for x,_ in EDITS)+'\n];\n'+END+'unchanged suffix\n'

class PatchFixtureTests(unittest.TestCase):
    def test_expected_replacements(self):
        old=fixture(); new=patch_text(old)
        for a,b in EDITS: self.assertIn(b,new)
        self.assertTrue(new.startswith('untouched prefix\n'))
        self.assertTrue(new.endswith('unchanged suffix\n'))
    def test_duplicate_anchor_refused(self):
        old=fixture().replace(EDITS[0][0],EDITS[0][0]+'\n'+EDITS[0][0])
        with self.assertRaises(ValueError): patch_text(old)
    def test_changed_anchor_refused(self):
        old=fixture().replace(EDITS[2][0],'new upstream implementation')
        with self.assertRaises(ValueError): patch_text(old)
    def test_second_application_refused(self):
        with self.assertRaises(ValueError): patch_text(patch_text(fixture()))

if __name__=='__main__': unittest.main(verbosity=2)

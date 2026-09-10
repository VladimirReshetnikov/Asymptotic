import os
import sys
import unittest
from bounded_process import bounded_run

@unittest.skipUnless(os.name == "posix", "POSIX-only prototype")
class BoundedProcessTests(unittest.TestCase):
    def test_regular_output(self):
        r=bounded_run([sys.executable,"-c","print('ordinary result')"])
        self.assertEqual(r["Outcome"], "Exited")
        self.assertEqual(r["Output"].strip(), "ordinary result")
    def test_nonzero_exit(self):
        r=bounded_run([sys.executable,"-c","raise SystemExit(7)"])
        self.assertEqual((r["Outcome"],r["ExitCode"]), ("ExitError",7))
    def test_hard_timeout(self):
        r=bounded_run([sys.executable,"-c","import time; time.sleep(2)"],timeout=.05)
        self.assertEqual(r["Outcome"], "Timeout")
    def test_output_cap(self):
        r=bounded_run([sys.executable,"-c","import sys; sys.stdout.write('x'*200000)"],max_output_bytes=1024)
        self.assertEqual(r["Outcome"], "OutputLimit")
        self.assertEqual(r["CapturedBytes"], 1024)
        self.assertTrue(r["Truncated"])
    def test_launch_error(self):
        r=bounded_run(["/definitely/nonexistent/asymptotic-review-interpreter"])
        self.assertEqual(r["Outcome"], "LaunchError")

if __name__ == "__main__": unittest.main()

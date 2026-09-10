(* Deliberately invalid source fixture. Do NOT load as a package.
   Feed this file to the UPSTREAM run_mathics_tests.py using:
   --source /path/to/load_returns_failed.wl --case primitive-check-is-unpolluted
   The pinned runner can report Success for this selected primitive even though
   Get returned $Failed. After a load gate is added, it must exit nonzero.
   This is a regression specification, NOT a recorded runtime reproduction. *)
$Failed

(* Load the package and code/regression_checks.wl before TestReport on this file. *)
AsymptoticAudit`Private`$DeltaResults = AsymptoticAudit`RunChecks[];

VerificationTest[AsymptoticAudit`Private`$DeltaResults["C01-clean-domain-rejection"], True,
  TestID -> "C01-clean-domain-rejection"]

VerificationTest[AsymptoticAudit`Private`$DeltaResults["C02-polluted-domain-rejection"], True,
  TestID -> "C02-polluted-domain-rejection"]

VerificationTest[AsymptoticAudit`Private`$DeltaResults["C03-valid-domain-certificate"], True,
  TestID -> "C03-valid-domain-certificate"]

VerificationTest[AsymptoticAudit`Private`$DeltaResults["C04-valid-enclosure-contains-root"], True,
  TestID -> "C04-valid-enclosure-contains-root"]

VerificationTest[AsymptoticAudit`Private`$DeltaResults["C05-strict-endpoint-rejection"], True,
  TestID -> "C05-strict-endpoint-rejection"]

VerificationTest[AsymptoticAudit`Private`$DeltaResults["F01-sparse-exact-constant-product"], True,
  TestID -> "F01-sparse-exact-constant-product"]

VerificationTest[AsymptoticAudit`Private`$DeltaResults["F02-exact-zero-recognition"], True,
  TestID -> "F02-exact-zero-recognition"]

VerificationTest[AsymptoticAudit`Private`$DeltaResults["F03-uncertain-zero-not-annihilated"], True,
  TestID -> "F03-uncertain-zero-not-annihilated"]

VerificationTest[AsymptoticAudit`Private`$DeltaResults["B01-native-polynomial-agreement"], True,
  TestID -> "B01-native-polynomial-agreement"]

VerificationTest[AsymptoticAudit`Private`$DeltaResults["B02-native-logarithmic-agreement"], True,
  TestID -> "B02-native-logarithmic-agreement"]

Clear[AsymptoticAudit`Private`$DeltaResults];

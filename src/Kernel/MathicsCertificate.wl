(* Loaded only by Mathics, after the certificate implementation.
   Mathics 10 raises a Python IndexError when assigning to list[[-1]], even
   for a nonempty one-element list. The certificate history is nonempty at
   its update site. Its positive last index denotes exactly the same part.
   Preserve the original interval algorithm, options, and failure paths. *)

ClearAll[mathicsCertificateSetLast];
SetAttributes[mathicsCertificateSetLast, HoldAll];
(* Keep the helper inert until the transformation has finished, so replacing
   a held Set in a DownValue cannot execute that assignment during loading. *)
DownValues[InverseCertificate] = DownValues[InverseCertificate] /.
  HoldPattern[Set[Part[list_Symbol, -1], value_]] :>
    mathicsCertificateSetLast[list, value];
mathicsCertificateSetLast[list_Symbol, value_] := (list[[Length[list]]] = value);

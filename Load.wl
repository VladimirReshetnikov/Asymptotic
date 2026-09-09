(* ::Package:: *)
(* Convenience loader for the current main revision of AsymptoticInverse.
   For a fixed revision, use a commit-pinned AsymptoticInverse.wl URL with
   Get[URLRead[url, "Body"], Method -> "String"].
   SPDX-License-Identifier: MIT *)

With[{url = "https://raw.githubusercontent.com/VladimirReshetnikov/Asymptotic/main/AsymptoticInverse.wl"},
  With[{response = URLRead[url]},
    If[Head[response] === HTTPResponse && response["StatusCode"] === 200 &&
        StringQ[response["Body"]],
      Get[response["Body"], Method -> "String"],
      Message[Get::noopen, url]; $Failed]]]

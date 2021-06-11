let uuid_strings =
  [
    "deadbeef-dead-beef-dead-beef00000075"
  ; "deadbeef-dead-beef-dead-beef00000075-extra-characters"
  ; (* This valid uuid gets changed to lowercase when converted back to strings,
       this breaks UUID equality when comparing the the original with the one
       converted back to UUID *)
    "DEADBEEF-DEAD-BEEF-DEAD-BEEF00000075"
  ]

let non_uuid_strings =
  [
    ""
  ; "deadbeef"
  ; "deadbeef-dead-beef-dead-beef000000"
  ; "deadbeef-dead-beef-dead-beef0000007"
  ; "deadbeef-dead-beef-dead-beeffoobar75"
  ]

let uuid_arrays =
  [
    [|0; 1; 2; 3; 4; 5; 6; 7; 8; 9; 10; 11; 12; 13; 14; 15|]
  ; (* bytes after the 16th are ignored *)
    [|0; 1; 2; 3; 4; 5; 6; 7; 8; 9; 10; 11; 12; 13; 14; 15; 16|]
  ; [|0; 1; 2; 3; 4; 5; 6; 7; 8; 9; 10; 11; 12; 13; 14; 15; 16; 17|]
  ]

let non_uuid_arrays =
  [[|0|]; [|0; 1; 2; 3; 4; 5; 6; 7; 8; 9; 10; 11; 12; 13; 14|]]

type resource

let uuid_testable : (module Alcotest.TESTABLE with type t = resource Uuid.t) =
  Alcotest.testable Uuid.pp Uuid.equal

let pp_array arr =
  Printf.sprintf "[|%s|]"
    (Array.to_list arr |> List.map string_of_int |> String.concat "; ")

let roundtrip_tests testing_uuid =
  let expected = testing_uuid in
  let test_string () =
    let result = Uuid.(to_string testing_uuid |> of_string) in
    Alcotest.(check @@ uuid_testable)
      "Roundtrip string conversion" expected result
  in
  let test_array () =
    let result = Uuid.(int_array_of_uuid testing_uuid |> uuid_of_int_array) in
    Alcotest.(check @@ uuid_testable)
      "Roundtrip array conversion" expected result
  in
  [
    ("Roundtrip string conversion", `Quick, test_string)
  ; ("Roundtrip array conversion", `Quick, test_array)
  ]

let string_roundtrip_tests testing_string =
  let testing_uuid = Uuid.of_string testing_string in
  let test () =
    let expected = String.lowercase_ascii (String.sub testing_string 0 36) in
    let result = Uuid.to_string testing_uuid in
    Alcotest.(check string) "Roundtrip conversion" expected result
  in
  ( testing_string
  , ("Roundtrip conversion", `Quick, test) :: roundtrip_tests testing_uuid )

let array_roundtrip_tests testing_array =
  let testing_uuid = Uuid.uuid_of_int_array testing_array in
  let test () =
    let expected = Array.init 16 (fun i -> testing_array.(i)) in
    let result = Uuid.int_array_of_uuid testing_uuid in
    Alcotest.(check @@ array int) "Roundtrip conversion" expected result
  in
  ( pp_array testing_array
  , ("Roundtrip conversion", `Quick, test) :: roundtrip_tests testing_uuid )

let invalid_string_tests testing_string =
  let test () =
    Alcotest.(check @@ uuid_testable)
      "Must not be converted to UUID" Uuid.null
      (Uuid.of_string testing_string)
  in
  (testing_string, [("Fail to convert from string", `Quick, test)])

let invalid_array_tests testing_array =
  let test () =
    Alcotest.(check @@ uuid_testable)
      "Must not be converted to UUID" Uuid.null
      (Uuid.uuid_of_int_array testing_array)
  in
  (pp_array testing_array, [("Fail to convert from array", `Quick, test)])

let regression_tests =
  List.concat
    [
      List.map string_roundtrip_tests uuid_strings
    ; List.map array_roundtrip_tests uuid_arrays
    ; List.map invalid_string_tests non_uuid_strings
    ; List.map invalid_array_tests non_uuid_arrays
    ]

let () = Alcotest.run "Uuid" regression_tests

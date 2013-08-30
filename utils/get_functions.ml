open Big_int_convenience

let usage = "Usage: "^Sys.argv.(0)^" <elf file> (<output prefix> | -r) [<function names>]\n\
             Disassemble functions from a binary."

let rangeonly = ref false
let unroll = ref None
let speclist =
  ("-r", Arg.Set rangeonly,
   "Print ranges rather than disassembling functions.")
  ::("-unroll", Arg.Int (fun x -> unroll := Some x), "Unroll loops n times.")
  ::[]

let file = ref None
let prefix = ref ""
let names = ref []
let n = ref 0
let anon x =
  (match !n with
   | 0 -> file := Some x
   | 1 -> prefix := x
   | _ -> names := x :: !names
  );
  incr n
;;

Arg.parse speclist anon usage;
names := List.rev !names;
if !rangeonly && !prefix <> "" then
  names := !prefix :: !names;
if !file = None then (
  Arg.usage speclist usage;
  exit 1
);
if !prefix = "" then rangeonly := true

let p = Asmir.open_program (BatOption.get !file)
let ranges = Func_boundary.get_function_ranges p

let doit ranges = match !rangeonly with
  | true ->
      List.iter (fun (n,s,e) -> Printf.printf "%s\t0x%s 0x%s\n" n (~%s) (~%e)) ranges
  | false ->
    let names = match !names with
      | [] -> None
      | l -> Some l
    in
    let fs = Utils_common.get_functions ?names ?unroll:!unroll p in
    List.iter
      (fun (n,ir,_) ->
        let oc = open_out (!prefix ^ n ^ ".il") in
        let pp = new Pp.pp_oc oc in
        pp#ast_program ir;
        pp#close)
      fs
;;
let filter_range (s,_,_) =
  List.mem s !names

let ranges = if List.length !names > 0 then List.filter filter_range ranges else ranges;;

doit ranges

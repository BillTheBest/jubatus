(*
 Jubatus: Online machine learning framework for distributed environment
 Copyright (C) 2011,2012 Preferred Infrastructure and Nippon Telegraph and Telephone Corporation.

 This library is free software; you can redistribute it and/or
 modify it under the terms of the GNU Lesser General Public
 License as published by the Free Software Foundation; either
 version 2.1 of the License, or (at your option) any later version.

 This library is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 Lesser General Public License for more details.

 You should have received a copy of the GNU Lesser General Public
 License along with this library; if not, write to the Free Software
 Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
*)

open Stree

(* ints in enum should not be dup *)
let check_enum enum =
(*  let `Enum(name, members) = enum in * TODO *)
    ();;

let check_msg m =
(*  | `Message(n, fields) ->   TODO *)
    ();;

let check_ex _ = ();; (* TODO *)

exception Wrong_routing of string
exception Wrong_method of string
exception Bad_first_argv of string
exception Bad_rettype of string
exception Bad_cht_argv of string
exception Bad_decorators
exception Duplicate_method of string
exception Method_not_found of string

let rec make_decoration dec =
  match dec with
    | [(Routing(rt)) ; (Reqtype(rq)) ; (Aggtype(ag)) ] -> (rt, rq, ag)
(*  | hd::tl ->
      print_endline (Stree.decorator_to_string hd); make_decoration tl; *)
    | _ -> raise Bad_decorators;;

exception Too_much_argv of string

(* check they have valid decorators *)
let check_method m =
  let Method(rettype, name, argv, decorators) = m in

  (* To expand this, 
     use variadic template or add functions in src/common/mprpc/rpc_client.hpp *)
  if List.length argv > 4 then raise (Too_much_argv name);

  (* first argument of every method must be string *)
  let gettype field =
    let Field(_, t, _) = field in t (* FIXME: use record type here. *)
  in 
  if gettype (List.nth argv 0) <> String then raise (Bad_first_argv name);

  (* return type of every method must not be void due to pficommon *)
  if rettype = Void then raise (Bad_rettype name);

  let routing,_,_ = make_decoration decorators in

  match routing with
    | Cht(r) -> if gettype (List.nth argv 1) <> String then raise (Bad_cht_argv name);
    | _ -> ();;

let check_service methods =
  let s,l,g = List.fold_left
    (fun (save,load,get_status) meth ->
      let Method(rettype, name, argv, decorators) = meth in
      match name with
	|"save" when not save ->
	  (* TODO: check other features *)
	  (true,load,get_status);
	|"load" when not load -> (save,true,get_status);
	|"get_status" when not get_status -> (save,load,true);
	|"save" -> raise (Duplicate_method "save");
	|"load" -> raise (Duplicate_method "load");
	|"get_status" -> raise (Duplicate_method "get_status");
	|_ -> (save,load,get_status)
    )
    (false,false,false) methods
  in
  if not s then raise (Method_not_found "save");
  if not l then raise (Method_not_found "load");
  if not g then raise (Method_not_found "get_status");
    
  List.iter check_method methods;;

let check strees =
  let do_check = function
    | Typedef(n, t) -> ();
    | Enum(n, t)              -> check_enum t;
    | Message(n, fields)      -> check_msg fields;
    | Exception(n, fields, s) -> check_ex fields;
    | Service(_, methods)     -> check_service methods
  in
  List.iter do_check strees;;

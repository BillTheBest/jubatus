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

open Util
open Stree

let to_impl_strings = function
  | Service(_, methods) ->
    let to_keeper_string m =
      let Method(rettype, name, argv, decorators) = m in
      let routing,rwtype,_ = Validator.make_decoration decorators in

      let rettype = Util.decl_type2string rettype in
      let sorted_argv = List.sort
	(fun lhs rhs -> let Field(l,_,_) = lhs in let Field(r,_,_) = rhs in l-r ) argv
      in
      let argv_strs = List.map
	(fun field -> let Field(_,t,n) = field in (decl_type2string t)^" "^n) sorted_argv
      in
      let argv_strs2 = List.map
	(fun field -> let Field(_,_,n) = field in n) (List.tl sorted_argv)
      in
      let lock_str = match rwtype with
	| Update   -> "JWLOCK__";
	| Analysis -> "JRLOCK__";
	| Nolock   -> "NOLOCK__"
      in
      
      (Printf.sprintf "\n  %s %s(%s) //%s %s"
	 rettype name (String.concat ", " argv_strs)
	 (Stree.reqtype_to_string rwtype) (Stree.routing_to_string routing))
      ^(Printf.sprintf "\n  { %s(p_); return p_->%s(%s); }" lock_str name (String.concat ", " argv_strs2))
	
    in
    List.map to_keeper_string methods;
  | _ -> [];;

let generate s output strees =
  output <<< Generator.comment;

  if s#internal then
    output <<< "#include \"../framework.hpp\""
  else
    output <<< "#include <jubatus/framework.hpp>";

  output <<< ("#include \""^s#basename^"_server.hpp\"");
  output <<< ("#include \""^s#basename^"_serv.hpp\"");
  output <<< ("using namespace "^s#namespace^";");
  output <<< "using namespace jubatus::framework;";

  output <<< "namespace jubatus { namespace server {";
(*  output <<< "using "^s#basename^"::server::"^s#basename^";"; no way!! *)
  output <<< ("class "^s#basename^"_impl_ : public "^s#basename^"<"^s#basename^"_impl_>");
  output <<< "{";
  output <<< "public:";
  output <<< ("  "^s#basename^"_impl_(const server_argv& a):");
  output <<< ("    "^s#basename^"<"^s#basename^"_impl_>(a.timeout),");
  output <<< ("    p_(new "^s#basename^"_serv(a))");

  let use_cht =
    let include_cht_api = function
      | Service(_, methods) ->
	let has_cht (Method(_,_,_,decs)) =
	  let rec has_cht_ = function
	    | [] -> false;
	    | Routing(Cht(_))::_ -> true;
	    | _::tl -> has_cht_ tl
	  in
	  has_cht_ decs
	in
	List.exists has_cht methods;
      | _ -> false
    in
    if List.exists include_cht_api strees then " p_->use_cht();"
    else ""
  in
  output <<< ("  {" ^ use_cht ^ "}");

  List.iter (fun l -> output <<< l)
    (List.flatten (List.map to_impl_strings
		     (List.filter Generator.is_service strees)));

  output <<< "  int run(){ return p_->start(*this); };";
  output <<< ("  common::cshared_ptr<"^s#basename^"_serv> get_p(){ return p_; };");
  output <<< "private:";
  output <<< ("  common::cshared_ptr<"^s#basename^"_serv> p_;");
  output <<< "};";
  output <<< "}} // namespace jubatus::server";

  output <<< "int main(int args, char** argv){";
  output <<< "  return";
  
  output <<< "    jubatus::framework::run_server<jubatus::server::"^s#basename^"_impl_,";
  output <<< "                                   jubatus::server::"^s#basename^"_serv>";
  output <<< "       (args, argv, \""^s#basename^"\");";
  output <<< "}";;

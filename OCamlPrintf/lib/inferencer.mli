(** Copyright 2024-2025, Friend-zva, RodionovMaxim05 *)

(** SPDX-License-Identifier: LGPL-3.0-or-later *)

type error =
  [ `No_variable of string
  | `Not_implemented
  | `Occurs_check
  | `Unification_failed of Ast.core_type * Ast.core_type
  ]

val pp_error : Format.formatter -> error -> unit

module R : sig
  type 'a t

  val return : 'a -> 'a t
  val fail : error -> 'a t
  val bind : 'a t -> f:('a -> 'b t) -> 'b t
  val ( >>= ) : 'a t -> ('a -> 'b t) -> 'b t
  val ( >>| ) : 'a t -> ('a -> 'b) -> 'b t

  module Syntax : sig
    val ( let* ) : 'a t -> ('a -> 'b t) -> 'b t
  end

  module RList : sig
    val fold_left : 'a list -> init:'b t -> f:('b -> 'a -> 'b t) -> 'b t
  end

  module RMap : sig
    val fold : ('a, 'b, 'c) Base.Map.t -> init:'d t -> f:('a -> 'b -> 'd -> 'd t) -> 'd t
  end

  val fresh : int t
  val run : 'a t -> ('a, error) result
end

module Type : sig
  type t = Ast.core_type

  val occurs_in : string -> Ast.core_type -> bool
  val free_vars : Ast.core_type -> TypedTree.VarSet.t
end

module Subst : sig
  type t = (string, Ast.core_type, Base.String.comparator_witness) Base.Map.t

  val empty : (string, 'a, Base.String.comparator_witness) Base.Map.t

  val singleton
    :  string
    -> Ast.core_type
    -> (string, Ast.core_type, Base.String.comparator_witness) Base.Map.t R.t

  val find : ('a, 'b, 'c) Base.Map.t -> 'a -> 'b option
  val remove : ('a, 'b, 'c) Base.Map.t -> 'a -> ('a, 'b, 'c) Base.Map.t
  val apply : (string, Ast.core_type, 'a) Base.Map.t -> Ast.core_type -> Ast.core_type

  val unify
    :  Ast.core_type
    -> Ast.core_type
    -> (string, Ast.core_type, Base.String.comparator_witness) Base.Map.t R.t

  val extend
    :  string
    -> Ast.core_type
    -> (string, Ast.core_type, Base.String.comparator_witness) Base.Map.t
    -> (string, Ast.core_type, Base.String.comparator_witness) Base.Map.t R.t

  val compose
    :  (string, Ast.core_type, Base.String.comparator_witness) Base.Map.t
    -> (string, Ast.core_type, Base.String.comparator_witness) Base.Map.t
    -> (string, Ast.core_type, Base.String.comparator_witness) Base.Map.t R.t

  val compose_all
    :  (string, Ast.core_type, Base.String.comparator_witness) Base.Map.t list
    -> (string, Ast.core_type, Base.String.comparator_witness) Base.Map.t R.t
end

module VarSet : sig
  type elt = string
  type t = TypedTree.VarSet.t

  val empty : t
  val is_empty : t -> bool
  val mem : elt -> t -> bool
  val add : elt -> t -> t
  val singleton : elt -> t
  val remove : elt -> t -> t
  val union : t -> t -> t
  val inter : t -> t -> t
  val disjoint : t -> t -> bool
  val diff : t -> t -> t
  val compare : t -> t -> int
  val equal : t -> t -> bool
  val subset : t -> t -> bool
  val iter : (elt -> unit) -> t -> unit
  val map : (elt -> elt) -> t -> t
  val fold : (elt -> 'a -> 'a) -> t -> 'a -> 'a
  val for_all : (elt -> bool) -> t -> bool
  val exists : (elt -> bool) -> t -> bool
  val filter : (elt -> bool) -> t -> t
  val filter_map : (elt -> elt option) -> t -> t
  val partition : (elt -> bool) -> t -> t * t
  val cardinal : t -> int
  val elements : t -> elt list
  val min_elt : t -> elt
  val min_elt_opt : t -> elt option
  val max_elt : t -> elt
  val max_elt_opt : t -> elt option
  val choose : t -> elt
  val choose_opt : t -> elt option
  val split : elt -> t -> t * bool * t
  val find : elt -> t -> elt
  val find_opt : elt -> t -> elt option
  val find_first : (elt -> bool) -> t -> elt
  val find_first_opt : (elt -> bool) -> t -> elt option
  val find_last : (elt -> bool) -> t -> elt
  val find_last_opt : (elt -> bool) -> t -> elt option
  val of_list : elt list -> t
  val to_seq_from : elt -> t -> elt Seq.t
  val to_seq : t -> elt Seq.t
  val to_rev_seq : t -> elt Seq.t
  val add_seq : elt Seq.t -> t -> t
  val of_seq : elt Seq.t -> t
  val pp : Format.formatter -> t -> unit
  val fold_left_m : ('a -> elt -> 'a R.t) -> t -> 'a R.t -> 'a R.t
end

module Scheme : sig
  type t = TypedTree.scheme

  val occurs_in : string -> TypedTree.scheme -> bool
  val free_vars : TypedTree.scheme -> VarSet.t

  val apply
    :  (string, Ast.core_type, 'a) Base.Map.t
    -> TypedTree.scheme
    -> TypedTree.scheme

  val pp : Format.formatter -> TypedTree.scheme -> unit
end

module TypeEnv : sig
  type t = (string, TypedTree.scheme, Base.String.comparator_witness) Base.Map.t

  val empty : (string, 'a, Base.String.comparator_witness) Base.Map.t
  val extend : ('a, 'b, 'c) Base.Map.t -> 'a -> 'b -> ('a, 'b, 'c) Base.Map.t
  val free_vars : ('a, TypedTree.scheme, 'b) Base.Map.t -> VarSet.t

  val apply
    :  (string, Ast.core_type, 'a) Base.Map.t
    -> ('b, TypedTree.scheme, 'c) Base.Map.t
    -> ('b, TypedTree.scheme, 'c) Base.Map.t

  val pp : Format.formatter -> ('a, string * TypedTree.scheme, 'b) Base.Map.t -> unit
  val find_exn : (string, 'a R.t, 'b) Base.Map.t -> string -> 'a R.t
end

module Infer : sig
  val unify
    :  Ast.core_type
    -> Ast.core_type
    -> (string, Ast.core_type, Base.String.comparator_witness) Base.Map.t R.t

  val fresh_var : Ast.core_type R.t
  val instantiate : TypedTree.scheme -> Ast.core_type R.t
  val generalize : TypeEnv.t -> Ast.core_type -> TypedTree.scheme

  val lookup_env
    :  string
    -> (string, TypedTree.scheme, 'a) Base.Map.t
    -> ((string, 'b, Base.String.comparator_witness) Base.Map.t * Ast.core_type) R.t

  val infer_pattern
    :  (string, TypedTree.scheme, 'a) Base.Map.t
    -> Ast.pattern
    -> ((string, TypedTree.scheme, 'a) Base.Map.t * Ast.core_type) R.t

  val infer_expression : TypeEnv.t -> Ast.Expression.t -> (Subst.t * Ast.core_type) R.t
  val infer_srtucture_item : TypeEnv.t -> Ast.structure_item list -> TypeEnv.t R.t

  val infer_value_binding_list
    :  TypeEnv.t
    -> (string, Ast.core_type, Base.String.comparator_witness) Base.Map.t
    -> Ast.Expression.t Ast.value_binding list
    -> TypeEnv.t R.t
end

val run_inferencer : Ast.structure_item list -> (TypeEnv.t, error) result
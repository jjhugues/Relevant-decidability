(**************************************************************)
(*   Copyright Dominique Larchey-Wendling [*]                 *)
(*                                                            *)
(*                             [*] Affiliation LORIA -- CNRS  *)
(**************************************************************)
(*      This file is distributed under the terms of the       *)
(*         CeCILL v2 FREE SOFTWARE LICENSE AGREEMENT          *)
(**************************************************************)

Require Import List.
Require Import Permutation.

Set Implicit Arguments.

(* Various Permutation results *)

Infix "~p" := (@Permutation _) (at level 80).

Section perm_t.

  Variable X : Type.

  Inductive perm_t : list X -> list X -> Type :=
    | perm_t_nil   : perm_t nil nil
    | perm_t_cons  : forall x l m, perm_t l m -> perm_t (x::l) (x::m)
    | perm_t_swap  : forall x y l, perm_t (x::y::l) (y::x::l)
    | perm_t_trans : forall l m k, perm_t l m -> perm_t m k -> perm_t l k.

  Fact perm_t_refl l : perm_t l l.
  Proof.
    induction l; simpl; constructor; auto.
  Qed.

  Fact perm_t_sym l m : perm_t l m -> perm_t m l.
  Proof.
    induction 1; try constructor; auto.
    apply perm_t_trans with m; auto.
  Qed.

  Fact perm_t_app a b l m : perm_t a b -> perm_t l m -> perm_t (a++l) (b++m).
  Proof.
    intros H1 H2.
    apply perm_t_trans with (a++m).
    clear H1.
    induction a; simpl; auto; constructor; auto.
    clear H2.
    induction H1; simpl; auto.
    apply perm_t_refl.
    constructor; auto.
    constructor.
    apply perm_t_trans with (m0++m); auto.
  Qed.

  Fact perm_t_exchg a x b y c : perm_t (a++x::b++y::c) (a++y::b++x::c).
  Proof.
    apply perm_t_app.
    apply perm_t_refl.
    replace (perm_t (x :: b ++ y :: c) (y :: b ++ x :: c))
    with (perm_t ((x::b++y::nil)++c) ((y::b++x::nil)++c)).
    apply perm_t_app.
    2: apply perm_t_refl.
    2: repeat (simpl; rewrite app_ass); auto.
    clear a c.
    revert x y; induction b as [ | u b IH ]; intros x y; simpl.
    constructor.
    apply perm_t_trans with (1 := perm_t_swap _ _ _).
    apply perm_t_trans with (2 := perm_t_swap _ _ _).
    constructor; auto.
  Qed.

  Fact perm_t_middle x l m : perm_t (x::l++m) (l++x::m).
  Proof.
    induction l as [ | y l IH ]; simpl.
    apply perm_t_refl.
    apply perm_t_trans with (1 := perm_t_swap _ _ _).
    constructor; auto.
  Qed.

  Fact perm_t_Permutation l m : perm_t l m -> l ~p m.
  Proof.
    induction 1; auto; try constructor.
    apply perm_trans with m; auto.
  Qed.

End perm_t.

Section Permutation_rect.

  Variable (X : Type) (dec : forall x y : X, { x = y } + { x <> y }) (P : list X -> list X -> Type).

  Definition In_split_dec (x : X) m : In x m -> { l : _ & { r | m = l++x::r } }.
  Proof.
    induction m as [ | y m IH ].
    intros [].
    destruct (dec x y) as [ E | C ].
    subst; exists nil, m; auto.
    intros H.
    destruct IH as (l & r & ?).
    destruct H as [ ? | ]; auto.
    contradict C; auto.
    exists (y::l), r; simpl; f_equal; auto.
  Qed.

  (* Permutation and perm_t are equivalent when equality is decidable
     on the base type *)

  Theorem Permutation_perm_t (l m : list X) : l ~p m -> perm_t l m.
  Proof.
    revert m; induction l as [ | x l IHl ]; intros m H.
    apply Permutation_nil in H; subst; auto.
    constructor.
    destruct (@In_split_dec x m) as (ll & rr & E).
    apply Permutation_in with (1 := H); left; auto.
    subst.
    apply perm_t_trans with (x::ll++rr).
    constructor.
    apply IHl; auto.
    apply Permutation_cons_app_inv in H; auto.
    apply perm_t_middle.
  Qed.

  (* we derive a Type recursion principle for Permutation when
     the base type is decidable *)

  Hypothesis (HP0 : P nil nil)
             (HP1 : forall x l m, l ~p m -> P l m -> P (x::l) (x::m))
             (HP2 : forall x y l, P (x::y::l) (y::x::l))
             (HP3 : forall l m k, l ~p m -> P l m -> m ~p k -> P m k -> P l k).

  Theorem Permutation_rect l m : l ~p m -> P l m.
  Proof.
    intros H.
    apply Permutation_perm_t in H.
    induction H; auto.
    apply HP1; auto.
    apply perm_t_Permutation; auto.
    apply HP3 with m; auto;
      apply perm_t_Permutation; auto.
  Qed.

End Permutation_rect.

Section Permutation_tools.

  Variable X : Type.

  Implicit Types (l : list X).

  Theorem Permutation_In_inv l1 l2: l1 ~p l2 -> forall x, In x l1 -> exists l, exists r, l2 = l++x::r.
  Proof.
    intros H x Hx.
    apply in_split.
    apply Permutation_in with (1 := H).
    auto.
  Qed.

  Fact perm_in_head x l : In x l -> exists m, l ~p x::m.
  Proof.
    induction l as [ | y l IHl ].
    destruct 1.
    intros [ ? | H ]; subst.
    exists l; apply Permutation_refl.
    destruct (IHl H) as (m & Hm).
    exists (y::m).
    apply Permutation_trans with (2 := perm_swap _ _ _).
    constructor 2; auto.
  Qed.

  Theorem Permutation_add_one l1 l2 a r1 r2 : l1++r1 ~p l2++r2 -> l1++a::r1 ~p l2++a::r2.
  Proof.
    intros H.
    apply Permutation_trans with (2 := Permutation_middle _ _ _).
    apply Permutation_sym.
    apply Permutation_trans with (2 := Permutation_middle _ _ _).
    apply Permutation_sym.
    auto.
  Qed.

  Hint Resolve Permutation_add_one : core.

  Theorem Permutation_app_intro l1 l2 k r1 r2 : l1++r1 ~p l2++r2 -> l1++k++r1 ~p l2++k++r2.
  Proof. induction k; auto; simpl;intro; auto. Qed.

  Theorem Permutation_simpl_middle l1 l2 k r1 r2 : l1++k++r1 ~p l2++k++r2 -> l1++r1 ~p l2++r2.
  Proof.
    induction k; auto.
    intros H; simpl in H.
    apply Permutation_app_inv in H.
    auto.
  Qed.

  Hypothesis eqX_dec : forall x y : X, { x = y } + { x <> y }.

  Theorem Permutation_dec l m : { l ~p m } + { ~ (l ~p m) }.
  Proof.
    revert m; induction l as [ | x l IHl ].
    intros [ | y m ].
    left; auto.
    right; intros C; apply Permutation_nil in C; discriminate.
    intros m.
    destruct (In_dec eqX_dec x m) as [ H | H ].
    assert { m1 : _ & { m2 | m = m1++x::m2 } } as E.
      induction m as [ | y m IHm ].
      destruct H.
      destruct (eqX_dec x y) as [ E | D ].
      subst; exists nil, m; simpl; auto.
      destruct IHm as (m1 & m2 & Hm).
      destruct H; auto; contradict D; auto.
      exists (y::m1), m2; simpl; f_equal; auto.
    clear H; destruct E as (m1 & m2 & E).
    destruct (IHl (m1++m2)) as [ H | H ].
    subst; left; apply Permutation_cons_app; auto.
    subst; right; contradict H.
    apply Permutation_cons_app_inv in H; auto.
    right; contradict H.
    apply Permutation_in with (1 := H); left; auto.
  Qed.

  Fact Permutation_cons_2_inv (x y : X) l m : x::l ~p y::m -> (x = y /\ l ~p m) \/ exists k, l ~p y::k /\ m ~p x::k.
  Proof.
    intros H.
    assert (In x (y::m)) as H1.
      apply Permutation_in with (1 := H); left; auto.
    destruct H1 as [ H1 | H1 ].
    subst x; left; split; auto; revert H; apply Permutation_cons_inv.
    assert (exists k, m ~p x::k) as Hk.
      apply in_split in H1.
      destruct H1 as (m1 & m2 & H1).
      exists (m1++m2); subst.
      apply Permutation_sym, Permutation_cons_app; auto.
    clear H1.
    destruct Hk as (k & Hk).
    right; exists k; split; auto.
    apply Permutation_trans with (2 := perm_skip _ Hk) in H.
    apply Permutation_trans with (2 := perm_swap _ _ _) in H.
    revert H; apply Permutation_cons_inv.
  Qed.

End Permutation_tools.

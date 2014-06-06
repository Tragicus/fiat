Require Import Ensembles List Coq.Lists.SetoidList Program
        Common Computation.Core
        ADTNotation.BuildADTSig ADTNotation.BuildADT
        GeneralBuildADTRefinements QueryQSSpecs QueryStructure
        SetEq Omega.
Require Export EnsembleListEquivalence.

Unset Implicit Arguments.

Ltac generalize_all :=
  repeat match goal with
             [ H : _ |- _ ] => generalize H; clear H
         end.

Section AdditionalDefinitions.
  Open Scope list_scope.

  Definition NonNil {A: Type} (l: list A) :=
    match l with
      | nil => false
      | _  => true
    end.

  Definition dec2bool {A: Type} {P: A -> Prop} (pred: forall (a: A), sumbool (P a) (~ (P a))) :=
    fun (a: A) =>
      match pred a with
        | left _  => true
        | right _ => false
      end. (* TODO: Use this *)

  Definition Box {A: Type} (x: A) := [x].

  Definition Option2Box {A: Type} (xo: option A) :=
    match xo with
      | Some x => [x]
      | None   => []
    end.

  Definition FilteredSet {A B} ensemble projection (value: B) :=
    fun (p: A) => ensemble p /\ projection p = value.

  Definition ObservationalEq {A B} f g :=
    forall (a: A), @eq B (f a) (g a).
End AdditionalDefinitions.

Section AdditionalNatLemmas.
  Lemma le_r_le_max : 
    forall x y z,
      x <= z -> x <= max y z.
  Proof.
    intros x y z;
    destruct (Max.max_spec y z) as [ (comp, eq) | (comp, eq) ]; 
    rewrite eq;
    omega.
  Qed.

  Lemma le_l_le_max : 
    forall x y z,
      x <= y -> x <= max y z.
  Proof.
    intros x y z. 
    rewrite Max.max_comm.
    apply le_r_le_max.
  Qed.
End AdditionalNatLemmas.

Section AdditionalLogicLemmas.
  Lemma or_false :
    forall (P: Prop), P \/ False <-> P.
  Proof.
    tauto.
  Qed.

  Lemma false_or :
    forall (P Q: Prop),
      (False <-> P \/ Q) <-> (False <-> P) /\ (False <-> Q).
  Proof.
    tauto.
  Qed.

  Lemma false_or' :
    forall (P Q: Prop),
      (P \/ Q <-> False) <-> (False <-> P) /\ (False <-> Q).
  Proof.
    tauto.
  Qed.

  Lemma equiv_false :
    forall P,
      (False <-> P) <-> (~ P).
  Proof. 
    tauto.
  Qed.

  Lemma equiv_false' :
    forall P,
      (P <-> False) <-> (~ P).
  Proof. 
    tauto.
  Qed.

  Lemma eq_sym_iff :
    forall {A} x y, @eq A x y <-> @eq A y x.
  Proof. 
    split; intros; symmetry; assumption.
  Qed.
End AdditionalLogicLemmas.

Section AdditionalBoolLemmas.
  Lemma collapse_ifs_dec :
    forall P (b: {P} + {~P}),
      (if (if b then true else false) then true else false) =
      (if b then true else false).
  Proof.
    destruct b; reflexivity.
  Qed.

  Lemma collapse_ifs_bool :
    forall (b: bool),
      (if (if b then true else false) then true else false) =
      (if b then true else false).
  Proof.
    destruct b; reflexivity.
  Qed.
End AdditionalBoolLemmas.

Section AdditionalEnsembleLemmas.
  Lemma weaken :
    forall {A: Type} ensemble condition,
    forall (x: A),
      Ensembles.In _ (fun x => Ensembles.In _ ensemble x /\ condition x) x
      -> Ensembles.In _ ensemble x.
  Proof.
    unfold Ensembles.In; intros; intuition.
  Qed.
End AdditionalEnsembleLemmas.

Section AdditionalListLemmas.
  Lemma map_id :
    forall {A: Type} (seq: list A),
      (map (fun x => x) seq) = seq.
  Proof.
    intros A seq; induction seq; simpl; congruence.
  Qed.

  Lemma in_nil_iff :
    forall {A} (item: A),
      List.In item [] <-> False.
  Proof.
    intuition.
  Qed.

  Lemma in_not_nil :
    forall {A} x seq,
      @List.In A x seq -> seq <> nil.
  Proof.
    intros A x seq in_seq eq_nil.
    apply (@in_nil _ x).
    subst seq; assumption.
  Qed.

  Lemma in_seq_false_nil_iff :
    forall {A} (seq: list A),
      (forall (item: A), (List.In item seq <-> False)) <-> 
      (seq = []).
  Proof.
    intros.
    destruct seq; simpl in *; try tauto.
    split; intro H.
    exfalso; specialize (H a); rewrite <- H; eauto.
    discriminate.
  Qed.

  Lemma filter_comm :
    forall {A: Type} (pred1 pred2: A -> bool),
    forall (seq: list A),
      List.filter pred1 (List.filter pred2 seq) =
      List.filter pred2 (List.filter pred1 seq).
  Proof.
    intros A pred1 pred2 seq;
    induction seq as [ | hd tl];
    [ simpl
    | destruct (pred1 hd) eqn:eq1;
      destruct (pred2 hd) eqn:eq2;
      repeat progress (simpl;
                       try rewrite eq1;
                       try rewrite eq2)
    ]; congruence.
  Qed.

  Lemma InA_In:
    forall (A : Type) (x : A) (l : list A),
      InA eq x l -> List.In x l.
  Proof.
    intros ? ? ? H;
    induction H;
    simpl;
    intuition.
  Qed.

  Lemma not_InA_not_In :
    forall {A: Type} l eqA (x: A),
      Equivalence eqA ->
      not (InA eqA x l) -> not (List.In x l).
  Proof.
    intros A l;
    induction l;
    intros ? ? equiv not_inA in_l;
    simpl in *;

    [ trivial
    | destruct in_l as [eq | in_l];
      subst;
      apply not_inA;
      pose proof equiv as (?,?,?);
      eauto using InA_cons_hd, InA_cons_tl, (In_InA equiv)
    ].
  Qed.

  Lemma NoDupA_stronger_than_NoDup :
    forall {A: Type} (seq: list A) eqA,
      Equivalence eqA ->
      NoDupA eqA seq -> NoDup seq.
  Proof.
    intros ? ? ? ? nodupA;
    induction nodupA;
    constructor ;
    [ apply (not_InA_not_In _ _ _ _ H0)
    | trivial].
  (* Alternative proof: red; intros; apply (In_InA (eqA:=eqA)) in H2; intuition. *)
  Qed.

  Lemma add_filter_nonnil_under_app :
    forall {A: Type} (seq: list (list A)),
      fold_right (app (A := A)) [] seq =
      fold_right (app (A := A)) [] (List.filter NonNil seq).
  Proof.
    intros; induction seq; simpl;
    [ | destruct a; simpl; rewrite IHseq];
    trivial.
  Qed.

  Lemma box_plus_app_is_identity :
    forall {A: Type} (seq: list A),
      fold_right (app (A := A)) [] (map Box seq) = seq.
  Proof.
    intros A seq; induction seq; simpl; congruence.
  Qed.

  Lemma in_Option2Box :
    forall {A: Type} (xo: option A) (x: A),
      List.In x (Option2Box xo) <-> xo = Some x.
  Proof.
    intros A xo x; destruct xo; simpl; try rewrite or_false; intuition; congruence.
  Qed.

  Lemma filter_by_equiv :
    forall {A} f g,
      ObservationalEq f g ->
      forall seq, @List.filter A f seq = @List.filter A g seq.
  Proof.
    intros A f g obs seq; unfold ObservationalEq in obs; induction seq; simpl; try rewrite obs; try rewrite IHseq; trivial.
  Qed.

  Lemma filter_and :
    forall {A} pred1 pred2,
    forall (seq: list A),
      List.filter (fun x => andb (pred1 x) (pred2 x)) seq =
      List.filter pred1 (List.filter pred2 seq).
  Proof.
    intros; 
    induction seq;
    simpl;
    [ | destruct (pred1 a) eqn:eq1; 
        destruct (pred2 a) eqn:eq2];
    simpl; 
    try rewrite eq1;
    try rewrite eq2;
    trivial;
    f_equal;
    trivial.
  Qed.

  Lemma filter_and' :
    forall {A} pred1 pred2,
    forall (seq: list A),
      List.filter (fun x => andb (pred1 x) (pred2 x)) seq =
      List.filter pred2 (List.filter pred1 seq).
  Proof.
    intros; 
    induction seq;
    simpl;
    [ | destruct (pred1 a) eqn:eq1; 
        destruct (pred2 a) eqn:eq2];
    simpl; 
    try rewrite eq1;
    try rewrite eq2;
    trivial;
    f_equal;
    trivial.
  Qed.

  Definition flatten {A} seq := List.fold_right (@app A) [] seq.

  Lemma in_flatten_iff :
    forall {A} x seqs, 
      @List.In A x (flatten seqs) <-> 
      exists seq, List.In x seq /\ List.In seq seqs.
  Proof.
    intros; unfold flatten.
    induction seqs; simpl. 

    firstorder.
    rewrite in_app_iff.
    rewrite IHseqs.

    split.
    intros [ in_head | [seq (in_seqs & in_seq) ] ]; eauto.
    intros [ seq ( in_seq & [ eq_head | in_seqs ] ) ]; subst; eauto.
  Qed.

  Lemma flatten_filter :
    forall {A} (seq: list (list A)) pred, 
      List.filter pred (flatten seq) =
      flatten (List.map (List.filter pred) seq). 
  Proof.
    intros; induction seq; trivial.
    unfold flatten; simpl.
    induction a; trivial.
    simpl; 
      destruct (pred a); simpl; rewrite IHa; trivial.
  Qed.

  Lemma map_map :
    forall { A B C } (proc1: A -> B) (proc2: B -> C),
    forall seq,
      List.map proc2 (List.map proc1 seq) = List.map (fun x => proc2 (proc1 x)) seq.
  Proof.            
    intros; induction seq; simpl; f_equal; trivial.
  Qed.        
  
  Lemma filter_all_true :
    forall {A} pred (seq: list A),
      (forall x, List.In x seq -> pred x = true) ->
      List.filter pred seq = seq.
  Proof.
    induction seq as [ | head tail IH ]; simpl; trivial.
    intros all_true.
    rewrite all_true by eauto.
    f_equal; intuition.
  Qed.

  Lemma filter_all_false :
    forall {A} seq pred,
      (forall item : A, List.In item seq -> pred item = false) ->
      List.filter pred seq = [].
  Proof.
    intros A seq pred all_false; induction seq as [ | head tail IH ]; simpl; trivial.
    rewrite (all_false head) by (simpl; eauto). 
    intuition.
  Qed.

  Lemma map_filter_all_false :
    forall {A} pred seq, 
      (forall subseq, List.In subseq seq -> 
                      forall (item: A), List.In item subseq -> 
                                        pred item = false) ->
      (List.map (List.filter pred) seq) = (List.map (fun x => []) seq).
  Proof.
    intros A pred seq all_false; 
    induction seq as [ | subseq subseqs IH ] ; simpl; trivial.
    
    f_equal.

    specialize (all_false subseq (or_introl eq_refl)).
    apply filter_all_false; assumption.

    apply IH; firstorder.
  Qed.

  Lemma foldright_compose :
    forall {TInf TOutf TAcc} 
           (g : TOutf -> TAcc -> TAcc) (f : TInf -> TOutf) 
           (seq : list TInf) (init : TAcc),
      List.fold_right (compose g f) init seq =
      List.fold_right g init (List.map f seq).
  Proof.
    intros; 
    induction seq; 
    simpl; 
    [  | rewrite IHseq ];
    reflexivity.
  Qed.            

  Lemma flatten_nils :
    forall {A} (seq: list (list A)),
      flatten (List.map (fun _ => []) seq) = @nil A.
  Proof.        
    induction seq; intuition. 
  Qed.

  Lemma flatten_app :
    forall {A} (seq1 seq2: list (list A)),
      flatten (seq1 ++ seq2) = flatten seq1 ++ flatten seq2.
  Proof.
    unfold flatten; induction seq1; simpl; trivial.
    intros; rewrite IHseq1; rewrite app_assoc; trivial.
  Qed.

  Lemma flatten_head :
    forall {A} head tail,
      @flatten A (head :: tail) = head ++ flatten tail.
  Proof.
    intuition.
  Qed.

  Lemma in_map_unproject :
    forall {A B} projection seq,
    forall item,
      @List.In A item seq ->
      @List.In B (projection item) (List.map projection seq).
  Proof.
    intros ? ? ? seq;
    induction seq; simpl; intros item in_seq.

    trivial.
    destruct in_seq;
      [ left; f_equal | right ]; intuition.
  Qed.
End AdditionalListLemmas.

Section AdditionalComputationLemmas.
  Lemma eq_ret_compute :
    forall (A: Type) (x y: A), x = y -> ret x ↝ y.
  Proof.
    intros; subst; apply ReturnComputes; trivial.
  Qed.

  Require Import Computation.Refinements.Tactics.

  Lemma refine_snd :
    forall {A B: Type} (P: B -> Prop),
      refine
        { pair | P (snd pair) }
        (_fst <- Pick (fun (x: A) => True);
         _snd <- Pick (fun (y: B) => P y);
         ret (_fst, _snd)).
  Proof.
    t_refine.
  Qed.

  Lemma refine_let :
    forall {A B : Type} (PA : A -> Prop) (PB : B -> Prop),
      refineEquiv (Pick (fun x: A * B  =>  let (a, b) := x in PA a /\ PB b))
                  (a <- {a | PA a};
                   b <- {b | PB b};
                   ret (a, b)).
  Proof.
    t_refine.
  Qed.

  Lemma refine_ret_eq :
    forall {A: Type} (a: A) b,
      b = ret a -> refine (ret a) (b).
  Proof.
    t_refine.
  Qed.

  Lemma ret_computes_to :
    forall {A: Type} (a1 a2: A),
      ret a1 ↝ a2 <-> a1 = a2.
  Proof.
    t_refine.
  Qed.

  Lemma refine_eqA_into_ret :
    forall {A: Type} {eqA: list A -> list A -> Prop},
      Reflexive eqA ->
      forall (comp : Comp (list A)) (impl result: list A),
        comp = ret impl -> (
          comp ↝ result ->
          eqA result impl
        ).
  Proof.
    intros; subst; inversion_by computes_to_inv; subst; trivial.
  Qed.
End AdditionalComputationLemmas.

Ltac refine_eq_into_ret :=
  match goal with
    | [ H : _ _ _ ↝ _ |- ?eq _ _ ] =>
      generalize H;
        clear H;
        apply (refine_eqA_into_ret _)
  end.

Ltac prove_observational_eq :=
  lazy; intuition (eauto using collapse_ifs_bool, collapse_ifs_dec; eauto with *).

Section AdditionalQueryLemmas. (* TODO: Kill the two following lemmas. They are outdated now. :'( *)
  Lemma refine_ensemble_into_list_with_extraction :
    forall {A B: Type} (la: list A) (ens: A -> Prop) (lb: list B)
           (cond_prop: A -> Prop) (cond: A -> bool)
           (extraction: A -> B),
      (forall a, (cond_prop a <-> cond a = true)) ->
      (EnsembleListEquivalence ens la) ->
      ((forall (b: B), List.In b lb <-> (exists a0, ens a0 /\ cond_prop a0 /\ extraction a0 = b)) <->
       (SetEq lb (map extraction (List.filter cond la)))).
  Proof.
    unfold SetEq, EnsembleListEquivalence.

    intros.
    split; intros.
    rewrite in_map_iff.
    destruct (H1 x) as [H1' H1''].

    split; intros.

    specialize (H1' H2).
    destruct H1' as [a1 ?].
    eexists.
    rewrite filter_In, <- H.
    rewrite <- H0.
    instantiate (1 := a1); tauto.

    destruct H2 as [x' H2].
    rewrite filter_In, <- H in H2.
    apply H1''.
    exists x'.
    rewrite H0; tauto.


    rewrite H1.
    rewrite in_map_iff.
    split; intro HH;
    destruct HH as [x HH];
    exists x;
    try rewrite filter_In in *;
    try rewrite H0, H in *;
    try rewrite <- H0 in *;
    tauto.
  Qed.

  Lemma refine_ensemble_into_list :
    forall {A: Type},
    forall (la: list A) (ens: A -> Prop) (lb: list A)
           (cond_prop: A -> Prop) (cond: A -> bool),
      (forall a, (cond_prop a <-> cond a = true)) ->
      (EnsembleListEquivalence ens la) ->
      ((forall (b : A), List.In b lb <-> ens b /\ cond_prop b) <->
       (SetEq lb (List.filter cond la))).
  Proof.
    unfold EnsembleListEquivalence.
    intros A la ens lb cond_prop cond H H0.

    pose proof (refine_ensemble_into_list_with_extraction la ens lb cond_prop cond (fun x => x) H H0).
    simpl in H1.

    rewrite map_id in H1.
    destruct H1 as [H1 H1'].

    split; intros HH;
    [ apply H1 | specialize (H1' HH) ].

    intros.
    specialize (HH b).
    rewrite HH.
    split; intros.
    exists b; intuition.
    destruct H2 as [a0 H2]; intuition; subst; tauto.

    unfold SetEq in HH.
    intros b; specialize (HH b).
    rewrite HH.

    rewrite filter_In, H, H0.
    intuition.
  Qed.

  Require Import Computation.Refinements.General.

  Lemma refine_pick_val' : 
    forall {A : Type} (a : A)  (P : A -> Prop),
      P a -> refine (Pick P) (ret a).
  Proof.
    intros; apply refine_pick_val; assumption.
  Qed.

  Require Import InsertQSSpecs StringBound.
  Lemma get_update_unconstr_iff :
    forall db_schema qs table new_contents,
    forall x,
      Ensembles.In _ (GetUnConstrRelation (UpdateUnConstrRelation db_schema qs table new_contents) table) x <->
      Ensembles.In _ new_contents x.
  Proof.
    unfold GetUnConstrRelation, UpdateUnConstrRelation, RelationInsert;
    intros; rewrite ith_replace_BoundIndex_eq;
    reflexivity.
  Qed.

  Require Import Heading Schema.
  Lemma tupleAgree_sym :
    forall (heading: Heading) tup1 tup2 attrs,
      @tupleAgree heading tup1 tup2 attrs <-> @tupleAgree heading tup2 tup1 attrs.
  Proof.
    intros; unfold tupleAgree;
    split; intro; setoid_rewrite eq_sym_iff; assumption.
  Qed.
End AdditionalQueryLemmas.

Section AdditionalSetEqLemmas.
  Lemma SetUnion_Or :
    forall {A: Type}
           {ens1 ens2: A -> Prop}
           {seq1 seq2: list A},
      EnsembleListEquivalence ens1 seq1 ->
      EnsembleListEquivalence ens2 seq2 ->
      EnsembleListEquivalence (fun x => ens1 x \/ ens2 x) (SetUnion seq1 seq2).
  Proof.
    unfold EnsembleListEquivalence, SetUnion, Ensembles.In;
    intros A ens1 ens2 seq1 seq2 eq1 eq2 x;
    specialize (eq1 x);
    specialize (eq2 x);
    rewrite in_app_iff;
    tauto.
  Qed.
End AdditionalSetEqLemmas.

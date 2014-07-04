Require Import AutoDB.

Definition Market := string.
Definition StockType := nat.
Definition StockCode := nat.
Definition Date      := nat.
Definition Timestamp := nat.

Definition TYPE := "TYPE".
Definition MARKET := "MARKET".
Definition STOCK_CODE := "STOCK_CODE".
Definition FULL_NAME := "FULL_NAME".

Definition DATE := "DATE".
Definition TIME := "TIME".
Definition PRICE := "PRICE".
Definition VOLUME := "VOLUME".

Definition STOCKS := "STOCKS".
Definition TRANSACTIONS := "TRANSACTIONS".

Definition StocksSchema :=
  Query Structure Schema
    [ relation STOCKS has
              schema <STOCK_CODE :: StockCode,
                      FULL_NAME :: string,
                      MARKET :: Market,
                      TYPE :: StockType>
              where attributes [FULL_NAME; MARKET; TYPE] depend on [STOCK_CODE]; (* uniqueness, really *)
      relation TRANSACTIONS has
              schema <STOCK_CODE :: nat,
                      DATE :: Date,
                      TIME :: Timestamp,
                      PRICE :: N,
                      VOLUME :: N>
              where attributes [PRICE] depend on [STOCK_CODE; TIME] ]
    enforcing [attribute STOCK_CODE for TRANSACTIONS references STOCKS].

Definition StocksSig : ADTSig :=
  ADTsignature {
      "Init"               : unit                              → rep,
      "AddStock"           : rep × (StocksSchema#STOCKS)       → rep × bool,
      "AddTransaction"     : rep × (StocksSchema#TRANSACTIONS) → rep × bool,
      "TotalVolume"        : rep × (StockCode * Date)          → rep × N,
      "MaxPrice"           : rep × (StockCode * Date)          → rep × option N,
      "TotalActivity"      : rep × (StockCode * Date)          → rep × nat,
      "LargestTransaction" : rep × (StockType * Date)          → rep × option N
    }.

Definition StocksSpec : ADT StocksSig :=
  QueryADTRep StocksSchema {
    const "Init" (_: unit) : rep := empty,

    update "AddStock" (stock: StocksSchema#STOCKS) : bool :=
        Insert stock into STOCKS,

    update "AddTransaction" (transaction : StocksSchema#TRANSACTIONS) : bool :=
        Insert transaction into TRANSACTIONS,

    query "TotalVolume" (params: StockCode * Date) : N :=
      SumN (For (transaction in TRANSACTIONS)
            Where (transaction!STOCK_CODE = fst params)
            Where (transaction!DATE = snd params)
            Return transaction!VOLUME),

    query "MaxPrice" (params: StockCode * Date) : option N :=
      MaxN (For (transaction in TRANSACTIONS)
            Where (transaction!STOCK_CODE = fst params)
            Where (transaction!DATE = snd params)
            Return transaction!PRICE),

    query "TotalActivity" (params: StockCode * Date) : nat :=
      Count (For (transaction in TRANSACTIONS)
            Where (transaction!STOCK_CODE = fst params)
            Where (transaction!DATE = snd params)
            Return ()),

    query "LargestTransaction" (params: StockType * Date) : option N :=
      MaxN (For (stock in STOCKS)
            For (transaction in TRANSACTIONS)
            Where (stock!TYPE = fst params)
            Where (transaction!DATE = snd params)
            Where (stock!STOCK_CODE = transaction!STOCK_CODE)
            Return (N.mul transaction!PRICE transaction!VOLUME))
}.

Definition StocksHeading := GetHeading StocksSchema STOCKS.
Definition TransactionsHeading := GetHeading StocksSchema TRANSACTIONS.

(* Using those breaks refine_foreign_key_check_into_query *)
Definition STOCK_STOCKCODE        := StocksHeading/STOCK_CODE.
Definition STOCK_TYPE             := StocksHeading/TYPE.
Definition TRANSACTIONS_DATE      := TransactionsHeading/DATE.
Definition TRANSACTIONS_STOCKCODE := TransactionsHeading/STOCK_CODE.

Definition StocksStorage : @BagPlusBagProof (StocksSchema#STOCKS).
  mkIndex StocksHeading [StocksHeading/TYPE; StocksHeading/STOCK_CODE].
Defined.

Definition TransactionsStorage : @BagPlusBagProof (StocksSchema#TRANSACTIONS).
  mkIndex TransactionsHeading [TransactionsHeading/DATE; TransactionsHeading/STOCK_CODE].
Defined.

Definition TStocksBag := BagType StocksStorage.
Definition TTransactionsBag := BagType TransactionsStorage.

Definition Stocks_AbsR
           (or : UnConstrQueryStructure StocksSchema)
           (nr : (TStocksBag) * (TTransactionsBag)) : Prop :=
  or!STOCKS ≃ benumerate (fst nr) /\ or!TRANSACTIONS ≃ benumerate (snd nr).

Definition StocksDB :
  Sharpened StocksSpec.
Proof.
  match goal with
    | [ |- Sharpened ?spec ] =>
      unfolder spec ltac:(fun spec' => change spec with spec')
  end; start_honing_QueryStructure; hone_representation Stocks_AbsR.

(*  plan Stocks_AbsR. *)
 
  hone method "AddTransaction".
  startMethod Stocks_AbsR. 
  pruneDuplicates. 
  pickIndex.
  fundepToQuery.
  concretize.
  asPerm (StocksStorage, TransactionsStorage).
  commit.

  (* This is the body of foreignToQuery *) 
  match goal with
    | [ |- context[Pick (fun b' => decides b' (exists tup2 : @IndexedTuple ?H, _ /\ ?r ``?s = _ ))] ] =>
      match goal with
        | [ |- appcontext[@benumerate _ (@Tuple ?H')] ] =>
          equate H H'; let T' := constr:(@Tuple H') in
                       let temp := fresh in
                       pose (refine_foreign_key_check_into_query (fun t : T' => r!s = t!s)) as temp;
                         rewrite temp by eauto with typeclass_instances;
                         simplify with monad laws; cbv beta; simpl; clear temp
      end
  end.

  Focus 2.
  (* Strange thing: there are two levels of absMethod here *)
  hone method "LargestTransaction". 
  idtac.
  idtac.
  unfold Stocks_AbsR in *; split_and. simplify with monad laws.
  startMethod Stocks_AbsR. concretize. asPerm (StocksStorage, TransactionsStorage.
  commit; choose_db AbsR; finish honing.
  
  match goal with
    | [ |- Sharpened ?spec ] =>
      unfolder spec ltac:(fun spec' => change spec with spec')
  end; start_honing_QueryStructure. hone_representation Stocks_AbsR.

  hone method "AddStock".
  mutator.
  startMethod Stocks_AbsR; repeat progress (try setoid_rewrite refine_trivial_if_then_else; 
                   try setoid_rewrite key_symmetry;
                   try setoid_rewrite refine_tupleAgree_refl_True; 
                   try simplify with monad laws); pickIndex;
  repeat ((foreignToQuery || fundepToQuery);
          concretize; asPerm storages; commit);
  Split Constraint Checks; checksSucceeded || checksFailed.
  pickIndex.
  mutator.
  honeOne.

  plan Stocks_AbsR.
  
  Print Ltac plan.

  (*unfold cast, eq_rect_r, eq_rect, eq_sym.*)
  Notation "a ! b" := (a ``(b)).
  Notation "a == b" := (if string_dec a b then true else false).
  Notation "a != b" := (negb (beq_nat b a)) (at level 20, no associativity).
  Notation "a == b" := (beq_nat b a).
  repeat match goal with
           | [ H := _ |- _ ] => unfold H; clear H
         end.
  finish sharpening.
Defined.

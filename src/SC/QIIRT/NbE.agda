module SC.QIIRT.NbE where

open import Prelude
open import Data.Product
open import SC.QIIRT.Base

-- Definition of Variables and Renaming
-- with embedding into Tm and Sub
data Var : (Γ : Ctx) → Ty Γ → Set where
  here  : Var (Γ ‣ A) (A [ π₁ idS ])
  there : Var Γ A → Var (Γ ‣ B) (A [ π₁ idS ])

⌞_⌟V : Var Γ A → Tm Γ A
⌞ here ⌟V = π₂ idS
⌞ there x ⌟V  = ⌞ x ⌟V [ π₁ idS ]tm

data Ren : Ctx → Ctx → Set
⌞_⌟R : Ren Δ Γ → Sub Δ Γ

data Ren where
  ∅ : Ren Δ ∅
  _‣_ : (ρ : Ren Δ Γ) → Var Δ (A [ ⌞ ρ ⌟R ]) → Ren Δ (Γ ‣ A)

⌞ ∅ ⌟R = ∅
⌞ σ ‣ t ⌟R = ⌞ σ ⌟R ‣ ⌞ t ⌟V

-- Operations about renamings: lift, identity, and variable lookup
_↑R_ : Ren Δ Γ → (A : Ty Δ) → Ren (Δ ‣ A) Γ
∅ ↑R A = ∅
(_‣_ {A = U} ρ x) ↑R A = (ρ ↑R A) ‣ there x

idR : Ren Δ Δ
idR {∅} = ∅
idR {Δ ‣ U} = (idR ↑R U) ‣ here

lookupVar : (ρ : Ren Δ Γ) → Var Γ A → Var Δ (A [ ⌞ ρ ⌟R ])
lookupVar (_‣_ {A = U} ρ x) here = x 
lookupVar (_‣_ {A = U} ρ x') (there {A = U} x) = lookupVar ρ x
-- requires A [ π₁ idS ] [ ⌞ ρ ⌟R ‣ ⌞ x ⌟V ] ≡ A [ ⌞ ρ ⌟R ] , but pattern match on U for now

-- Several lemmas
⌞lookup⌟ : (ρ : Ren Δ Γ)(x : Var Γ A) → ⌞ lookupVar ρ x ⌟V ≡ ⌞ x ⌟V [ ⌞ ρ ⌟R ]tm
⌞lookup⌟ (_‣_ {A = U} ρ x) here = begin
    ⌞ x ⌟V
  ≡⟨ sym (βπ₂ {σ = ⌞ ρ ⌟R} {⌞ x ⌟V}) ⟩
    π₂ (⌞ ρ ⌟R ‣ ⌞ x ⌟V)
  ≡⟨ cong π₂ (sym (idS∘ (⌞ ρ ⌟R ‣ ⌞ x ⌟V))) ⟩
    π₂ (idS ∘ (⌞ ρ ⌟R ‣ ⌞ x ⌟V))
  ≡⟨ π₂∘ idS (⌞ ρ ⌟R ‣ ⌞ x ⌟V) ⟩
    π₂ idS [ ⌞ ρ ⌟R ‣ ⌞ x ⌟V ]tm
  ≡⟨⟩
    ⌞ here ⌟V [ ⌞ ρ ⌟R ‣ ⌞ x ⌟V ]tm
  ∎
⌞lookup⌟ (_‣_ {A = U} ρ x') (there {A = U} x) = begin
    ⌞ lookupVar ρ x ⌟V
  ≡⟨ ⌞lookup⌟ ρ x ⟩
    ⌞ x ⌟V [ ⌞ ρ ⌟R ]tm
  ≡⟨ cong (⌞ x ⌟V [_]tm) (sym (βπ₁ {σ = ⌞ ρ ⌟R} {⌞ x' ⌟V})) ⟩
    ⌞ x ⌟V [ π₁ (⌞ ρ ⌟R ‣ ⌞ x' ⌟V) ]tm
  ≡⟨ cong (⌞ x ⌟V [_]tm) (cong π₁ (sym (idS∘ (⌞ ρ ⌟R ‣ ⌞ x' ⌟V)))) ⟩
    ⌞ x ⌟V [ π₁ (idS ∘ (⌞ ρ ⌟R ‣ ⌞ x' ⌟V)) ]tm
  ≡⟨ cong (⌞ x ⌟V [_]tm) (π₁∘ idS (⌞ ρ ⌟R ‣ ⌞ x' ⌟V)) ⟩
    ⌞ x ⌟V [ π₁ idS ∘ (⌞ ρ ⌟R ‣ ⌞ x' ⌟V) ]tm
  ≡⟨ [∘]tm ⌞ x ⌟V (π₁ idS) (⌞ ρ ⌟R ‣ ⌞ x' ⌟V) ⟩ -- would be "refl" using recursion _[_]t
    ⌞ x ⌟V [ π₁ idS ]tm [ ⌞ ρ ⌟R ‣ ⌞ x' ⌟V ]tm
  ≡⟨⟩
    ⌞ there x ⌟V [ ⌞ ρ ⌟R ‣ ⌞ x' ⌟V ]tm
  ∎

⌞↑⌟ : (ρ : Ren Δ Γ)(A : Ty Δ) → ⌞ ρ ↑R A ⌟R ≡ ⌞ ρ ⌟R ∘ π₁ idS
⌞↑⌟ ∅ A = sym η∅
⌞↑⌟ (_‣_ {A = U} ρ x) A = begin
    ⌞ ρ ↑R A ⌟R ‣ ⌞ x ⌟V [ π₁ idS ]tm
  ≡⟨ cong (_‣ ⌞ x ⌟V [ π₁ idS ]tm) (⌞↑⌟ ρ A) ⟩
    (⌞ ρ ⌟R ∘ π₁ idS) ‣ ⌞ x ⌟V [ π₁ idS ]tm
  ≡⟨ sym (‣∘ {σ = ⌞ ρ ⌟R} {⌞ x ⌟V} {π₁ idS}) ⟩
    ((⌞ ρ ⌟R ‣ ⌞ x ⌟V) ∘ π₁ idS)
  ∎

⌞idR⌟ : ⌞ idR {Δ} ⌟R ≡ idS
⌞idR⌟ {∅} = sym η∅
⌞idR⌟ {Δ ‣ U} = begin 
    ⌞ idR ↑R U ⌟R ‣ π₂ idS
  ≡⟨ cong (_‣ π₂ idS) (⌞↑⌟ idR U) ⟩
    (⌞ idR ⌟R ∘ π₁ idS) ‣ π₂ idS
  ≡⟨ cong (λ y → (y ∘ π₁ idS) ‣ π₂ idS) ⌞idR⌟ ⟩
    (idS ∘ π₁ idS) ‣ π₂ idS
  ≡⟨ cong (_‣ π₂ idS) (idS∘ (π₁ idS)) ⟩
    π₁ idS ‣ π₂ idS
  ≡⟨ sym ηπ ⟩
    idS
  ∎

-- Composition of renamings
_⊙_ : Ren Δ Γ → Ren Θ Δ → Ren Θ Γ
∅ ⊙ _ = ∅
_‣_ {A = U} ρ x ⊙ ρ' = (ρ ⊙ ρ') ‣ lookupVar ρ' x

⌞⊙⌟ : (ρ : Ren Δ Γ)(ρ' : Ren Θ Δ) → ⌞ ρ ⊙ ρ' ⌟R ≡ ⌞ ρ ⌟R ∘ ⌞ ρ' ⌟R
⌞⊙⌟ ∅ ρ' = sym η∅
⌞⊙⌟ (_‣_ {A = U} ρ x) ρ' = begin 
    ⌞ ρ ⊙ ρ' ⌟R ‣ ⌞ lookupVar ρ' x ⌟V
  ≡⟨ cong (_‣ ⌞ lookupVar ρ' x ⌟V) (⌞⊙⌟ ρ ρ') ⟩
    (⌞ ρ ⌟R ∘ ⌞ ρ' ⌟R) ‣ ⌞ lookupVar ρ' x ⌟V
  ≡⟨ cong ((⌞ ρ ⌟R ∘ ⌞ ρ' ⌟R) ‣_) (⌞lookup⌟ ρ' x) ⟩ 
    (⌞ ρ ⌟R ∘ ⌞ ρ' ⌟R) ‣ ⌞ x ⌟V [ ⌞ ρ' ⌟R ]tm
  ≡⟨ sym (‣∘ {A = U} {⌞ ρ ⌟R} {⌞ x ⌟V} {⌞ ρ' ⌟R}) ⟩
    (⌞ ρ ⌟R ‣ ⌞ x ⌟V) ∘ ⌞ ρ' ⌟R
  ∎

-- Reification of terms and substitutions into variables and renamings
---- This is feasible because the only type is U for now
reifyTm : Tm Γ A → Var Γ A
reifySub : Sub Δ Γ → Ren Δ Γ
reifyTm (π₂ {A = U} σ) with reifySub σ
... | ρ ‣ x = x
reifyTm (t [ σ ]tm) with reifyTm t | reifySub σ
... | here  {A = U}   | ρ ‣ x  = x
... | there {A = U} x | ρ ‣ x' = lookupVar ρ x
reifySub ∅ = ∅ 
reifySub (σ ‣ t) = reifySub σ ‣ reifyTm t
reifySub idS = idR
reifySub (σ ∘ τ) = reifySub σ ⊙ reifySub τ
reifySub (π₁ σ) with reifySub σ
... | ρ ‣ _ = ρ

soundnessTm : (t : Tm Γ A) → ⌞ reifyTm t ⌟V ≡ t
soundnessSub : (σ : Sub Δ Γ) → ⌞ reifySub σ ⌟R ≡ σ
soundnessTm (π₂ {A = U} (σ ‣ t)) with soundnessSub (σ ‣ t)
... | eq = begin
    ⌞ reifyTm t ⌟V
  ≡⟨ sym (βπ₂ {σ = ⌞ reifySub σ ⌟R} {⌞ reifyTm t ⌟V}) ⟩
    π₂ (⌞ reifySub σ ⌟R ‣ ⌞ reifyTm t ⌟V)
  ≡⟨ cong π₂ eq ⟩
    π₂ (σ ‣ t)
  ∎
soundnessTm (π₂ {A = U} idS) = refl
soundnessTm (π₂ {Δ} {A = U} (σ ∘ τ)) with reifySub σ | soundnessSub σ
... | ρ ‣ x | ⌞ρ⌟‣⌞x⌟≡σ with soundnessSub τ
... | eq = begin
    ⌞ lookupVar (reifySub τ) x ⌟V
  ≡⟨ ⌞lookup⌟ (reifySub τ) x ⟩
    ⌞ x ⌟V [ ⌞ reifySub τ ⌟R ]tm
  ≡⟨ cong (⌞ x ⌟V [_]tm) eq ⟩
    ⌞ x ⌟V [ τ ]tm
  ≡⟨ cong (_[ τ ]tm) (sym (βπ₂ {σ = ⌞ ρ ⌟R} {⌞ x ⌟V})) ⟩
    π₂ (⌞ ρ ⌟R ‣ ⌞ x ⌟V) [ τ ]tm
  ≡⟨ cong (λ y → π₂ y [ τ ]tm) ⌞ρ⌟‣⌞x⌟≡σ ⟩
    π₂ σ [ τ ]tm
  ≡⟨ sym (π₂∘ σ τ) ⟩
    π₂ (σ ∘ τ)
  ∎
soundnessTm (π₂ {Δ} {A = U} (π₁ σ)) with reifySub σ | soundnessSub σ
... | (ρ ‣ x) ‣ x' | eq = begin
    ⌞ x ⌟V
  ≡⟨ sym (βπ₂ {σ = ⌞ ρ ⌟R} {⌞ x ⌟V}) ⟩
    π₂ (⌞ ρ ⌟R ‣ ⌞ x ⌟V)
  ≡⟨ cong π₂ (sym (βπ₁ {σ = ⌞ ρ ⌟R ‣ ⌞ x ⌟V} {⌞ x' ⌟V})) ⟩
    π₂ (π₁ ((⌞ ρ ⌟R ‣ ⌞ x ⌟V) ‣ ⌞ x' ⌟V))
  ≡⟨ cong (λ y → π₂ (π₁ y)) eq ⟩
    π₂ (π₁ σ)
  ∎
soundnessTm (t [ σ ]tm) with reifyTm t | reifySub σ | soundnessTm t | soundnessSub σ
... | here {A = U} | ρ ‣ x | eqTm | eqSub = begin
    ⌞ x ⌟V
  ≡⟨ sym (βπ₂ {σ = ⌞ ρ ⌟R} {⌞ x ⌟V}) ⟩
    π₂ (⌞ ρ ⌟R ‣ ⌞ x ⌟V)
  ≡⟨ cong π₂ eqSub ⟩
    π₂ σ
  ≡⟨ cong π₂ (sym (idS∘ σ)) ⟩
    π₂ (idS ∘ σ)
  ≡⟨ π₂∘ idS σ ⟩
    π₂ idS [ σ ]tm
  ≡⟨ cong (_[ σ ]tm) eqTm ⟩
    t [ σ ]tm
  ∎
... | there {A = U} x | ρ ‣ x' | eqTm | eqSub = begin
    ⌞ lookupVar ρ x ⌟V
  ≡⟨ ⌞lookup⌟ ρ x ⟩
    ⌞ x ⌟V [ ⌞ ρ ⌟R ]tm
  ≡⟨ cong (⌞ x ⌟V [_]tm) (sym (βπ₁ {σ = ⌞ ρ ⌟R} {⌞ x' ⌟V})) ⟩
    ⌞ x ⌟V [ π₁ (⌞ ρ ⌟R ‣ ⌞ x' ⌟V) ]tm
  ≡⟨ cong (λ y → ⌞ x ⌟V [ π₁ y ]tm) eqSub ⟩
    ⌞ x ⌟V [ π₁ σ ]tm
  ≡⟨ cong (⌞ x ⌟V [_]tm) (sym (π₁idS∘ σ)) ⟩ -- would be "cong (⌞ x ⌟V [_]t) (sym (π₁idS∘ σ))" using recursion _[_]t
    ⌞ x ⌟V [ π₁ idS ∘ σ ]tm
  ≡⟨ [∘]tm ⌞ x ⌟V (π₁ idS) σ ⟩ -- would be "refl" using recursion _[_]t
    ⌞ x ⌟V [ π₁ idS ]tm [ σ ]tm
  ≡⟨ cong (_[ σ ]tm) eqTm ⟩
    t [ σ ]tm
  ∎
soundnessSub ∅ = refl
soundnessSub (σ ‣ t) = begin
    ⌞ reifySub σ ⌟R ‣ ⌞ reifyTm t ⌟V
  ≡⟨ cong (⌞ reifySub σ ⌟R ‣_) (soundnessTm t) ⟩
    ⌞ reifySub σ ⌟R ‣ t
  ≡⟨ cong (_‣ t) (soundnessSub σ) ⟩
    σ ‣ t
  ∎
soundnessSub idS = ⌞idR⌟
soundnessSub (σ ∘ τ) = begin
    ⌞ reifySub σ ⊙ reifySub τ ⌟R
  ≡⟨ ⌞⊙⌟ (reifySub σ) (reifySub τ) ⟩
    ⌞ reifySub σ ⌟R ∘ ⌞ reifySub τ ⌟R
  ≡⟨ cong (_∘ ⌞ reifySub τ ⌟R) (soundnessSub σ) ⟩
    σ ∘ ⌞ reifySub τ ⌟R
  ≡⟨ cong (σ ∘_) (soundnessSub τ) ⟩
    σ ∘ τ
  ∎
soundnessSub (π₁ σ) with reifySub σ | soundnessSub σ
... | ρ ‣ x | eq = begin
    ⌞ ρ ⌟R
  ≡⟨ sym (βπ₁ {σ = ⌞ ρ ⌟R} {⌞ x ⌟V}) ⟩
    π₁ (⌞ ρ ⌟R ‣ ⌞ x ⌟V)
  ≡⟨ cong π₁ eq ⟩
    π₁ σ
  ∎

-- Inductive definition of the normal form
data NeSub (Δ : Ctx) : (Γ : Ctx) → Sub Δ Γ → Set where
  idS : NeSub Δ Δ idS
  π₁  : NeSub Δ (Γ ‣ A) σ → NeSub Δ Γ (π₁ σ)

data NfTm (Δ : Ctx) : Tm Δ A → Set where
  π₂ : NeSub Δ (Γ ‣ A) σ → NfTm Δ {A [ π₁ σ ]} (π₂ σ)

test : vs {B = B'} (vs {B = B} (vz {Γ} {U})) ≡ π₂ (π₁ (π₁ idS)) -- π₂ (π₁ (π₁ idS))
test {Γ} {B} {B'} =
  begin
    π₂ idS [ π₁ idS ]tm [ π₁ idS ]tm
  ≡⟨ cong (_[ π₁ idS ]tm) (sym (π₂∘ idS (π₁ idS))) ⟩
    π₂ (idS ∘ π₁ idS) [ π₁ idS ]tm
  ≡⟨ cong (_[ π₁ idS ]tm) (cong π₂ (idS∘ (π₁ idS))) ⟩
    π₂ (π₁ idS) [ π₁ idS ]tm
  ≡⟨ sym (π₂∘ (π₁ idS) (π₁ idS)) ⟩
    π₂ (π₁ idS ∘ π₁ idS)
  ≡⟨ cong π₂ (sym (π₁∘ idS (π₁ idS))) ⟩
    π₂ (π₁ (idS ∘ π₁ idS))
  ≡⟨ cong (λ y → π₂ (π₁ y)) (idS∘ (π₁ idS)) ⟩
    π₂ (π₁ (π₁ idS))
  ∎

accVar : (x : Var Γ A)(σ : Sub Δ Γ) → Tm Δ (A [ σ ])
accVar (here {A = U}) σ = π₂ σ
accVar (there {A = U} {U} x) σ = accVar x (π₁ σ)

accVar[]tm : (x : Var Γ A)(σ : Sub Δ Γ)(τ : Sub Θ Δ) → accVar x σ [ τ ]tm ≡ tr (Tm Θ) ([∘] A σ τ) (accVar x (σ ∘ τ))
accVar[]tm (here {A = U}) σ τ = sym (π₂∘ σ τ)
accVar[]tm (there {A = U} {U} x) σ τ = begin
    accVar x (π₁ σ) [ τ ]tm
  ≡⟨ accVar[]tm x (π₁ σ) τ ⟩
    accVar x (π₁ σ ∘ τ)
  ≡⟨ cong (accVar x) (sym (π₁∘ σ τ)) ⟩
    accVar x (π₁ (σ ∘ τ))
  ∎

nfVar : (x : Var Γ A) → Tm Γ A
nfVar {A = U} x = accVar x idS

soundnessNfVar : (x : Var Γ A) → ⌞ x ⌟V ≡ nfVar x
soundnessNfVar (here {A = U}) = refl
soundnessNfVar (there {A = U} {U} x) = begin
    ⌞ x ⌟V [ π₁ idS ]tm
  ≡⟨ cong (_[ π₁ idS ]tm) (soundnessNfVar x) ⟩
    accVar x idS [ π₁ idS ]tm
  ≡⟨ accVar[]tm x idS (π₁ idS) ⟩
    accVar x (idS ∘ π₁ idS)
  ≡⟨ cong (accVar x) (idS∘ π₁ idS) ⟩
    accVar x (π₁ idS)
  ∎

NfTm[nfVar] : (x : Var Γ A) → NfTm Γ (nfVar x)
NfTm[nfVar] (here {A = U}) = π₂ idS
NfTm[nfVar] (there {A = U} x) = {!   !} 
module to-string where

open import lib
open import cedille-types
open import syntax-util
open import ctxt

markup : (attr : string) → 𝕃 (string × string) → string → string
markup a ts s = "<" ^ a ^ (markup-h ts "") ^ ">" ^ s ^ "</" ^ a ^ ">"
  where
    markup-h : 𝕃 (string × string) → string → string
    markup-h ((th , vh) :: t) s = markup-h t (s ^ (" " ^ th ^ "='" ^ vh ^ "'"))
    markup-h [] s = s

markup-unless-missing : var → location → string
markup-unless-missing v ("missing" , "missing") = v
markup-unless-missing v ("[nofile]" , _) = v
markup-unless-missing v (fn , pi) = markup "location" (("filename" , fn) :: ("pos" , pi) :: []) v

var-to-string : ctxt → var → string
var-to-string Γ v = markup-unless-missing (unfile Γ v) (ctxt-var-location Γ v)

binder-to-string : binder → string
binder-to-string All = "∀"
binder-to-string Pi = "Π"

maybeErased-to-string : maybeErased → string
maybeErased-to-string Erased = "-"
maybeErased-to-string NotErased = ""

lam-to-string : lam → string
lam-to-string ErasedLambda = "Λ"
lam-to-string KeptLambda = "λ"

leftRight-to-string : leftRight → string
leftRight-to-string Left = "l"
leftRight-to-string Right = "r"
leftRight-to-string Both = ""

vars-to-string : ctxt → vars → string
vars-to-string Γ (VarsStart v) = unfile Γ v
vars-to-string Γ (VarsNext v vs) = unfile Γ v ^ " " ^ vars-to-string Γ vs

theta-to-string : ctxt → theta → string
theta-to-string _ Abstract = "θ"
theta-to-string _ AbstractEq = "θ+"
theta-to-string Γ (AbstractVars vs) = "θ<" ^ vars-to-string Γ vs ^ ">"

ie-to-string : ie → string
ie-to-string Iota = "ι"
ie-to-string Exists = "∃"

maybeMinus-to-string : maybeMinus → string
maybeMinus-to-string EpsHnf = ""
maybeMinus-to-string EpsHanf = "-"

-- the 𝔹 argument tells whether this is a top-level expression, or a subexpression
type-to-string : ctxt → 𝔹 → type → string
term-to-string : ctxt → 𝔹 → term → string
kind-to-string : ctxt → 𝔹 → kind → string
lterms-to-stringh : ctxt → lterms → string
type-to-stringh : {ed : exprd} → ctxt → 𝔹 → ⟦ ed ⟧ → type → string
term-to-stringh : {ed : exprd} → ctxt → 𝔹 → ⟦ ed ⟧ → term → string
kind-to-stringh : {ed : exprd} → ctxt → 𝔹 → ⟦ ed ⟧ → kind → string
optClass-to-string : ctxt → optClass → string
optType-to-string : ctxt → optType → string
maybeCheckType-to-string : ctxt → maybeCheckType → string
optTerm-to-string : ctxt → optTerm → string
tk-to-string : ctxt → tk → string
liftingType-to-string : ctxt → liftingType → string
liftingType-to-stringh : {ed : exprd} → ctxt → ⟦ ed ⟧ → liftingType → string
qualif-to-string : ctxt → qualif-info → string
maybeAtype-to-string : ctxt → maybeAtype → string
arg-to-string : ctxt → arg → string
args-to-string : ctxt → args → string

-- If the first or second argument (toplevel, locally-not-needed) is true, don't put parens; else put parens
-- converts terms to string equivalents by adding parens
-- at the top level, parens are not needed
parens-unless : 𝔹 → 𝔹 → string → string
parens-unless toplevel locally-not-needed s =
  if toplevel || locally-not-needed then s else ("(" ^ s ^ ")")

term-to-string Γ toplevel t = term-to-stringh Γ toplevel star t
type-to-string Γ toplevel tp = type-to-stringh Γ toplevel star tp
kind-to-string Γ toplevel k = kind-to-stringh Γ toplevel star k
liftingType-to-string Γ l = liftingType-to-stringh Γ star l
qualif-to-string Γ (x , as) = x ^ args-to-string Γ as

term-to-stringh Γ toplevel p (App t x t') = 
  parens-unless toplevel ((is-beta p) || (is-app p)) (term-to-stringh Γ ff (App t x t') t ^ " " ^ (maybeErased-to-string x) ^ term-to-string Γ ff t')
term-to-stringh Γ toplevel p (AppTp t tp) =
  parens-unless toplevel ((is-beta p) || (is-app p)) (term-to-stringh Γ ff (AppTp t tp) t ^ " · " ^ type-to-string Γ ff tp)
term-to-stringh Γ toplevel p (Hole _) = "●"
term-to-stringh Γ toplevel p (Lam pi l pi' x o t) = 
  parens-unless toplevel ((is-beta p) || (is-abs p))
    (lam-to-string l ^ " " ^ x ^ optClass-to-string Γ o ^ " . " ^ term-to-stringh Γ ff (Lam pi l pi' x o t) t)
term-to-stringh Γ toplevel p (Let pi (DefTerm pi'' x m t) t') = 
  let parent = Let pi (DefTerm pi'' x m t) t' in
  parens-unless toplevel ((is-beta p) || (is-abs p))
    ("let " ^ x ^ maybeCheckType-to-string Γ m ^ " = " ^ term-to-stringh Γ ff parent t ^ " in " ^ term-to-stringh Γ ff parent t')
term-to-stringh Γ toplevel p (Let pi (DefType pi'' x k t) t') = 
  let parent = Let pi (DefType pi'' x k t) t' in
  parens-unless toplevel ((is-beta p) || (is-abs p))
    ("let " ^ x ^ " ◂ " ^ kind-to-string Γ toplevel k ^ " = " ^ type-to-stringh Γ ff parent t ^ " in " ^ term-to-stringh Γ ff parent t')
term-to-stringh Γ toplevel p (Unfold _ t) =
  "unfold " ^ (term-to-string Γ toplevel t)
term-to-stringh Γ toplevel p (Parens _ t _) = term-to-string Γ toplevel t
-- Here
term-to-stringh Γ toplevel p (Var pi x) = var-to-string Γ x
term-to-stringh Γ toplevel p (Beta _ ot) = "β" ^ optTerm-to-string Γ ot
term-to-stringh Γ toplevel p (Delta _ t) = "(δ" ^ " " ^ term-to-string Γ ff t ^ ")"
term-to-stringh Γ toplevel p (Omega _ t) = "(ω" ^ " " ^ term-to-string Γ ff t ^ ")"
term-to-stringh Γ toplevel p (IotaPair _ t1 t2 ot _) = "[ " ^ term-to-string Γ tt t1 ^ " , " ^ term-to-string Γ tt t1 ^ " ]"
term-to-stringh Γ toplevel p (IotaProj t n _) = term-to-string Γ ff t ^ " . " ^ n
term-to-stringh Γ toplevel p (PiInj _ n t) = "(π" ^ n ^ " " ^ term-to-string Γ ff t ^ ")"
term-to-stringh Γ toplevel p (Epsilon _ lr m t) = "(ε" ^ leftRight-to-string lr ^ maybeMinus-to-string m ^ " " ^ term-to-string Γ ff t ^ ")"
term-to-stringh Γ toplevel p (Sigma _ t) = "(ς " ^ term-to-string Γ ff t ^ ")"
term-to-stringh Γ toplevel p (Theta _ u t ts) = "(" ^ theta-to-string Γ u ^ " " ^ term-to-string Γ ff t ^ lterms-to-stringh Γ ts ^ ")"
term-to-stringh Γ toplevel p (Rho _ r t t') = "(" ^ rho-to-string r ^ term-to-string Γ ff t ^ " - " ^ term-to-string Γ ff t' ^ ")"
  where rho-to-string : rho → string
        rho-to-string RhoPlain = "ρ"
        rho-to-string RhoPlus = "ρ+"
term-to-stringh Γ toplevel p (Chi _ T t') = "(χ " ^ maybeAtype-to-string Γ T ^ " - " ^ term-to-string Γ ff t' ^ ")"

type-to-stringh Γ toplevel p (Abs pi b pi' x t t') = 
  parens-unless toplevel (is-abs p)
    (binder-to-string b ^ " " ^ x ^ " : " ^ tk-to-string Γ t ^ " . " ^ type-to-stringh Γ ff (Abs pi b pi' x t t') t')
type-to-stringh Γ toplevel p (TpLambda pi pi' x tk t) = 
  parens-unless toplevel (is-abs p) ("λ " ^ x ^ " : " ^ tk-to-string Γ tk ^ " . " ^ type-to-stringh Γ ff (TpLambda pi pi' x tk t) t )
type-to-stringh Γ toplevel p (IotaEx pi ie pi' x m t) = parens-unless toplevel (is-abs p) (ie-to-string ie ^ " " ^ x ^ optType-to-string Γ m ^ " . " 
                                  ^ type-to-stringh Γ ff (IotaEx pi ie pi' x m t) t)
type-to-stringh Γ toplevel p (Lft _ _ X x x₁) = "(↑ " ^ X ^ " . " ^ term-to-string Γ ff x ^ " : " ^ liftingType-to-string Γ x₁ ^ ")"
type-to-stringh Γ toplevel p (TpApp t t₁) = parens-unless toplevel (is-app p) (type-to-stringh Γ ff (TpApp t t₁) t ^ " · " ^ type-to-string Γ ff t₁)
type-to-stringh Γ toplevel p (TpAppt t t') = parens-unless toplevel (is-app p) (type-to-stringh Γ ff (TpAppt t t') t ^ " " ^ term-to-string Γ ff t')
type-to-stringh Γ toplevel p (TpArrow x UnerasedArrow t) =
  parens-unless toplevel (is-arrow p) (type-to-string Γ ff x ^ " ➔ " ^  type-to-stringh Γ ff (TpArrow x UnerasedArrow t) t)
type-to-stringh Γ toplevel p (TpArrow x ErasedArrow t) = 
  parens-unless toplevel (is-arrow p) (type-to-string Γ ff x ^ " ➾ " ^  type-to-stringh Γ ff (TpArrow x ErasedArrow t) t)
type-to-stringh Γ toplevel p (TpEq t1 t2) = "(" ^ term-to-string Γ ff t1 ^ " ≃ " ^ term-to-string Γ ff t2 ^ ")"
type-to-stringh Γ toplevel p (TpParens _ t _) = type-to-string Γ toplevel t
-- Here
type-to-stringh Γ toplevel p (TpVar pi x) = var-to-string Γ x
type-to-stringh Γ toplevel p (TpHole _) = "●" --ACG
type-to-stringh Γ toplevel p (NoSpans t _) = type-to-string Γ ff t

kind-to-stringh Γ toplevel p (KndArrow k k') =
  parens-unless toplevel (is-arrow p) (kind-to-string Γ ff k ^ " ➔ " ^ kind-to-stringh Γ ff (KndArrow k k') k')
kind-to-stringh Γ toplevel p (KndParens _ k _) = kind-to-string Γ toplevel k
kind-to-stringh Γ toplevel p (KndPi pi pi' x u k) = 
  parens-unless toplevel (is-abs p) ("Π " ^ x ^ " : " ^ tk-to-string Γ u ^ " . " ^ kind-to-stringh Γ ff (KndPi pi pi' x u k) k )
kind-to-stringh Γ toplevel p (KndTpArrow x k) =
  parens-unless toplevel (is-arrow p) (type-to-string Γ ff x ^ " ➔ " ^ kind-to-stringh Γ ff (KndTpArrow x k) k)
kind-to-stringh Γ toplevel p (KndVar _ x ys) = x ^ args-to-string Γ ys
kind-to-stringh Γ toplevel p (Star _) = "★"

arg-to-string Γ (TermArg t) = term-to-string Γ ff t
arg-to-string Γ (TypeArg t) = type-to-string Γ ff t
args-to-string Γ (ArgsCons y ys) = " " ^ arg-to-string Γ y ^ args-to-string Γ ys
args-to-string _ (ArgsNil _) = ""

liftingType-to-stringh Γ p (LiftArrow t t₁) = 
  parens-unless ff (is-arrow p) (liftingType-to-string Γ t ^ " ➔ " ^ liftingType-to-stringh Γ (LiftArrow t t₁) t₁ )
liftingType-to-stringh Γ p (LiftTpArrow t t₁) = 
  parens-unless ff (is-arrow p) (type-to-string Γ ff t ^ " ➔ " ^ liftingType-to-stringh Γ (LiftTpArrow t t₁) t₁ )
liftingType-to-stringh Γ p (LiftParens _ t _) = liftingType-to-string Γ t
liftingType-to-stringh Γ p (LiftPi pi x x₁ t) = 
  parens-unless ff (is-abs p) ("Π " ^ x ^ " : " ^ type-to-string Γ ff x₁ ^ " . " ^ liftingType-to-stringh Γ (LiftPi pi x x₁ t) t)
liftingType-to-stringh Γ p (LiftStar _) = "☆"

optClass-to-string _ NoClass = ""
optClass-to-string Γ (SomeClass x) = " : " ^ tk-to-string Γ x

optType-to-string _ NoType = ""
optType-to-string Γ (SomeType x) = " : " ^ type-to-string Γ ff x

maybeCheckType-to-string _ NoCheckType = ""
maybeCheckType-to-string Γ (Type x) = " ◂ " ^ type-to-string Γ ff x

optTerm-to-string _ NoTerm = ""
optTerm-to-string Γ (SomeTerm x _) = " { " ^ term-to-string Γ ff x ^ " }"
 
tk-to-string Γ (Tkk k) = kind-to-string Γ ff k
tk-to-string Γ (Tkt t) = type-to-string Γ ff t

lterms-to-stringh Γ (LtermsNil _) = ""
lterms-to-stringh Γ (LtermsCons m t ts) = " " ^ (maybeErased-to-string m) ^ term-to-string Γ ff t ^ lterms-to-stringh Γ ts

maybeAtype-to-string _ NoAtype = ""
maybeAtype-to-string Γ (Atype T) = type-to-string Γ ff T

to-string : {ed : exprd} → ctxt → ⟦ ed ⟧ → string
to-string{TERM} Γ = term-to-string Γ tt
to-string{TYPE} Γ = type-to-string Γ tt
to-string{KIND} Γ = kind-to-string Γ tt
to-string{LIFTINGTYPE} = liftingType-to-string
to-string{ARG} = arg-to-string
to-string{QUALIF} = qualif-to-string

to-string-if : ctxt → {ed : exprd} → maybe (⟦ ed ⟧) → string
to-string-if mΓ (just e) = to-string mΓ e
to-string-if _ nothing = "[nothing]"

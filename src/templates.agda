-- Generated by src/templates/TemplatesCompiler
module templates where
open import cedille-types
{-# FOREIGN GHC import qualified Templates #-}


-- src/templates/Mendler.ced
postulate
  templateMendler : start
{-# COMPILE GHC templateMendler = Templates.templateMendler #-}


-- src/templates/MendlerSimple.ced
postulate
  templateMendlerSimple : start
{-# COMPILE GHC templateMendlerSimple = Templates.templateMendlerSimple #-}

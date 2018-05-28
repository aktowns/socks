module Environment where

import           Control.Monad.State
import qualified Data.Map              as M
import qualified Data.Map.Merge.Strict as MM
import           Data.Text             (Text)
import           Debug.Trace           (traceM)
import           Formatting

import           Types

envLookup :: Text -> Context LVal
envLookup x = do
    (symtab, partab) <- get
    case (M.lookup x symtab, M.lookup x partab) of
        (Just v, _) -> return v -- prefer symtab
        (_, Just v) -> return v
        _           -> return $ Err $ sformat ("undefined variable " % stext) x

addSymbol :: Text -> LVal -> Context ()
addSymbol x val = do
    -- traceM $ "Inserting " ++ x ++ " into local environment"
    (symtab, partab) <- get
    put (M.insert x val symtab, partab)
    return ()

addSymbolParent :: Text -> LVal -> Context ()
addSymbolParent x val = do
    --traceM $ "Inserting " ++ x ++ " into global environment"
    (symtab, partab) <- get
    put (symtab, M.insert x val partab)
    return ()

clonedContext :: Context LVal -> Context LVal
clonedContext c = do
    (symtab, partab) <- get

    (val, (_, par)) <- lift $ runStateT c (symtab, partab)
    let newPartab = MM.merge MM.preserveMissing MM.preserveMissing (MM.zipWithMatched $ \_ _ y -> y) partab par

    put (symtab, newPartab)
    return val

traceEnv :: Context ()
traceEnv = do
    envs <- get
    traceM $ show envs

emptyEnv :: SymTab
emptyEnv = (M.fromList [], M.fromList [])

emptyPartialEnv :: [(Text, LVal)]
emptyPartialEnv = []

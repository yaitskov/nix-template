import Test.Tasty

import Prelude

main :: IO ()
main = myTestTree >>= defaultMain

myTestTree :: IO TestTree
myTestTree =
  pure $ testGroup "myhsapp" []

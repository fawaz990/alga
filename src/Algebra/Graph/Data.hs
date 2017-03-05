{-# LANGUAGE DeriveFunctor, DeriveFoldable, DeriveTraversable #-}
module Algebra.Graph.Data (Graph (..), fold) where

import Control.Monad
import Test.QuickCheck

import qualified Algebra.Graph as A
import Algebra.Graph hiding (Graph)
import Algebra.Graph.AdjacencyMap hiding (transpose)

data Graph a = Empty
             | Vertex a
             | Overlay (Graph a) (Graph a)
             | Connect (Graph a) (Graph a)
             deriving (Show, Functor, Foldable, Traversable)

instance A.Graph (Graph a) where
    type Vertex (Graph a) = a
    empty   = Empty
    vertex  = Vertex
    overlay = Overlay
    connect = Connect

instance Arbitrary a => Arbitrary (Graph a) where
    arbitrary = arbitraryGraph

    shrink Empty         = []
    shrink (Vertex    _) = [Empty]
    shrink (Overlay x y) = [Empty, x, y]
                        ++ [Overlay x' y' | (x', y') <- shrink (x, y) ]
    shrink (Connect x y) = [Empty, x, y, Overlay x y]
                        ++ [Connect x' y' | (x', y') <- shrink (x, y) ]

instance Num a => Num (Graph a) where
    fromInteger = Vertex . fromInteger
    (+)         = Overlay
    (*)         = Connect
    signum      = const Empty
    abs         = id
    negate      = id

instance Ord a => Eq (Graph a) where
    x == y = fold x == (fold y :: AdjacencyMap a)

instance Applicative Graph where
    pure  = vertex
    (<*>) = ap

instance Monad Graph where
    return = vertex
    (>>=)  = flip foldMapGraph

fold :: A.Graph g => Graph (Vertex g) -> g
fold = foldMapGraph vertex

foldMapGraph :: A.Graph g => (a -> g) -> Graph a -> g
foldMapGraph _ Empty         = empty
foldMapGraph f (Vertex  x  ) = f x
foldMapGraph f (Overlay x y) = overlay (foldMapGraph f x) (foldMapGraph f y)
foldMapGraph f (Connect x y) = connect (foldMapGraph f x) (foldMapGraph f y)
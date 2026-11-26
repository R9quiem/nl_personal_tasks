module Main where

import Control.Exception (IOException, catch)
import Control.Monad (foldM)
import Data.List (intercalate)
import System.Environment (getArgs)
import System.Exit (die)
import Text.Read (readMaybe)

partitions :: Integer -> Integer -> [[Integer]]
partitions 0 _ = [[]]
partitions remaining limit =
    [ value : rest
    | value <- [min remaining limit, min remaining limit - 1 .. 1]
    , rest <- partitions (remaining - value) value
    ]

printPartition :: Integer -> [Integer] -> IO Integer
printPartition count values = do
    putStrLn (intercalate " + " (map show values))
    let nextCount = count + 1
    nextCount `seq` pure nextCount

run :: IO ()
run = do
    args <- getArgs
    number <- case args of
        [raw] -> case readMaybe raw of
            Just value | value > 0 -> pure value
            _ -> die "Error: expected a positive integer"
        _ -> die "Usage: partitions <positive integer>"
    count <- foldM printPartition 0 (partitions number number)
    putStrLn ("Total: " ++ show count)

reportError :: IOException -> IO ()
reportError errorValue = die ("Error: " ++ show errorValue)

main :: IO ()
main = run `catch` reportError

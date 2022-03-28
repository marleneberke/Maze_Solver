using Random
using PuzzleMaker

Random.seed!(101)

puzzle = PuzzleMaker.generate_puzzle(10)

PuzzleSolver.get_paths(puzzle)

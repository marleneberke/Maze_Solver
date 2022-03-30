using Gen
using PuzzleSolver

puzzle = ["S" 1 2 5; 1 0 0 1; 3 2 5 "F"]
correct_path = [CartesianIndex(1, 1), CartesianIndex(2, 1), CartesianIndex(3, 1), CartesianIndex(3, 2), CartesianIndex(3, 3)]
display(puzzle)
paths = PuzzleSolver.get_paths(puzzle) #not sure why I have to name the package. Seems I didn't have to do this with MetaGen
println(paths)
lengths = map(x -> length(x), paths)

puzzle_args = Puzzle_Args(paths, lengths, puzzle, correct_path)

params = PuzzleSolver.Params()

(trace, _) = Gen.generate(PuzzleSolver.gm, (10, params, puzzle_args))
display(get_choices(trace))
get_retval(trace)[end]

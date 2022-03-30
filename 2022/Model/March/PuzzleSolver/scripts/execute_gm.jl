using Gen
using PuzzleSolver
using Random

Random.seed!(1)

puzzle = ["S" 6 4 0 1 5 2; 1 0 7 0 4 0 7; 3 4 1 8 2 1 "F"]
correct_path = [CartesianIndex(2, 1), CartesianIndex(3, 1), CartesianIndex(3, 2), CartesianIndex(3, 3)]
display(puzzle)
paths = PuzzleSolver.get_paths(puzzle) #not sure why I have to name the package. Seems I didn't have to do this with MetaGen
#lengths = map(x -> length(x), paths)

puzzle_args = Puzzle_Args(paths, puzzle, correct_path)

params = PuzzleSolver.Params(p_thinking_mistake = 0.)

(trace, _) = Gen.generate(PuzzleSolver.gm, (10, params, puzzle_args))
display(get_choices(trace))
get_retval(trace)[end]

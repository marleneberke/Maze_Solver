using Gen
using Distributions
using StatsBase

include("../maze_generator.jl")
include("helper_functions.jl")
include("gm.jl")
include("inference.jl")

#################################################################################

Random.seed!(1);
h = 15
w = 15
m = maze(h,w);
printmaze(m);

#Random.seed!(4);
Random.seed!(2);

#################################################################################
node_matrix = Matrix{TreeNode}(undef, h, w)
for x = 1:h
    for y = 1:w
        neighbors = find_neighbors(x, y, m)
        node_matrix[x,y] = Node(Coordinate(x,y), neighbors)
    end
end

goal_location = Coordinate(h, w)

#################################################################################
S = 100 #number of steps (NOT time)
(trace, _) = Gen.generate(unfold_model, (S,))
println("generating is done")

choices = get_choices(trace)
retval = get_retval(trace)

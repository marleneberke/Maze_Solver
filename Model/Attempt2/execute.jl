using Gen
using Distributions
using StatsBase

include("../maze_generator.jl")
include("helper_functions.jl")
include("gm.jl")
#include("inference.jl")

#################################################################################

Random.seed!(1);
h = 10
w = 10
m = maze(h,w);
printmaze(m);

Random.seed!(3);

#################################################################################
#will not change. like ground truth
node_matrix = Matrix{Node}(undef, h, w)
for x = 1:h
    for y = 1:w
        neighbors = find_neighbors(x, y, m)
        node_matrix[x,y] = Node(Coordinate(x,y), neighbors)
    end
end

start = node_matrix[1, 1]
start_location = start.location
way_so_far = Coordinate[]
goal = node_matrix[h, w]
goal_location = goal.location

#################################################################################
T = 500
(trace, _) = Gen.generate(unfold_model, (T,));
#
choices = get_choices(trace)
retval = get_retval(trace)

locations = Array{Coordinate}(undef, T)
distracted = Array{Bool}(undef, T)
locations[1] = retval[1].current_location #starting value
distracted[1] = retval[1].distracted
for t = 2:T
    locations[t] = retval[2][t].current_location
    distracted[t] = retval[2][t].distracted
    println(locations[t])
    println(distracted[t])
end




outfile = "path.txt"
file = open(outfile, "w")

for i = 1:length(locations)
    println(file, locations[i])
end

close(file)

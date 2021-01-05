using Gen
using Distributions

include("../maze_generator.jl")
include("helper_functions.jl")
include("DLS_simple_gm.jl")
#include("old_DLS_simple.jl")
include("inference.jl")

#################################################################################

Random.seed!(1);
h = 10
w = 10
m = maze(h,w);
printmaze(m);

#################################################################################
node_matrix = Matrix{Node}(undef, h, w)
for x = 1:h
    for y = 1:w
        children = find_children(x, y, m)
        node_matrix[x,y] = Node(Coordinate(x,y), copy(children), copy(children)) #this way viable_children and children can change independently
    end
end

start_location = node_matrix[1, 1].location
way_so_far = Coordinate[]
goal_location = node_matrix[h, w].location

#################################################################################
T = 50
(trace, _) = Gen.generate(unfold_model, (T,));

choices = get_choices(trace)
retval = get_retval(trace)

locations = Array{Coordinate}(undef, T)
locations[1] = retval[1].current_location #init
for t = 2:T
    locations[t] = retval[2][t].current_location
end

println(locations)

computation_times = Array{Float64}(undef, T)
for t = 1:T
    computation_times[t] = trace[:chain => t => :find_best => :computation_time]
end
println(computation_times)


# #see if I can infer x and y from deterministic thing
unfold_pf_traces = unfold_particle_filter(10, locations, computation_times, 10)
#
#
# #how to access values in the traces from the particle filter.
# for i = 1:num_particles
#     for t = 1:T
#         unfold_pf_traces[i][:chain => t => :next_location]
#     end
# end

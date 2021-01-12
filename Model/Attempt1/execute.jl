using Gen
using Distributions

include("../maze_generator.jl")
include("helper_functions.jl")
#include("DLS_intersection_sensitivity.jl")
include("DLS_simple_gm.jl")
include("inference.jl")

#################################################################################

Random.seed!(1);
h = 10
w = 10
m = maze(h,w);
printmaze(m);

Random.seed!(3);

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
T = 30
(trace, _) = Gen.generate(unfold_model, (T,));
#
choices = get_choices(trace)
retval = get_retval(trace)
#
# locations = Array{Coordinate}(undef, T)
# locations[1] = retval[1].current_location #starting value
# for t = 2:T
#     locations[t] = retval[2][t].current_location
# end
#
# println(locations)
#
locations = Array{Coordinate}(undef, T)
movement_times = Array{Float64}(undef, T)
distracted = Array{Float64}(undef, T)
for t = 1:T
    locations[t] = trace[:chain => t => :next_location]
    movement_times[t] = trace[:chain => t => :find_best => :movement_time]
    distracted[t] = trace[:chain => t => :find_best => :distracted]
end
#println(locations) #doesn't have starting value
#println(movement_times)
#println(distracted)
#
#
# #see if I can infer x and y from deterministic thing
num_particles = 1
unfold_pf_traces = unfold_particle_filter(num_particles, locations, movement_times, num_particles)
#
# #
# #how to access values in the traces from the particle filter.
# inferred_distracted = zeros(T)
# for i = 1:num_particles
#     for t = 1:T
#         inferred_distracted[t] = inferred_distracted[t] + unfold_pf_traces[i][:chain => t => :find_best => :distracted]
#     end
# end
# inferred_distracted = inferred_distracted./num_particles
# MSE = sum((distracted .- inferred_distracted).^2)


#################################################################################
#Print to text file
outfile = "path.txt"
file = open(outfile, "w")

println(file, 0.0) #delay before drawing first
println(file, start_location)
for i = 1:length(locations)
    println(file, movement_times[i])
    println(file, locations[i])
end

close(file)

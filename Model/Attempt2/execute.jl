using Gen
using Distributions
using StatsBase

include("../maze_generator.jl")
include("helper_functions.jl")
include("gm.jl")
include("inference.jl")

#################################################################################

Random.seed!(1);
h = 10
w = 10
m = maze(h,w);
printmaze(m);

#Random.seed!(4);
Random.seed!(6);

#################################################################################
#will not change. like ground truth
node_matrix = Matrix{Node}(undef, h, w)
for x = 1:h
    for y = 1:w
        neighbors = find_neighbors(x, y, m)
        node_matrix[x,y] = Node(Coordinate(x,y), neighbors)
    end
end

start_location = node_matrix[1, 1].location
way_so_far = Coordinate[]
goal_location = node_matrix[h, w].location

#################################################################################
T = 300 #should be 150
(trace, _) = Gen.generate(unfold_model, (T,))
#
choices = get_choices(trace)
retval = get_retval(trace)

locations = Array{Coordinate}(undef, T)
distracted = Array{Bool}(undef, T)
for t = 1:T
    locations[t] = choices[:chain => t => :location]
    distracted[t] = choices[:chain => t => :distracted]
    #println(locations[t])
    #println(distracted[t])
end

max_tree_size = choices[:max_tree_size]
time_per_move = choices[:time_per_move]
time_per_thought = choices[:time_per_thought]
#
# locations = Array{Coordinate}(undef, T)
# distracted = Array{Bool}(undef, T)
# locations[1] = retval[1].current_location #starting value
# distracted[1] = retval[1].distracted
# for t = 2:T
#     locations[t] = retval[2][t].current_location
#     distracted[t] = retval[2][t].distracted
#     #println(locations[t])
#     #println(distracted[t])
# end
#


#################################################################################
#
# # #see if I can infer x and y from deterministic thing
num_particles = 1000
unfold_pf_traces = unfold_particle_filter(num_particles, locations, num_particles);
#
#
#how to access values in the traces from the particle filter.
inferred_distracted = zeros(T)
inferred_max_tree_sizes = zeros(num_particles)
inferred_times_per_move = zeros(num_particles)
inferred_times_per_thought = zeros(num_particles)
for i = 1:num_particles
    inferred_max_tree_sizes[i] = unfold_pf_traces[i][:max_tree_size]
    inferred_times_per_move[i] = unfold_pf_traces[i][:time_per_move]
    inferred_times_per_thought[i] = unfold_pf_traces[i][:time_per_thought]
    for t = 1:T
        inferred_distracted[t] = inferred_distracted[t] + unfold_pf_traces[i][:chain => t => :distracted]
    end
end
inferred_distracted = inferred_distracted./num_particles
MSE = sum((distracted .- inferred_distracted).^2)

where_distracted = locations[findall(x->x==true, distracted)] #check which coordinates that corresponds to
where_inferred_distracted = locations[findall(x->x>0.5, inferred_distracted)] #more than half of the particles say distracted

#remove all the stuff at (10,10)
filter!(x->x!=goal_location, where_distracted)
filter!(x->x!=goal_location, where_inferred_distracted)

#could do a more fine-grained comparison
where_distracted==where_inferred_distracted

#unfold_pf_traces[1][:chain => 199 => :distracted]
#################################################################################

outfile = "path.txt"
file = open(outfile, "w")

for i = 1:length(locations)
    println(file, locations[i])
end

close(file)

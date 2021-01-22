using Gen
using Distributions
using StatsBase

include("../maze_generator.jl")
include("helper_functions.jl")
include("gm.jl")
include("inference.jl")

#################################################################################

Random.seed!(6);
h = 15
w = 15
m = maze(h,w);
printmaze(m);

#Random.seed!(4);
Random.seed!(1);

#################################################################################
# node_matrix = Matrix{TreeNode}(undef, h, w)
# for x = 1:h
#     for y = 1:w
#         neigh = find_neighbors(x, y, m) #word neighbors is a function in the maze_genorator.jl script
#         node_matrix[x,y] = TreeNode(Coordinate(x,y), copy(neigh), Coordinate[], copy(neigh))
#     end
# end

goal_location = Coordinate(h, w)

#################################################################################
S = 160 #number of steps (NOT time) #30
(trace, _) = Gen.generate(unfold_model, (S,))
println("generating is done")

choices = get_choices(trace)
retval = get_retval(trace)
#retval[2][28].current_location

#figure out how many steps it was
T = 0
s = 0
while T==0
    global s = s+1
    try
        choices[:chain => s => :next_location]
    catch e
        global T = s-1
    end
end

locations = Array{Coordinate}(undef, T)
distracted = Array{Bool}(undef, T)
depth_limit = Array{Int64}(undef, T)
how_long_distracted = Array{Float64}(undef, T)
time_spent_here = Array{Float64}(undef, T)
#tests = Array{Bool}(undef, T)
for t = 1:T
    #tests[t] = choices[:chain => t => :test]
    locations[t] = choices[:chain => t => :next_location]
    distracted[t] = choices[:chain => t => :distracted]
    how_long_distracted[t] = choices[:chain => t => :how_long_distracted]
    depth_limit[t] = choices[:chain => t => :depth_limit]
    time_spent_here[t] = choices[:chain => t => :time_spent_here]
    #println(locations[t])
    #println(distracted[t])
end

speed_of_thought_factor = choices[:speed_of_thought_factor]


#################################################################################

# where_distracted = locations[findall(x->x==true, distracted).-1] #check which coordinates that corresponds to
# how_long_distracted[distracted]
# time_spent_here[distracted]

#################################################################################
# # #see if I can infer x and y from deterministic thing
# num_particles = 200 #the lower the probability of distraction, the more particles I need
# unfold_pf_traces = unfold_particle_filter(num_particles, locations, time_spent_here, num_particles);
# #
# #
# #how to access values in the traces from the particle filter.
# inferred_distracted = zeros(T)
# inferred_how_long_distracted = zeros(T)
# for i = 1:num_particles
#     for t = 1:T
#         inferred_distracted[t] = inferred_distracted[t] + unfold_pf_traces[i][:chain => t => :distracted]
#         inferred_how_long_distracted[t] = inferred_how_long_distracted[t] + unfold_pf_traces[i][:chain => t => :how_long_distracted]
#     end
# end
# inferred_distracted = inferred_distracted./num_particles
# inferred_how_long_distracted = inferred_how_long_distracted./num_particles
# MSE = sum((distracted .- inferred_distracted).^2)
#
# where_distracted = locations[findall(x->x==true, distracted).-1] #check which coordinates that corresponds to
# where_inferred_distracted = locations[findall(x->x>0.5, inferred_distracted).-1] #more than half of the particles say distracted
#
# #remove all the stuff at (10,10)
# filter!(x->x!=goal_location, where_distracted)
# filter!(x->x!=goal_location, where_inferred_distracted)
#
# #could do a more fine-grained comparison
# where_distracted==where_inferred_distracted
#
# #compare how long distracted
# how_long_distracted[findall(x->x==true, distracted)]
# inferred_how_long_distracted[findall(x->x==true, distracted)]


#################################################################################

outfile = "path.txt"
file = open(outfile, "w")

println(file, "0.0") #don't wait before drawing (1, 1)
println(file, "Coordinate(1, 1)") #print the start

for i = 1:length(locations)
    println(file, time_spent_here[i])
    println(file, locations[i])
end

close(file)

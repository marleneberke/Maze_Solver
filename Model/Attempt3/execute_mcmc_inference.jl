using Gen
using Distributions
using StatsBase
using PyPlot

include("../maze_generator.jl")
include("helper_functions.jl")
include("gm.jl")
include("MCMC_inference.jl")

#################################################################################

Random.seed!(4);
h = 7
w = 7
m = maze(h,w);
printmaze(m);

#Random.seed!(4);
Random.seed!(3);

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
f = open("path.txt")
lines = readlines(f)
n = length(lines)

locations = Array{Coordinate}(undef, Int((n-2)/2))
time_spent_here = Array{Float64}(undef, Int((n-2)/2))

for i = 3:n #skip the first two lines
    if iseven(i) #even lines have the locations
        s = lines[i]
        x,y = split(s, ",")
        _,x = split(x, "(")
        _,y = split(y, " ")
        y,_ = split(y, ")")
        locations[Int((i-2)/2)] = Coordinate(parse(Int64, x), parse(Int64, y))
    else
        time_spent_here[Int((i-1)/2)] = parse(Float64, lines[i])
    end
end

close(f)
#################################################################################
num_iter = 10 #the lower the probability of distraction, the more particles I need
#burnin = 5000 #throw out this many
inferred_how_long_distracted, tr = MCMC_inference(num_iter, locations, time_spent_here);

g = plt.hist(inferred_how_long_distracted[Int64(num_iter/2):num_iter], 50); #burnin is half the iterations



# #################################################################################
# # # #see if I can infer x and y from deterministic thing
# #
# #
# #how to access values in the traces from the particle filter.
# T = length(locations)
# inferred_distracted = zeros(T)
# inferred_how_long_distracted = zeros(T)
# hist = zeros(num_particles)
# for i = 1:num_particles
#     for t = 1:T
#         inferred_distracted[t] = inferred_distracted[t] + unfold_pf_traces[i][:chain => t => :distracted]
#         if t == 7
#             hist[i] = unfold_pf_traces[i][:chain => t => :how_long_distracted]
#         end
#         inferred_how_long_distracted[t] = inferred_how_long_distracted[t] + unfold_pf_traces[i][:chain => t => :how_long_distracted]
#     end
# end
# #println(hist)
# #g = plt.hist(hist, 50)
# inferred_distracted = inferred_distracted./num_particles
# inferred_how_long_distracted = inferred_how_long_distracted./num_particles
#
# #where_distracted = locations[findall(x->x==true, distracted).-1] #check which coordinates that corresponds to
# pushfirst!(locations, Coordinate(1, 1))
# #more than half of the particles say distracted. could do a more fine-grained comparison
# where_inferred_distracted = locations[findall(x->x>0.5, inferred_distracted)]
#
# for i = 1:length(inferred_distracted)
#     println(locations[i])
#     println(inferred_distracted[i])
#     println(inferred_how_long_distracted[i])
# end
#
# #compare how long distracted
# #how_long_distracted[findall(x->x==true, distracted)]
# inferred_how_long_distracted[findall(x->x>0.5, inferred_distracted)]

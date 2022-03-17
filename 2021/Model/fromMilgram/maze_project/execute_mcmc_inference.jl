using Gen
using Distributions
#using StatsBase #I think shuffle! is from StatsBase
#using PyPlot
#using Plotly

include("maze_generator.jl") #need to move this file into the folder
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
file_to_read = string(ARGS[1], ".txt") #so arg should be path1 or something like that

f = open(file_to_read)
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

t_pause = findfirst(time_spent_here.>60)
#################################################################################
num_iter = 500000 #the lower the probability of distraction, the more particles I need
#burnin = 5000 #throw out this many
inferred_how_long_distracted, tr = MCMC_inference(num_iter, locations, time_spent_here, t_pause);

#g = plt.hist(inferred_how_long_distracted[Int64(num_iter/2):num_iter], 50); #burnin is half the iterations


#################################################################################
#making barplot
distracted = mean(inferred_how_long_distracted[Int64(num_iter/2):num_iter])*10#speed_of_thought_factor
sd_distracted = std(10 .* inferred_how_long_distracted[Int64(num_iter/2):num_iter])
thinking = time_spent_here[t_pause] - distracted

# bar1 = [
#     "x" => ["shuffle model inferences"],
#     "y" => [distracted],
#     "name" => "Time distracted",
#     "type" => "bar"
# ]
# bar2 = [
#     "x" => ["shuffle model inferences"],
#     "y" => [thinking],
#     "name" => "Time thinking",
#     "type" => "bar"
# ]
# data = [bar1, bar2]
# layout = ["barmode" => "stack"]
# response = Plotly.plot(data, ["layout" => layout, "filename" => "stacked-bar", "fileopt" => "overwrite"])


#################################################################################
#make output file
outfile = string("output_", file_to_read, ".csv")
file = open(outfile, "w")
#header
print(file, "model_name, maze_name, pause_location, pause_time, mean_time_distracted, time_thinking, sd_time_distracted \n")
print(file, "Attempt5, ", "7_by_7_maze_4, ", locations[t_pause-1], ", ", time_spent_here[t_pause], ", ", distracted, ", ", thinking, ", ", sd_distracted, "\n")

close(file)

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

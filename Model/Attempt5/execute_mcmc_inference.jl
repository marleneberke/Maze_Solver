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
inferred_how_long_distracted, tr = MCMC_inference(num_iter, locations, time_spent_here, t_pause);

#################################################################################
#making barplot
distracted = mean(inferred_how_long_distracted[Int64(num_iter/2):num_iter])*10#speed_of_thought_factor
sd_distracted = std(10 .* inferred_how_long_distracted[Int64(num_iter/2):num_iter])
thinking = time_spent_here[t_pause] - distracted

#################################################################################
#make output file
outfile = string("output_", file_to_read, ".csv")
file = open(outfile, "w")
#header
print(file, "model_name, maze_name, pause_location, pause_time, mean_time_distracted, time_thinking, sd_time_distracted \n")
print(file, "Attempt5, ", "15_by_15_maze_6, ", locations[t_pause-1], ", ", time_spent_here[t_pause], ", ", distracted, ", ", thinking, ", ", sd_distracted, "\n")

close(file)

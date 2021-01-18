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
Random.seed!(1);

#################################################################################
goal_location = Coordinate(h, w)

#################################################################################
T = 1300 #time units
(trace, _) = Gen.generate(unfold_model, (T,));
println("generating is done")

choices = get_choices(trace)
retval = get_retval(trace)

locations = Array{Coordinate}(undef, T)
distracted = Array{Bool}(undef, T)
for t = 1:T
    locations[t] = choices[:chain => t => :current_location]
    distracted[t] = choices[:chain => t => :distracted]
    #println(locations[t])
    #println(distracted[t])
end

#################################################################################
num_particles = 1000
unfold_pf_traces = unfold_particle_filter(num_particles, locations, num_particles);

#how to access values in the traces from the particle filter.
inferred_distracted = zeros(T)
for i = 1:num_particles
    for t = 1:T
        inferred_distracted[t] = inferred_distracted[t] + unfold_pf_traces[i][:chain => t => :distracted]
    end
end
inferred_distracted = inferred_distracted./num_particles
MSE = sum((distracted .- inferred_distracted).^2)

where_distracted = locations[findall(x->x==true, distracted)] #check which coordinates that corresponds to
where_inferred_distracted = locations[findall(x->x>0.5, inferred_distracted)] #more than half of the particles say distracted

#remove all the stuff at (10,10)
locations_distracted = filter!(x->x!=goal_location, where_distracted)
filter!(x->x!=goal_location, where_inferred_distracted)

#could do a more fine-grained comparison that this
where_distracted==where_inferred_distracted

#################################################################################

outfile = "path.txt"
file = open(outfile, "w")

for i = 1:length(locations)
    println(file, locations[i])
end

close(file)

#################################################################################

outfile = "distracted.txt"
file = open(outfile, "w")

for i = 1:length(locations_distracted)
    println(file, locations_distracted[i])
end

close(file)

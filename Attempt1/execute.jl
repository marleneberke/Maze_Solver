using Gen

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


#################################################################################
T = 5
(trace, _) = Gen.generate(unfold_model, (T,));

choices = get_choices(trace)
retval = get_retval(trace)

locations = Array{Coordinate}(undef, T)
locations[1] = retval[1].current_location #init
#println(retval[1].current_location) #initial starting point
for t = 2:T
    #println(retval[2][t].current_location)
    locations[t] = retval[2][t].current_location
end

# #see if I can infer x and y from deterministic thing
unfold_pf_traces = unfold_particle_filter(10, locations, 10)
#
#
# #how to access values in the traces from the particle filter.
# for i = 1:num_particles
#     for t = 1:T
#         unfold_pf_traces[i][:chain => t => :x]
#     end
# end

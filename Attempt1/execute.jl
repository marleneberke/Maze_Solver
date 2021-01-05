using Gen

include("../maze_generator.jl")
include("helper_functions.jl")
include("DLS_simple_gm.jl")
include("inference.jl")

#################################################################################

Random.seed!(1);
h = 5
w = 5
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

goal_location = node_matrix[h, w].location
start_location = node_matrix[1, 1].location

#################################################################################
T = 5
(trace, _) = Gen.generate(unfold_model, (T,))

choices = get_choices(trace)
retval = get_retval(trace)

locations = Array{Coordinate}(undef, T)
locations[1] = retval[1].current_location
#println(retval[1].current_location) #initial starting point
for t = 2:T
    #println(retval[2][t].current_location)
    locations[t] = retval[2][t].current_location
end

#see if I can infer x and y from deterministic thing
unfold_pf_traces = unfold_particle_filter(500, locations, 500)


#how to access values in the traces from the particle filter.
for i = 1:num_particles
    for t = 1:T
        unfold_pf_traces[i][:chain => t => :next_location]
    end
end

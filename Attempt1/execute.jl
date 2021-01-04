using Gen

include("../maze_generator.jl")
include("helper_functions.jl")
include("DLS_simple_gm.jl")

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

goal_node = node_matrix[h, w]
start_node = node_matrix[1, 1]

#################################################################################
T = 4
(trace, _) = Gen.generate(unfold_model, (T,))

choices = get_choices(trace)
retval = get_retval(trace)

println(retval[1].current_node.location) #initial starting point
for t = 2:T
    println(retval[2][t].current_node.location)
end

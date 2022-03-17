using Random
using StatsBase
using Gen

include("maze_generator.jl")
include("helper_functions.jl")
include("DLS_solver_gen_version.jl")

################################################################################

node_matrix = Matrix{Node}(undef, h, w)
for x = 1:h
    for y = 1:w
        children = find_children(x, y, m)
        node_matrix[x,y] = Node(Coordinate(x,y), copy(children), copy(children)) #this way viable_children and children can change independently
    end
end

goal_node = node_matrix[h, w]
start_node = node_matrix[1,1]
way_so_far = [start_node.location]

# way_so_far = go(goal_node, start_node, node_matrix, way_so_far)
#
# println("final route ", way_so_far)

trace,_ = Gen.generate(go, (goal_node, start_node, node_matrix, way_so_far))
choices = Gen.get_choices(trace)

way_so_far = Gen.get_retval(trace)

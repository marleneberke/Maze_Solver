#This version just makes random choices at intersections

using Random
using StatsBase

include("maze_generator.jl")

#################################################################################
Random.seed!(1);
h = 10
w = 10
m = maze(h,w);
printmaze(m);

#################################################################################
struct Coordinate
    x::Int64
    y::Int64
end

struct Node
    location::Coordinate
    children::Array{Coordinate,1}
    viable_children::Array{Coordinate,1}
end

#################################################################################

function find_children(x::Int64, y::Int64, maze::Matrix)
    children = Coordinate[]
    #left
    if maze[2*x-1, 2*y]==0
        push!(children, Coordinate(x-1, y))
    end
    #right
    if maze[2*x+1, 2*y]==0
        push!(children, Coordinate(x+1, y))
    end
    #up
    if maze[2*x, 2*y-1]==0
        push!(children, Coordinate(x, y-1))
    end
    #down
    if maze[2*x, 2*y+1]==0
        push!(children, Coordinate(x, y+1))
    end
    return children
end

#################################################################################
function go(goal_node::Node, start_node::Node, node_matrix::Matrix{Node}, way_so_far::Array{Coordinate})
    current_node = start_node
    while current_node != goal_node
        next_node, node_matrix, way_so_far = move(current_node, node_matrix, way_so_far)
        current_node = next_node
    end
    return way_so_far
end

function move(current_node::Node, node_matrix::Matrix{Node}, way_so_far::Array{Coordinate})
    if length(current_node.viable_children)==0 #back all the way up to the last node that had a viable child
        current_node, way_so_far = backtrack(current_node.location, node_matrix, way_so_far); #now current node will definitely have a viable child
    end

    if length(current_node.viable_children)==1
        next_node_coor = current_node.viable_children[1] #moves one step
    else #move randomly one step
        next_node_coor = sample(current_node.viable_children)
    end

    #update stuff. updates the matrix as well. also, for some reason removes childrren, not just viable children
    next_node = node_matrix[next_node_coor.x, next_node_coor.y]
    filter!(x->x!=next_node_coor, current_node.viable_children)
    filter!(x->x!=current_node.location, next_node.viable_children)

    push!(way_so_far, next_node_coor)

    return next_node, node_matrix, way_so_far
end

#backtracks all the way to the previous node with a viable child
function backtrack(current_location::Coordinate, node_matrix::Matrix{Node}, way_so_far::Array{Coordinate})

    i = 1
    n = length(way_so_far)
    not_there_yet = true

    way_to_get_out = Coordinate[]

    node = Node
    while not_there_yet
        node_coor = way_so_far[n-i]
        push!(way_to_get_out, node_coor)
        node = node_matrix[node_coor.x, node_coor.y]
        not_there_yet = length(node.viable_children)==0
        i = i+1
    end

    for j in 1:length(way_to_get_out)
        push!(way_so_far, way_to_get_out[j])
    end

    return node, way_so_far
end

#################################################################################
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

Random.seed!(2);

way_so_far = go(goal_node, start_node, node_matrix, way_so_far)

println("final route ", way_so_far)


#################################################################################

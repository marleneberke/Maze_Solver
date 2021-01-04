################################################################################
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
#removes current_node from next_node's viable children and vice versa
function update(current_node::Node, next_node::Node)
    filter!(x->x!=next_node.location, current_node.viable_children)
    filter!(x->x!=current_node.location, next_node.viable_children)
end

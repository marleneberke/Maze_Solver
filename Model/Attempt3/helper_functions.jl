################################################################################
struct Coordinate
    x::Int64
    y::Int64
end

struct TreeNode
    location::Coordinate
    neighbors::Vector{Coordinate}
    parent::Union{Coordinate, Missing}
    children::Vector{Coordinate}
end

struct SearchNode
    location::Coordinate
    depth::Int64
end
#################################################################################
function find_neighbors(x::Int64, y::Int64, maze::Matrix)
    neighbors = Coordinate[]
    #left
    if maze[2*x-1, 2*y]==0
        push!(neighbors, Coordinate(x-1, y))
    end
    #right
    if maze[2*x+1, 2*y]==0
        push!(neighbors, Coordinate(x+1, y))
    end
    #up
    if maze[2*x, 2*y-1]==0
        push!(neighbors, Coordinate(x, y-1))
    end
    #down
    if maze[2*x, 2*y+1]==0
        push!(neighbors, Coordinate(x, y+1))
    end
    return neighbors
end

#################################################################################
#returns a heuristic for a position based on proximity to goal.
function heuristic(position::Coordinate, goal::Coordinate)
    return (abs(position.x - goal.x) + abs(position.y - goal.y)) #manhattan distance
end

#################################################################################
# function update(parent::Coordinate, children::Vector{Coordinate}, current_node_matrix::Matrix{TreeNode})
#     parent_node = current_node_matrix[parent.x, parent.y]
#     for child in children
#         child_node = current_node_matrix[child.x, child.y]
#         if !in(child_node.parents, parent) #update the child.
#             push!(child_node.parents, parent)
#             child_node.children = child_node.neighbors[in(child_node.parents, child_node.neighbors)].==0] #neighbors that are not in the parents
#         end
#         if in(parent_node.parents, child) #update the parent. if there's a child that's listed as a parent, remove it's listing as a parent, and add it to children
#             filter!(x->x==child, parent_node.parents)
#             parent_node.children = parent_node.neighbors[in(parent_node.parents, parent_node.neighbors)].==0]
#         end
#     end
# end

#################################################################################
#returns a path from from to to. Stipulating that from is above-stream of to. so trace to's parents back to from.
function find_path(from::Coordinate, to::Coordinate, search_tree::Matrix{TreeNode})


end

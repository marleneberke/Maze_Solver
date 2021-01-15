################################################################################
struct Coordinate
    x::Int64
    y::Int64
end

struct TreeNode
    location::Coordinate
    neighbors::Vector{Coordinate}
    parent::Vector{Coordinate} #want it to only ever have length 1, but it needs to be mutable
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
#make parent the parent of these children
function update(parent::Coordinate, children::Vector{Coordinate}, current_node_matrix::Matrix{TreeNode})
    parent_node = current_node_matrix[parent.x, parent.y]
    for child in children
        child_node = current_node_matrix[child.x, child.y]
        if isempty(child_node.parent)
            push!(child_node.parent, parent) #maybe only do this if child_node.parent is empty
        end
        filter!(x->x!=parent, child_node.children) #remove the parent from the children's children
    end
end

#################################################################################
#called when node is a dead end (has no children). want to remove node from it's parent's children, continue recursively until reaching intersection
function prune(node::TreeNode, current_node_matrix::Matrix{TreeNode})
    @assert isempty(node.children)
    location = node.location
    parent = node.parent[1]
    parent_node = current_node_matrix[parent.x, parent.y]
    filter!(x->x!=location, parent_node.children)
    if isempty(parent_node.children)
        prune(parent_node, current_node_matrix)
    end
end

#################################################################################
#called when the current node is a dead end (has no children). want to make its parent it's child, continue recursively until reaching intersection
#could combine with prune
function reverse(current_node::TreeNode, current_node_matrix::Matrix{TreeNode})
    @assert isempty(current_node.children)
    @assert length(current_node.parent)==1
    parent = current_node.parent[1]
    parent_node = current_node_matrix[parent.x, parent.y]
    push!(current_node.children, parent)
    if isempty(parent_node.children)
        reverse(parent_node, current_node_matrix)
    end
end
#################################################################################
#returns a path from from to to. Stipulating that from is up-stream of to. so trace to's parents back to from.
function find_path(from::Coordinate, to::Coordinate, current_node_matrix::Matrix{TreeNode})
    next = to
    path = Coordinate[]

    while next!=from
        push!(next, path)
        next_node = current_node_matrix[next_node.location.x, next_node.location.y]
        @assert length(next.parent)==1
        next = next.parent[1]
    end
    return path
end
#returns an array that starts with to and ends with the one before from

#################################################################################
#Conducts a DLS search. Stops if the goal is found. Returns the best location, it's value, and the counter
function conduct_search(best_location::Coordinate, best_val::Int64, counter::Int64)
    locations_to_visit = [SearchNode(current_location, 0)]
    while !isempty(locations_to_visit) & best_val > 0
        to_search = pop!(locations_to_visit)

        #evaluate to_search
        if to_search.location == goal_location
            best_val = 0
            best_location = to_search.location
        elseif isempty(to_search.children)
            #do dead-end stuff. remove the children
            prune(to_search, current_node_matrix)
        elseif heuristic(to_search.location, goal_location) < best_val
            best_val = heuristic(to_search.location, goal_location)
            best_location = best_location = to_search.location
        end

        #make to_search a parent of it's children, and remove it from it's children's children
        update(to_search.location, to_search.children, current_node_matrix) #make sure have the right parent-child relationships

        if to_search.depth < depth_limit
            push!(locations_to_visit, to_search.children...)
        end
        counter = counter + 1
    end

    return (best_location, best_val, counter)
end

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

mutable struct Search
    best_location::Coordinate
    best_val::Float64
    locations_to_visit::Vector{SearchNode}
    depth_limit::Int64
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
################################################################################
#make parent the parent of these children
function update_parent_child(parent::Coordinate, children::Vector{Coordinate}, current_node_matrix::Matrix{TreeNode})
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
function reverse(location::Coordinate, current_node_matrix::Matrix{TreeNode})
    current_node = current_node_matrix[location.x, location.y]
    #println("current_node ", current_node)
    @assert isempty(current_node.children)
    @assert length(current_node.parent)==1
    parent = current_node.parent[1]
    parent_node = current_node_matrix[parent.x, parent.y]
    push!(current_node.children, parent)
    if isempty(parent_node.children)
        reverse(parent_node.location, current_node_matrix)
    end
end
#################################################################################
#return a path from start to finish using BFS over the neighbors
function find_path(start::Coordinate, finish::Coordinate, current_node_matrix::Matrix{TreeNode})
    queue = [[start]]
    visited = Coordinate[]

    while length(queue) > 0
        #println("queue ", queue)
        path = pop!(queue)
        vertex = path[end]

        if vertex==finish
            return path
        end
        vertex_node = current_node_matrix[vertex.x, vertex.y]
        #println("vertex_node.neighbors ", vertex_node.neighbors)
        for neigh in vertex_node.neighbors
            #println("path ", path)
            if !(neigh in visited)
                new_path = push!(copy(path), neigh)
                #println("new_path ", new_path)
                push!(queue, new_path)
            end
            push!(visited, vertex)
        end
    end
end

#################################################################################
#continues a search. updates the search and the current_node_matrix
function conduct_search(current_location, search::Search, current_node_matrix::Matrix{TreeNode})
    to_search = pop!(search.locations_to_visit)
    to_search_node = current_node_matrix[to_search.location.x, to_search.location.y]
    if to_search.location!==current_location #don't evaluate it if it's the current location
        if to_search.location == goal_location
            search.best_val = 0
            search.best_location = to_search.location
        elseif isempty(to_search_node.children)
            #do dead-end stuff. remove the children
            prune(to_search_node, current_node_matrix)
        elseif heuristic(to_search.location, goal_location) < search.best_val
            search.best_val = heuristic(to_search.location, goal_location)
            search.best_location = to_search.location
        end
    end

    #make to_search a parent of it's children, and remove it from it's children's children
    update_parent_child(to_search.location, to_search_node.children, current_node_matrix) #make sure have the right parent-child relationships

    if to_search.depth < search.depth_limit
        for child in to_search_node.children
            push!(search.locations_to_visit, SearchNode(child, to_search.depth+1))
        end
    end

    return search, current_node_matrix
end

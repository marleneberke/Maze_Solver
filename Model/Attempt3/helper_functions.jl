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
# #returns a path from from to to. Stipulating that from is up-stream of to. so trace to's parents back to from.
# function find_path_upstream(from::Coordinate, to::Coordinate, current_node_matrix::Matrix{TreeNode})
#     next = to
#     path = Coordinate[]
#
#     while next!=from && next!=Coordinate(1, 1)
#         push!(path, next)
#         next_node = current_node_matrix[next.x, next.y]
#         @assert length(next_node.parent)==1
#         next = next_node.parent[1]
#     end
#     return path
# end
# #returns an array that starts with to and ends with the one before from

#################################################################################
# #returns a path from from to to. from and to must have a common parent
# function find_path_complex(from::Coordinate, to::Coordinate, current_node_matrix::Matrix{TreeNode})
#     path_to = find_path_upstream(Coordinate(1, 1), to, current_node_matrix)
#     push!(path_to, Coordinate(1, 1))
#     println("path_to ", path_to)
#     path_from = find_path_upstream(Coordinate(1, 1), from, current_node_matrix)
#     push!(path_from, Coordinate(1, 1))
#     println("path_from ", path_from)
#     #now I have paths going from (1, 1) to each
#
#     overlap = intersect(path_to, path_from)
#     intersection = overlap[1]
#     println("intersection ", intersection)
#
#     index_path_to = findfirst(isequal(intersection), path_to)
#     index_path_from = findfirst(isequal(intersection), path_from)
#
#     path = vcat(path_to[1:index_path_to], Base.reverse(path_from[2:index_path_from-1])) #reverses the path_from
#     return path
# end
# #returns an array that starts with to and ends with the one before from

#################################################################################
#Conducts a DLS search. Stops if the goal is found. Returns the best location, it's value, and the counter.
function conduct_search(current_location::Coordinate , best_location::Coordinate, best_val::Float64, counter::Int64, depth_limit::Int64, current_node_matrix::Matrix{TreeNode})
    #println("current_location ", current_location)
    locations_to_visit = [SearchNode(current_location, 0)] #don't want to actually consider the current location
    while !isempty(locations_to_visit) && (best_val > 0)
        to_search = pop!(locations_to_visit)
        to_search_node = current_node_matrix[to_search.location.x, to_search.location.y]
        #println("to_search_node ", to_search_node)
        #evaluate to_search
        #don't evalute the current_node
        if to_search.location!==current_location
            if to_search.location == goal_location
                best_val = 0
                best_location = to_search.location
            elseif isempty(to_search_node.children)
                #do dead-end stuff. remove the children
                prune(to_search_node, current_node_matrix)
            elseif heuristic(to_search.location, goal_location) < best_val
                best_val = heuristic(to_search.location, goal_location)
                best_location = to_search.location
            end
        end

        #println("best_val ", best_val)
        #println("best_location ", best_location)

        #make to_search a parent of it's children, and remove it from it's children's children
        update_parent_child(to_search.location, to_search_node.children, current_node_matrix) #make sure have the right parent-child relationships

        if to_search.depth < depth_limit# && to_search.location != goal_location #if you're at the goal, don't add its children
            shuffled = shuffle!(to_search_node.children)
            # if to_search.location == Coordinate(5, 1)
            #     println("shuffled ", shuffled)
            # end
            for child in shuffled#shuffle so the order isn't always the same
                # if to_search.location == Coordinate(5, 1)
                #     println("child ", child)
                # end
                push!(locations_to_visit, SearchNode(child, to_search.depth+1))
            end
        end
        counter = counter + 1


        #println("to_search ", to_search)
        #println("counter ", counter)
    end

    #println("counter ", counter)

    #There's a possiblity that this picks a location that's found later in the search to be a dead end.
    #If that happens, run the search again, but keep the old counter
    if best_location!=current_location && best_location!=goal_location && isempty(current_node_matrix[best_location.x, best_location.y].children)
        (best_location, best_val, _) = conduct_search(current_location, best_location, Inf, 0, depth_limit, current_node_matrix)
    end
    #println(best_location)
    #println(current_node_matrix[best_location.x, best_location.x])

    return (best_location, best_val, counter)
end

#################################################################################

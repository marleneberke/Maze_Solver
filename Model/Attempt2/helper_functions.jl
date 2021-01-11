################################################################################
struct Coordinate
    x::Int64
    y::Int64
end

struct Node
    location::Coordinate
    neighbors::Vector{Coordinate}
end

struct TreeNode
    location::Coordinate
    parent::Coordinate
    children::Vector{Coordinate}
end

struct Tree
    nodes::Matrix{Union{TreeNode, Missing}}
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

#count up the number of non-missing entries downstream from current location, including current location. recursive
function size_of_downstream_tree(current_location::Coordinate, search_tree::Matrix{Union{TreeNode, Missing}})
    if (ismissing(search_tree[current_location.x, current_location.y]) || isempty(search_tree[current_location.x, current_location.y].children))
        return 0
    end

    current_node = search_tree[current_location.x, current_location.y]
    n = length(current_node.children)
    results = Array{Float64, 1}(undef, n)
    for i = 1:n
        results[i] = size_of_downstream_tree(current_node.children[i], search_tree)
    end

    return 1 + sum(results)
end

#return a list of nodes that have the coordinates of nodes that aren't part of the search tree yet but are children of nodes
#in the search tree
function get_downstream_frontier(current_location::Coordinate, parent::Coordinate, search_tree::Matrix{Union{TreeNode, Missing}})

    if ismissing(search_tree[current_location.x, current_location.y])
        return [TreeNode(current_location, parent, filter!(x->x!=parent, node_matrix[current_location.x, current_location.y].neighbors))] #location, parent, children
    end
    current_node = search_tree[current_location.x, current_location.y]
    n = length(current_node.children)
    frontier = []
    for i = 1:n
        results = get_downstream_frontier(current_node.children[i], current_location, search_tree)
        for r = 1:length(results)
            push!(frontier, results[r])
        end
    end

    return frontier
end


#Given that node is a dead end (has no children), remove it from it's parent's chidren
function prune(node::TreeNode, search_tree::Matrix{Union{TreeNode, Missing}})
    #remove node from its parent's list of children
    parent = node.parent
    filter!(x->x!=node.location, search_tree[parent.x, parent.y].children)
    #search_tree[node.location.x, node.location.y] = missing #remove this node from the search tree
    if length(search_tree[parent.x, parent.y].children) < 1
        search_tree = prune(search_tree[parent.x, parent.y], search_tree)
    end
    return search_tree
end

#returns a path from the goal to the current node (backwards)
function find_path(current_location::Coordinate, goal_location::Coordinate, search_tree::Matrix{Union{TreeNode, Missing}})
    path_to_goal = []

    next = goal_location
    #work backwards
    while next!=current_location
        push!(path_to_goal, next)
        next = search_tree[next.x, next.y].parent
    end
    return path_to_goal
end

#find the most promising location currently in the search tree, and move toward it
function find_best_move(current_location::Coordinate, goal_location::Coordinate, search_tree::Matrix{Union{TreeNode, Missing}})
    best = Inf
    best_location = current_location

    (I, J) = size(search_tree)
    for i = 1:I
        for j = 1:J
            if !ismissing(search_tree[i, j]) && (search_tree[i, j].location!=current_location) && (!isempty(search_tree[i, j].children)) #has children (isn't dead end). goal will already have been identified and have path_to_goal if it's in the search tree
                eval = heuristic(search_tree[i, j].location, goal_location)
                if eval < best #doesn't address ties for best
                    best = eval
                    best_location = search_tree[i, j].location
                end
            end
        end
    end

    path = find_path(current_location, best_location, search_tree)
    return pop!(path)
end

#returns a heuristic for a position based on proximity to goal.
function heuristic(position::Coordinate, goal::Coordinate)
    return (abs(position.x - goal.x) + abs(position.y - goal.y)) #manhattan distance
end

function add_to_search_tree(to_add::TreeNode, search_tree::Matrix{Union{TreeNode, Missing}})
    search_tree[to_add.location.x, to_add.location.y] = to_add
    for child in to_add.children
        tree_node = TreeNode(child, start.location, filter!(x->x!=to_add.location, node_matrix[child.x, child.y].neighbors)) #location, parent, children
    end
    return search_tree
end

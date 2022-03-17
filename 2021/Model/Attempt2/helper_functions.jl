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

#return a list of TreeNodes that have the coordinates of nodes that aren't part of the search tree yet but are children of nodes
#in the search tree
function get_downstream_frontier(current_location::Coordinate, parent::Coordinate, search_tree::Matrix{Union{TreeNode, Missing}})

    if ismissing(search_tree[current_location.x, current_location.y])
        return [TreeNode(current_location, parent, filter!(x->x!=parent, deepcopy(node_matrix[current_location.x, current_location.y].neighbors)))] #location, parent, children. deepcopy of anything with node_matrix
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

#returns a path from the goal to the current node (backwards), so starts with goal and ends with a child of the current location
function find_path(current_location::Coordinate, goal_location::Coordinate, search_tree::Matrix{Union{TreeNode, Missing}})
    path_to_goal = []

    println("goal_location", goal_location)

    next = goal_location
    #work backwards
    while next!=current_location && next!=Coordinate(0,0) #last part is for dealing with getting all the way to the start
        push!(path_to_goal, next)
        next = search_tree[next.x, next.y].parent
        println("next ", next)
    end

    if next!=current_location #means don't have a path to the current location
        #means have a path from the goal location to the start. means the current location is not directly upstream of the goal.
        #so, search the upstream path from the current location until we find an intersection and then splice the two paths together
        path_from_current_location = []
        next = search_tree[current_location.x,current_location.y].parent
        while next ∉ path_to_goal
            push!(path_from_current_location, next)
            next = search_tree[next.x, next.y].parent
            println("next ", next)
        end
        push!(path_from_current_location, next) #push next location, which should be the overlap between the two paths

        #join the paths
        index_of_intersection = findall(x->x==next, path_to_goal)[1]

        r = reverse(path_from_current_location)
        println("index_of_intersection ", index_of_intersection)
        println("path_to_goal ", path_to_goal)
        #println("path_to_goal ", path_to_goal[1:index_of_intersection])
        truncated_path_to_goal = path_to_goal[1:(index_of_intersection-1)]
        path_to_goal = vcat(truncated_path_to_goal, r)
    end
    println("path_to_goal ", path_to_goal)
    return path_to_goal
end

#returns a path from the goal to the current node (backwards). this one is designed for when the goal node is not on the search tree because it's part of the frontier
#identical except for start
function find_path(current_location::Coordinate, goal_node::TreeNode, search_tree::Matrix{Union{TreeNode, Missing}})
    path_to_goal = []

    println("goal_node", goal_node)

    next = goal_node.location
    push!(path_to_goal, next)
    next = goal_node.parent
    println("next ", next)

    #work backwards
    while next!=current_location && next!=Coordinate(0,0) #last part is for dealing with getting all the way to the start
        push!(path_to_goal, next)
        next = search_tree[next.x, next.y].parent
        println("next ", next)
    end

    if next!=current_location #means don't have a path to the current location
        #means have a path from the goal location to the start. means the current location is not directly upstream of the goal.
        #so, search the upstream path from the current location until we find an intersection and then splice the two paths together
        path_from_current_location = []
        next = search_tree[current_location.x,current_location.y].parent
        while next ∉ path_to_goal
            push!(path_from_current_location, next)
            next = search_tree[next.x, next.y].parent
            println("next ", next)
        end
        push!(path_from_current_location, next) #push next location, which should be the overlap between the two paths

        #join the paths
        index_of_intersection = findall(x->x==next, path_to_goal)

        path_to_goal = vcat(path_to_goal[1:index_of_intersection-1], reverse(path_from_current_location))
    end
    println("path_to_goal ", path_to_goal)
    return path_to_goal
end

#find the most promising location on the frontier of the search tree downstream from current location and move toward it
function find_best_move(current_location::Coordinate, goal_location::Coordinate, search_tree::Matrix{Union{TreeNode, Missing}})
    frontier = get_downstream_frontier(current_location, search_tree[current_location.x,current_location.y].parent, search_tree)

    println("current_location in find_best_move ", current_location)
    println("frontier ", frontier)

    n = length(frontier)
    evals = Array{Float64, 1}(undef, n)
    for i = 1:n
        evals[i] = heuristic(frontier[i].location, goal_location)
    end
    val, index = findmin(evals)
    best_node = frontier[index]
    println("best node ", best_node)

    path = find_path(current_location, best_node, search_tree)
    return pop!(path)
end

#returns a heuristic for a position based on proximity to goal.
function heuristic(position::Coordinate, goal::Coordinate)
    return (abs(position.x - goal.x) + abs(position.y - goal.y)) #manhattan distance
end

function add_to_search_tree(to_add::TreeNode, search_tree::Matrix{Union{TreeNode, Missing}})
    search_tree[to_add.location.x, to_add.location.y] = to_add
    for child in to_add.children #prepping
        tree_node = TreeNode(child, to_add.location, filter!(x->x!=to_add.location, deepcopy(node_matrix[child.x, child.y].neighbors))) #location, parent, children. deepcopy so that node_matrix doesn't actually get changed
    end
    return search_tree
end

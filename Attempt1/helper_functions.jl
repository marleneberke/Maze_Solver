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

#################################################################################

#find the best way to go from a node. if it's a dead end, backtrack
#returns the next node
function find_best(max_depth::Int64, current_node::Node, node_matrix::Matrix{Node}, way_so_far::Array{Coordinate})
    #println("current_node ", current_node)
    candidates = current_node.viable_children;
    #evaluations will heuristic's the values for each path
    evaluations = Array{Float64, 1}(undef, length(candidates))
    for i = 1:length(candidates)
        #candidate_node = node_matrix[candidates[i].x, candidates[i].y]
        #give DLS a fake copy of the node_matrix and all the nodes. don't actually want the node_matrix changed.
        dpcpy_matrix = deepcopy(node_matrix)
        candidate_node = dpcpy_matrix[candidates[i].x, candidates[i].y]
        parent_node = dpcpy_matrix[current_node.location.x, current_node.location.y]
        update(candidate_node, parent_node)
        #evaluations[i] = DLS_wrapper(candidate_node, dpcpy_matrix, 1)
        evaluations[i] = DLS(candidate_node, dpcpy_matrix, max_depth)
    end
    #println("candidates ", candidates)
    #println("evaluations ", evaluations)
    val, index = findmin(evaluations)
    #if all deadends
    if val == Inf
        #remove the children
        for i = 1:length(candidates)
            candidate = candidates[1]#because candidates gets shorter every time
            candidate_node = node_matrix[candidate.x, candidate.y]
            update(candidate_node, current_node)
        end
        next_node, way_so_far = backtrack(current_node.location, node_matrix, way_so_far);
    else
        #update stuff
        next_node_coor = candidates[index] #best option
        next_node = node_matrix[next_node_coor.x, next_node_coor.y]
        update(current_node, next_node)
        push!(way_so_far, next_node_coor)
    end
    println("next_node ", next_node)
    return next_node, way_so_far
end

#implements a DLS that returns the best value possible from a given starting point
function DLS(current_node::Node, node_matrix::Matrix{Node}, depth::Int64)
    if current_node.location == goal_location
        return 0 #goal found
    end

    if (depth==0)
        return heuristic(current_node.location, goal_location)
    else
        n = length(current_node.viable_children)
        if (n==0) #deadend
            return Inf #deadend is very bad
        else
            results = Array{Float64, 1}(undef, n)
            for i = 1:n
                #do all the little updates
                child_location = current_node.viable_children[1] #at 1 because keep removing children so child_location gets shorter each time
                child_node = node_matrix[child_location.x, child_location.y]
                update(current_node, child_node)
                results[i] = DLS(child_node, node_matrix, depth-1)
            end
            return minimum(results) #return the best found value
        end
    end
end

#returns a heuristic for a position based on proximity to goal.
function heuristic(position::Coordinate, goal::Coordinate)
    return (abs(position.x - goal.x) + abs(position.y - goal.y)) #manhattan distance
end

#backtracks all the way to the previous node with a viable child
function backtrack(current_location::Coordinate, node_matrix::Matrix{Node}, way_so_far::Array{Coordinate})
    println("in backtrack")
    not_there_yet = true
    way_to_get_out = Coordinate[]

    node = Node
    while not_there_yet
        n = findfirst(isequal(current_location), way_so_far)
        node_coor = way_so_far[n-1]
        push!(way_to_get_out, node_coor)
        node = node_matrix[node_coor.x, node_coor.y]
        not_there_yet = length(node.viable_children)==0
        current_location = node.location
    end

    for j in 1:length(way_to_get_out)
        push!(way_so_far, way_to_get_out[j])
    end

    return node, way_so_far
end

#This version does a DLS after every move and probabilistically picks the next move

using Random
using StatsBase
using Gen

include("maze_generator.jl")
include("helper_functions.jl")

#################################################################################
@gen function go(goal_node::Node, start_node::Node, node_matrix::Matrix{Node}, way_so_far::Array{Coordinate})
    current_node = start_node
    k = 0; #k if for indexing  how many time find_best gets called
    while current_node != goal_node
        next_node, node_matrix, way_so_far = move(current_node, node_matrix, way_so_far, k)
        current_node = next_node
    end
    return way_so_far
end

@gen function move(current_node::Node, node_matrix::Matrix{Node}, way_so_far::Array{Coordinate}, k)
    if length(current_node.viable_children)==0 #back all the way up to the last node that had a viable child
        current_node, way_so_far = backtrack(current_node.location, node_matrix, way_so_far); #now current node will definitely have a viable child
    end

    if length(current_node.viable_children)==1 #go that way
        next_node_coor = current_node.viable_children[1] #moves one step
        #update stuff. should update the matrix as well.
        next_node = node_matrix[next_node_coor.x, next_node_coor.y]
        update(current_node, next_node)
        push!(way_so_far, next_node_coor)
    else #choose best option. if after search, options are bad, backtrack
        next_node, way_so_far = @trace(find_best(current_node, node_matrix, way_so_far), (:find_best, k))
        k = k + 1;
    end

    return next_node, node_matrix, way_so_far
end

#find the best way to go from a node. if it's a dead end, backtrack
#returns the next node
@gen function find_best(current_node::Node, node_matrix::Matrix{Node}, way_so_far::Array{Coordinate})
    #evaluations will heuristic's the values for each path
    candidates = current_node.viable_children;
    evaluations = Array{Float64, 1}(undef, length(candidates))

    lambda = 5
    depth_limit = @trace(poisson(lambda), (:depth_limit))

    for i = 1:length(candidates)
        #candidate_node = node_matrix[candidates[i].x, candidates[i].y]
        #give DLS a fake copy of the node_matrix and all the nodes. don't actually want the node_matrix changed.
        dpcpy_matrix = deepcopy(node_matrix)
        candidate_node = dpcpy_matrix[candidates[i].x, candidates[i].y]
        parent_node = dpcpy_matrix[current_node.location.x, current_node.location.y]
        update(candidate_node, parent_node)
        #evaluations[i] = DLS_wrapper(candidate_node, dpcpy_matrix, 1)
        # lambda = 5
        # depth_limit = @trace(poisson(lambda), (:depth_limit))
        evaluations[i] = DLS(candidate_node, dpcpy_matrix, depth_limit)
    end
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
        return next_node, way_so_far
    else
        #update stuff
        next_node_coor = candidates[index] #best option
        next_node = node_matrix[next_node_coor.x, next_node_coor.y]
        update(current_node, next_node)
        push!(way_so_far, next_node_coor)
        return next_node, way_so_far
    end
end

#implements a DLS that returns the best value possible from a given starting point
function DLS(current_node::Node, node_matrix::Matrix{Node}, depth::Int64)
    if current_node.location == goal_node.location
        return 0 #goal found
    end

    if (depth==0)
        return heuristic(current_node.location, goal_node.location)
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

#################################################################################

Random.seed!(1);
h = 10
w = 10
m = maze(h,w);
printmaze(m);

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

way_so_far = go(goal_node, start_node, node_matrix, way_so_far)

println("final route ", way_so_far)

#################################################################################
#Print to text file
outfile = "path.txt"
file = open(outfile, "w")

for i = 1:length(way_so_far)
    println(file, way_so_far[i])
end

close(file)
#################################################################################

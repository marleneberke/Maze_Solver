include("custom_distributions.jl")
include("helper_functions.jl")

struct State
    current_location::Coordinate
    current_node_matrix::Matrix{TreeNode}
end

#describes how to get from one state to the next
@gen function kernel(s::Int64, state::State, speed_of_thought_factor::Float64)
    current_location = state.current_location
    current_node_matrix = state.current_node_matrix

    if current_location == goal_location
        return state
    end

    #println("in kernel ", current_node_matrix[3, 1])
    #println("current_location ", current_location)
    ###########################################################################
    #do the search
    depth_limit = @trace(uniform_discrete(8, 8), :depth_limit)

    best_location = current_location
    best_val = Inf
    counter = 0#keeps track of how many places have been searched
    #Do the depth-first DLS
    best_location, best_val, counter = conduct_search(current_location, best_location, best_val, counter, depth_limit, current_node_matrix)

    #go towards the best_location
    if best_val == Inf #if the best value we came across was Inf, means we're in a dead end. redo search going backwards
        reverse(current_location, current_node_matrix)
        best_location, best_val, counter = conduct_search(current_location, best_location, best_val, counter, depth_limit, current_node_matrix)
    end

    path = find_path(current_location, best_location, current_node_matrix)
    next_location = path[2] #path[1] is our current location
    (x, y) = (next_location.x, next_location.y)

    next_location = @trace(location_distribution(x, y), :next_location)

    ###########################################################################
    #move times
    distracted = @trace(bernoulli(0.02), :distracted)
    if distracted
        how_long_distracted = @trace(geometric(0.02), :how_long_distracted) #could change to exponential if I want continuous, but then I'd need uniform to also be continuous

        #how_long_distracted = @trace(uniform_discrete(1, 20), :how_long_distracted) #could change to exponential if I want continuous, but then I'd need uniform to also be continuous
        println("how_long_distracted ", how_long_distracted)
    else
        how_long_distracted = @trace(uniform_discrete(0, 0), :how_long_distracted) #may need to change this
    end
    thinking_time = speed_of_thought_factor*(counter + how_long_distracted)
    movement_minimum = speed_of_thought_factor*6 #should be in same units of the counter. this is saying minimum "game speed" movement is same as searching 6 squares
    #movement_time = maximum([movement_minimum, thinking_time])
    #just to have movement_time be saved
    #@trace(uniform_discrete(movement_time, movement_time), :time_spent_here)
    sd = speed_of_thought_factor
    @trace(trunc_normal(Float64(thinking_time), Float64(sd), Float64(movement_minimum), 10000.0), :time_spent_here)
    ###########################################################################

    next_state = State(next_location, current_node_matrix)
    return next_state
end

chain = Gen.Unfold(kernel)
Gen.load_generated_functions()

@gen function unfold_model(S::Int64)
    #set parameters and such
    node_matrix = Matrix{TreeNode}(undef, h, w)
    for x = 1:h
        for y = 1:w
            neigh = find_neighbors(x, y, m)
            node_matrix[x,y] = TreeNode(Coordinate(x,y), copy(neigh), Coordinate[], copy(neigh)) #location, neighbors, children
        end
    end

    #println("in unfold ", node_matrix[3, 1])

    start_location = node_matrix[1, 1].location
    speed_of_thought_factor = @trace(uniform_discrete(5, 5), :speed_of_thought_factor)

    # record initial state
    init_state = State(start_location, node_matrix)

    # run `chain` function under address namespace `:chain`, producing a vector of states
    states = @trace(chain(S, init_state, speed_of_thought_factor), :chain)

    result = (init_state, states)
    return result
end

#This should be the same model at Attempt3 but using time units instead of steps to make inference tractible

include("custom_distributions.jl")
include("helper_functions.jl")

struct State
    current_location::Coordinate
    current_node_matrix::Matrix{TreeNode}
    distracted::Bool
    time_since_last_thought::Int64
    time_since_last_move::Int64
    search::Search
end

@gen function kernel(t::Int64, state::State, time_per_thought::Int64, time_per_move::Int64, depth_limit::Int64)
    current_location = state.current_location
    current_node_matrix = state.current_node_matrix
    distracted = state.distracted
    time_since_last_move = state.time_since_last_move
    time_since_last_thought = state.time_since_last_thought
    search = state.search

    current_location = @trace(location_distribution(current_location.x, current_location.y), :current_location)

    #2% chance of becoming newly distracted, 98% remaining distracted if already so
    distracted = @trace(bernoulli(0.02+distracted*0.96), :distracted)
    if distracted || current_location==goal_location #if distracted or at the goal, just return
        return State(current_location, current_node_matrix, distracted, time_since_last_move, time_since_last_thought, search)
    end

    ###########################################################################
    #thinking / searching part

    if time_since_last_thought >= time_per_thought && !isempty(search.locations_to_visit) && (search.best_val > 0) #if theres a search started and the goal hasn't been found yet
        search, current_node_matrix = conduct_search(current_location, search, current_node_matrix)
        time_since_last_thought = 0
    elseif time_since_last_thought >= time_per_thought && isempty(search.locations_to_visit) && (search.best_val == Inf) #means hit a dead end
        search.best_location = current_location
        search.best_val = Inf
        push!(search.locations_to_visit, SearchNode(current_location, 0))
        reverse(current_location, current_node_matrix)
        search, current_node_matrix = conduct_search(current_location, search, current_node_matrix)
        time_since_last_thought = 0
    else
        time_since_last_thought = time_since_last_thought + 1
    end
    ###########################################################################
    #moving part
    if time_since_last_move >= time_per_move && (isempty(search.locations_to_visit) || search.best_val==0) #if it's been enough time and either search is complete or the goal has been found
        path = find_path(current_location, search.best_location, current_node_matrix)
        next_location = path[2] #path[1] is our current location
        #restart the search from the new location
        search.best_location = next_location
        search.best_val = Inf
        push!(search.locations_to_visit, SearchNode(next_location, 0))
        time_since_last_move = 0
    else #stay where you are
        next_location = current_location
        time_since_last_move = time_since_last_move + 1
    end

    next_state = State(next_location, current_node_matrix, distracted, time_since_last_move, time_since_last_thought, search)
    return next_state
end

chain = Gen.Unfold(kernel)
Gen.load_generated_functions()

@gen function unfold_model(T::Int64)
    #set parameters and such
    node_matrix = Matrix{TreeNode}(undef, h, w)
    for x = 1:h
        for y = 1:w
            neigh = find_neighbors(x, y, m)
            node_matrix[x,y] = TreeNode(Coordinate(x,y), copy(neigh), Coordinate[], copy(neigh)) #location, neighbors, children
        end
    end

    start_location = node_matrix[1, 1].location
    time_per_thought = @trace(uniform_discrete(2, 2), :time_per_thought)
    time_per_move = @trace(uniform_discrete(5, 5), :time_per_move)
    depth_limit = @trace(uniform_discrete(5, 5), :depth_limit)

    search = Search(start_location, Inf, [SearchNode(start_location, 0)], depth_limit)

    # record initial state
    init_state = State(start_location, node_matrix, false, 0, 0, search)

    # run `chain` function under address namespace `:chain`, producing a vector of states
    states = @trace(chain(T, init_state, time_per_thought, time_per_move, depth_limit), :chain)

    result = (init_state, states)
    return result
end

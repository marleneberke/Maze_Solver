include("custom_distributions.jl")
include("helper_functions.jl")

struct State
    current_location::Coordinate
    current_node_matrix::Matrix{Union{Node, TreeNode}}
end

#describes how to get from one state to the next
@gen function kernel(s::Int64, state::State, speed_of_thought_factor::Float64)
    current_location = state.current_location
    current_node_matrix = state.current_node_matrix

    if current_location == goal_location
        return state
    end

    ###########################################################################
    #do the search
    depth_limit = @trace(uniform(8, 8), :depth_limit)

    best_val = Inf
    best_location = current_location
    locations_to_visit = [SearchNode(current_location, 0)]
    global counter = 0;#keeps track of how many places have been searched
    #Do the depth-first DLS
    while !isempty(locations_to_visit)
        to_search = pop!(locations_to_visit)

        #evaluate to_search
        if to_search.location == goal_location
            best_val = 0
            best_location = to_search.location
        elseif isempty(to_search.children)
            #do dead-end stuff
        elseif heuristic(to_search.location, goal_location) < best_val
            best_val = heuristic(to_search.location, goal_location)
            best_location = best_location = to_search.location
        end

        update(to_search.location, to_search.children, current_node_matrix) #make sure have the right parent-child relationships

        if to_search.depth < depth_limit
            push!(locations_to_visit, to_search.children...)
        end
        counter = counter + 1
    end

    #if the best value we came across was Inf, means we're in a dead end. redo search going backwards
    while best_val==Inf

    end

    #go towards the best_location
    path = find_path(current_location, best_location)
    pop!(path) #or pop first idk



    next_location = @trace(location_distribution(x, y), :next_location)


    ###########################################################################
    #move times
    distracted = @trace(bernoulli(0.05), :distracted)
    if distracted
        how_long_distracted = @trace(exponential(0.2), :how_long_distracted)
    end
    thinking_time = speed_of_thought_factor*counter + how_long_distracted
    movement_minimum = 5 #should be in same units of the counter
    movement_time = maximum(movement_minimum, thinking_time)
    #just to have movement_time be saved
    @trace(uniform(movement_time, movement_time), :time_spent_here)
    ###########################################################################


    return next_state
end

chain = Gen.Unfold(kernel)
Gen.load_generated_functions()

@gen function unfold_model(S::Int64)
    #set parameters and such
    node_matrix = Matrix{TreeNode}(undef, h, w)
    for x = 1:h
        for y = 1:w
            neighbors = find_neighbors(x, y, m)
            node_matrix[x,y] = TreeNode(Coordinate(x,y), neighbors, missing, Coordinate[]) #location, neighbors, children
        end
    end

    start_location = node_matrix[1, 1].location
    node_matrix[1, 1].children = copy(neighbors)
    speed_of_thought_factor = @trace(uniform(5, 5), :speed_of_thought_factor)

    # record initial state
    init_state = State(start_location, node_matrix)

    # run `chain` function under address namespace `:chain`, producing a vector of states
    states = @trace(chain(S, init_state, speed_of_thought_factor), :chain)

    result = (init_state, states)
    return result
end
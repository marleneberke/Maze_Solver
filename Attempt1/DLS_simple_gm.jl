struct State
    current_node::Node
    current_node_matrix::Matrix{Node}
end

#describes how to get from one state to the next
@gen function kernel(t::Int64, prev_state::State)
    #really simple test

    current_node = prev_state.current_node
    current_node_matrix = prev_state.current_node_matrix

    #if you've already hit the goal
    if current_node == goal_node
        next_node = current_node
    else #conduct a search with addressed randomness
        x = @trace(uniform_discrete(1, w), :x)
        y = @trace(uniform_discrete(1, h), :y)
        next_node = current_node_matrix[x, y]
    end

    next_state = State(next_node, current_node_matrix)

    return next_state
end

chain = Gen.Unfold(kernel)
Gen.load_generated_functions()

@gen function unfold_model(T::Int64)
    #set parameters and such

    # record initial state
    init_state = State(start_node, node_matrix)

    # run `chain` function under address namespace `:chain`, producing a vector of states
    states = @trace(chain(T, init_state), :chain)

    result = (init_state, states)
    return result
end

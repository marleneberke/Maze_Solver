struct State
    current_node::Node
    current_node_matrix::Matrix{Node}
end

#describes how to get from one state to the next
@gen function kernel(t::Int64, prev_state::State)
    #really simple test

    current_node = prev_state.current_node
    current_node_matrix = prev_state.current_node_matrix

    #just go down from prev_node until hitting end of maze
    if current_node.location.y < w
        next_node = current_node_matrix[current_node.location.x, current_node.location.y+1]
    else
        next_node = current_node
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

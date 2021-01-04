struct State
    current_node::Node
    current_node_matrix::Matrix{Node}
end

#describes how to get from one state to the next
@gen function kernel(t::Int64, prev_state::State)


    return next_state
end

chain = Gen.Unfold(kernel)
Gen.load_generated_functions()

@gen function unfold_model(T::Int64)
    #set parameters and such

    # record initial state
    init_state = State()

    # run `chain` function under address namespace `:chain`, producing a vector of states
    states = @trace(chain(T, init_state), :chain)

    result = (init_state, states)
    return result
end

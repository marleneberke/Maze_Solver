include("custom_distributions.jl")
include("helper_functions.jl")

struct State
    current_location::Coordinate
    current_node_matrix::Matrix{Node}
    way_so_far::Array{Coordinate}
end

#describes how to get from one state to the next
@gen function kernel(t::Int64, prev_state::State)
    println("t ", t)
    #really simple test
    #println("prev_state kernel ", prev_state)

    current_location = prev_state.current_location
    println("current_location kernel ", current_location)
    current_node_matrix = prev_state.current_node_matrix
    current_node = current_node_matrix[current_location.x, current_location.y]
    way_so_far = prev_state.way_so_far

    max_depth = @trace(poisson(10), :max_depth)
    #find the next move
    next_node, way_so_far = find_best(max_depth, current_node, current_node_matrix, way_so_far)
    println("next_node in kernel ", next_node)

    x = next_node.location.x
    y = next_node.location.y

    println("x ", x)
    println("y ", y)
    next_location = @trace(location_distribution(x, y), :next_location)
    #next_location = current_node_matrix[x, y].location


    println("next_location ", next_location)
    next_state = State(next_location, current_node_matrix, way_so_far)
    #println("next_state ", next_state)

    return next_state
end

chain = Gen.Unfold(kernel)
Gen.load_generated_functions()

@gen function unfold_model(T::Int64)
    #set parameters and such
    node_matrix = Matrix{Node}(undef, h, w)
    for x = 1:h
        for y = 1:w
            children = find_children(x, y, m)
            node_matrix[x,y] = Node(Coordinate(x,y), copy(children), copy(children)) #this way viable_children and children can change independently
        end
    end

    goal_location = node_matrix[h, w].location
    start_location = node_matrix[1, 1].location
    way_so_far = Coordinate[]


    # record initial state
    init_state = State(start_location, node_matrix, way_so_far)

    # run `chain` function under address namespace `:chain`, producing a vector of states
    states = @trace(chain(T, init_state), :chain)

    println("here")

    result = (init_state, states)
    return result
end

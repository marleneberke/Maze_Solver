using Gen

include("parse_puzzle_and_helpers.jl")
costs = lengths

struct State
    possible_paths::Vector{Any}
    estimated_costs::Vector{Int64}
    thinking_units_used::Int64
    goal_found::Bool
end

#returns:
#boolean for if evaluation says the path leads to the finish
#amount of time it took to think
@gen function evaluate(path_to_check::Int64, state::State)
    mistake_rate = 0.1
    where_mistake = @trace(geometric(mistake_rate), :where_mistake)

    #implement mistakes later.
    # if where_mistake < evals_until_end
    #     works = !works
    #     eval_length = where_mistake
    # end

    # if state.goal_found
    #     return state
    # end

    possible_path = state.possible_paths[path_to_check]
    works, evals_until_end = evaluate_rule(possible_path)

    thinking_units_used = state.thinking_units_used + evals_until_end

    if works
        #println("works")
        possible_paths = [possible_path]
        estimated_costs = [0]
        goal_found = true
    else
        possible_paths = state.possible_paths
        possible_paths = deleteat!(possible_paths, path_to_check)
        estimated_costs = state.estimated_costs
        estimated_costs = deleteat!(estimated_costs, path_to_check)
        goal_found = false
    end

    #adjust state in some way
    next_state = State(possible_paths, estimated_costs, thinking_units_used, goal_found)

    return next_state
end


@gen function kernel(i::Int64, state::State)
    if state.goal_found || length(state.possible_paths)==0 #if done
        return state
    end


    #ps = (maximum(state.estimated_costs) + 1) .- state.estimated_costs #+1 is so each p > 1
    #println(ps)
    #path_to_check = @trace(categorical(ps./sum(ps)), :path_to_check)
    ps = softmax(state.estimated_costs, 0.5) #tau = 0 means perfectly rational
    println("ps ", ps)
    path_to_check = @trace(categorical(ps), :path_to_check)

    next_state = @trace(evaluate(path_to_check, state), :evaluation)

    return next_state
end

chain = Gen.Unfold(kernel)
Gen.load_generated_functions()

@gen function gm(max::Int64) #max is max number of paths would evaluate
    init_state = State(paths, costs, 0, false)
    println("init_state ", init_state)
    states = @trace(chain(max, init_state), :chain)

    time_per_unit_think = @trace(normal(100, 1), :time_per_unit_think)
    total_time = @trace(normal(states[end].thinking_units_used*time_per_unit_think, 0.01), :total_time)
    return states
end

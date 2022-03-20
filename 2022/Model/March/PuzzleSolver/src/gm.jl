Base.@kwdef struct State
    possible_paths::Vector{Any}
    estimated_costs::Vector{Int64}
    thinking_units_used::Int64
    goal_found::Bool
end

Base.@kwdef struct Params #assuming p_guessing and p_already knew can't both the the case
    tau_softmax::Float64 = 0.5 #tau = 0 means perfectly rational
    mu_time_per_unit_think::Float64 = 100.
    sd_time_per_unit_think::Float64 = 1.
    lambda_distracted::Float64 = 10000. #bigger means less often distracted
    p_already_knew::Float64 = 0.00001
    p_guessing::Float64 = 0.00001
    p_mistake_action_level::Float64 = 0.00001
    p_thinking_mistake = 0.05
end

#Evaluate if a possible path follows the up-down rule.
#Return how many comparisons were needed to assess if it follows the rule.
@gen function evaluate_rule(possible_path::Vector{Any}, puzzle::Matrix{Any}, params::Params)
    if puzzle[possible_path[1]] == "S"
        possible_path = possible_path[2:end]
    end

    if length(possible_path) == 1
        return true, 0 #no eval needed
    end

    i = 1
    rule_not_broken = true
    previous_up = true
    previous_down = true
    while i < length(possible_path) && rule_not_broken
        up = puzzle[possible_path[i]] < puzzle[possible_path[i+1]]
        down = puzzle[possible_path[i]] > puzzle[possible_path[i+1]]
        rule_not_broken = (previous_down && up) || (previous_up && down)
        thinking_mistake = @trace(bernoulli(params.p_thinking_mistake), :(thinking_mistake, i))
        rule_not_broken = thinking_mistake ? !rule_not_broken : rule_not_broken #if there's a thinking mistake, flip the evaluation
        i = i + 1
        previous_up = up
        previous_down = down
    end

    return rule_not_broken, i-1
end

#returns:
#boolean for if evaluation says the path leads to the finish
#amount of time it took to think
@gen function evaluate(path_to_check::Int64, state::State, params::Params, puzzle::Matrix{Any})
    possible_path = state.possible_paths[path_to_check]
    works, evals_until_end = evaluate_rule(possible_path, puzzle, params)
    println("evals_until_end ", evals_until_end)

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


@gen function kernel(i::Int64, state::State, params::Params, puzzle::Matrix{Any})
    if state.goal_found || length(state.possible_paths)==0 #if done
        return state
    end

    # guess = @trace(bernoulli(params.p_guess), :guess)
    # if guess
    #     next_state =
    # end

    ps = softmax(state.estimated_costs, params.tau_softmax)
    println("ps ", ps)
    path_to_check = @trace(categorical(ps), :path_to_check)

    next_state = @trace(evaluate(path_to_check, state, params, puzzle), :evaluation)

    return next_state
end

chain = Gen.Unfold(kernel)
Gen.load_generated_functions()

@gen function gm(max::Int64, paths::Vector{Any}, costs::Vector{Int64}, params::Params, puzzle::Matrix{Any}, correct_path::Vector{CartesianIndex{2}})
    already_knew = @trace(bernoulli(params.p_already_knew), :already_knew)
    init_state = already_knew ? State(correct_path, costs, 0, true) : State(paths, costs, 0, false)

    guessing = @trace(bernoulli(params.p_guessing), :guessing)
    init_state = guessing ? State(rand(paths), costs, 0, true) : State(paths, costs, 0, false)

    println("init_state ", init_state)
    states = @trace(chain(max, init_state, params, puzzle), :chain)

    chosen_path = @trace(choose_path_distribution(push!(paths, []), states[end].possible_paths, params.p_mistake_action_level), :chosen_path)

    time_distracted = @trace(exponential(params.lambda_distracted), :time_distracted)
    time_per_unit_think = @trace(normal(params.mu_time_per_unit_think, params.sd_time_per_unit_think), :time_per_unit_think)
    total_time = @trace(normal((states[end].thinking_units_used*time_per_unit_think + time_distracted), params.sd_time_per_unit_think), :total_time)
    return states
end

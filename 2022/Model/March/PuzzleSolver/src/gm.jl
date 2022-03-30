#Evaluate if a segement follows the up-down rule.
#Return how many comparisons were needed to assess if it follows the rule.
@gen function evaluate_rule(segment::Vector{Any}, params::Params, puzzle::Matrix{Any})
    if puzzle[segment[1]] == "S"
        segment = segment[2:end]
    end

    if length(segment) == 1
        return true, 0 #no eval needed
    end

    i = 1
    rule_not_broken = true
    previous_up = true
    previous_down = true
    while i < length(segment) && rule_not_broken
        up = puzzle[segment[i]] < puzzle[segment[i+1]]
        down = puzzle[segment[i]] > puzzle[segment[i+1]]
        rule_not_broken = (previous_down && up) || (previous_up && down)
        thinking_mistake = @trace(bernoulli(params.p_thinking_mistake), :thinking_mistake => i)
        rule_not_broken = thinking_mistake ? !rule_not_broken : rule_not_broken #if there's a thinking mistake, flip the evaluation
        i = i + 1
        previous_up = up
        previous_down = down
    end

    return rule_not_broken, i-1
end

@gen function evaluate_segments(segments::Vector{Any}, params::Params, puzzle::Matrix{Any})
    j = 1
    works = true
    total_evals = 0
    section_last_evaluated = []
    evals_until_end = 0
    while works && j <= length(segments)
        #println("segments[j] ", segments[j])
        works, evals_until_end = @trace(evaluate_rule(segments[j], params, puzzle), :mistakes => j)
        total_evals = total_evals + evals_until_end
        section_last_evaluated = segments[j][evals_until_end-1 : evals_until_end+1] #not quite right for all segment lengths but close
        j = j + 1
    end
    return works, total_evals, j-1, section_last_evaluated, evals_until_end+1
end



#returns:
#boolean for if evaluation says the path leads to the finish
#amount of time it took to think
#updated state
@gen function evaluate(path_to_check::Int64, state::State, params::Params, puzzle::Matrix{Any})
    println("to check ", state.segments_of_path_to_be_checked[path_to_check])
    works, total_evals, n_segments_evaluated, section_last_evaluated, where_left_off = @trace(evaluate_segments(state.segments_of_path_to_be_checked[path_to_check], params, puzzle), :evaluate_segments)
    println("works ", works)
    return update_state(state, path_to_check, works, total_evals, n_segments_evaluated, section_last_evaluated, where_left_off)
end

@gen function kernel(i::Int64, state::State, params::Params, puzzle::Matrix{Any})
    if state.goal_found || length(state.possible_paths)==0 #if done
        return state
    end

    # guess = @trace(bernoulli(params.p_guess), :guess)
    # if guess
    #     next_state =
    # end
    # estimated_costs = estimate_costs(state)
    # ps = softmax(estimated_costs, params.tau_softmax)
    # #println("ps ", ps)
    # path_to_check = @trace(categorical(ps), :path_to_check)
    path_to_check = 1 #for debugging purposes

    next_state = @trace(evaluate(path_to_check, state, params, puzzle), :evaluation)

    return next_state
end

chain = Gen.Unfold(kernel)
Gen.load_generated_functions()

@gen function gm(max::Int64, params::Params, puzzle_args::Puzzle_Args)
    puzzle_args = deepcopy(puzzle_args)

    init_state = State(puzzle_args.paths, make_double_array(puzzle_args.paths), 0, false)
    println("init_state: ", init_state)
    # already_knew = @trace(bernoulli(params.p_already_knew), :already_knew)
    # init_state = already_knew ? State(puzzle_args.correct_path, puzzle_args.costs, 0, true) : State(puzzle_args.paths, puzzle_args.costs, 0, false)
    #
    # guessing = @trace(bernoulli(params.p_guessing), :guessing)
    # init_state = guessing ? State(rand(puzzle_args.paths), puzzle_args.costs, 0, true) : State(puzzle_args.paths, puzzle_args.costs, 0, false)
    #
    # distracted = @trace(bernoulli(params.p_distracted), :distracted) #if distracted, guess, don't think
    # init_state = distracted ? State(rand(puzzle_args.paths), puzzle_args.costs, 0, true) : State(puzzle_args.paths, puzzle_args.costs, 0, false)

    #println("init_state ", init_state)
    states = @trace(chain(max, init_state, params, puzzle_args.puzzle), :chain)

    # #chosen_path = @trace(choose_path_distribution(push!(paths, []), states[end].possible_paths, params.p_mistake_action_level), :chosen_path)
    # #write the categorical version for now (so as to keep moving forward)
    # paths = push!(paths, [])
    # desired_path = states[end].possible_paths[1]
    # println(paths)
    # println(desired_path)
    # desired_index = findall(x -> x==desired_path, paths)[1]
    # n_options = length(paths)
    # if n_options==1
    #     ps = fill(1., 1)
    # else
    #     ps = fill(params.p_mistake_action_level/(n_options-1), n_options)
    #     ps[desired_index] = 1-params.p_mistake_action_level
    # end
    # chosen_path = @trace(categorical(ps), :categorical_path)
    # println(paths[chosen_path])

    #test = @trace(trunc_normal(1., 1, 0., 2.), :test)

    #time_distracted = @trace(exponential(params.lambda_distracted), :time_distracted)
    time_per_unit_think = @trace(normal(params.mu_time_per_unit_think, params.sd_time_per_unit_think), :time_per_unit_think)

    # total_time = distracted ?
    #     @trace(exponential(params.lambda_distracted), :total_time) :
    #     @trace(normal((states[end].thinking_units_used*time_per_unit_think), params.sd_time_per_unit_think), :total_time)

    @trace(normal((states[end].thinking_units_used*time_per_unit_think), params.sd_time_per_unit_think), :total_time)
    return states
end

export gm

function metropolis_hastings_homemade(
        trace, proposal::GenerativeFunction, proposal_args::Tuple;
        check=false, observations=EmptyChoiceMap())
    println("here in mh")
    model_args = get_args(trace)
    argdiffs = map((_) -> NoChange(), model_args)
    proposal_args_forward = (trace, proposal_args...,)
    (fwd_choices, fwd_weight, _) = propose(proposal, proposal_args_forward)
    (new_trace, weight, _, discard) = update(trace,
        model_args, argdiffs, fwd_choices)
    proposal_args_backward = (new_trace, proposal_args...,)
    (bwd_weight, _) = assess(proposal, proposal_args_backward, discard)
    println("weight ", weight)
    println("bwd_weight ", bwd_weight)
    println("fwd_weight ", fwd_weight)
    alpha = weight - fwd_weight + bwd_weight
    check && check_observations(get_choices(new_trace), observations)
    if log(rand()) < alpha
        # accept
        return (new_trace, true)
    else
        # reject
        return (trace, false)
    end
end

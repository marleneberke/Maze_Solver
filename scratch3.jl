using Gen

@gen function fun(T::Int64)
    heads = []
    prob = @trace(uniform(0, 1), :prob)
    for i = 1:T
        head = @trace(categorical([1.0, 0.0]), (:head, i))
        push!(heads, head)
    end
    return heads
end

trace,_ = Gen.generate(fun, (10,))
choices = Gen.get_choices(trace)
heads = Gen.get_retval(trace)

function particle_filter(num_particles::Int, heads, num_samples::Int)

    # construct initial observations
    init_obs = Gen.choicemap(((:head, 1), heads[1]))
    state = Gen.initialize_particle_filter(fun, (1,), init_obs, num_particles)

    # steps
    for i=2:length(heads)
        Gen.maybe_resample!(state, ess_threshold=num_particles/2)
        obs = Gen.choicemap(((:head, i), heads[i]))
        Gen.particle_filter_step!(state, (i,), (UnknownChange(),), obs)
    end

    # return a sample of unweighted traces from the weighted collection
    return Gen.sample_unweighted_traces(state, num_samples)
end;

pf_traces = particle_filter(100, heads, 100);

Gen.get_choices(pf_traces[1])[:prob]

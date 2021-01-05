function unfold_particle_filter(num_particles::Int, locations::Array{Coordinate,1}, num_samples::Int)
    init_obs = Gen.choicemap()
    state = Gen.initialize_particle_filter(unfold_model, (0,), init_obs, num_particles)

    for t=1:length(locations)
        maybe_resample!(state, ess_threshold=num_particles/2)
        obs = Gen.choicemap((:chain => t => :next_location, locations[t]))
        Gen.particle_filter_step!(state, (t,), (UnknownChange(),), obs)
        println(t)
        # for i = 1:num_particles
        #     println(state.log_weights[i])
        # end
    end

    # return a sample of traces from the weighted collection:
    return Gen.sample_unweighted_traces(state, num_samples)
end

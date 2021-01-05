function unfold_particle_filter(num_particles::Int, locations::Array{Coordinate,1}, computation_times::Array{Float64,1}, num_samples::Int)
    init_obs = Gen.choicemap((:chain => 1 => :next_location, locations[1]))
    state = Gen.initialize_particle_filter(unfold_model, (0,), init_obs, num_particles)

    for t=2:length(locations)
        println(t)
        maybe_resample!(state, ess_threshold=num_particles)#used to be /2. now always resampling becasue I want to get rid of -Inf before they become NANs
        obs = Gen.choicemap((:chain => t => :next_location, locations[t])) #put the location
        obs[:chain => t => :find_best => :computation_time] = computation_times[t] #and computation times
        Gen.particle_filter_step!(state, (t,), (UnknownChange(),), obs)
        for i = 1:num_particles
            println(state.log_weights[i])
        end
    end

    # return a sample of traces from the weighted collection:
    return Gen.sample_unweighted_traces(state, num_samples)
end

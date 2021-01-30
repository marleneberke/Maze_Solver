function unfold_particle_filter(num_particles::Int, locations::Array{Coordinate,1}, time_spent_here::Array{Float64,1}, num_samples::Int)
    #init_obs = Gen.choicemap((:chain => 1 => :next_location, locations[1]))
    #init_obs[:chain => 1 => :find_best => :movement_time] = movement_times[1] #and movement times
    #init_obs = Gen.choicemap((:chain => 1 => :next_location, locations[1])) #put the location
    #init_obs[:chain => 1 => :time_spent_here] = time_spent_here[1] #and movement times
    init_obs = Gen.choicemap()

    state = Gen.initialize_particle_filter(unfold_model, (0,), init_obs, num_particles)
    #for i = 1:num_particles
        #println("weights ", state.log_weights[i])
    #end

    for t=1:length(locations)
        println(t)

        maybe_resample!(state, ess_threshold=num_particles)#used to be /2. now always resampling becasue I want to get rid of -Inf before they become NANs
        ess = effective_sample_size(normalize_weights(state.log_weights)[2])
        println("ess after resample ", ess)

        if t==8
            hist = zeros(num_particles)
            for i = 1:num_particles
                hist[i] = state.traces[i][:chain => 7 => :how_long_distracted]
            end
            h = plt.hist(hist, 50)
        end



        #obs = Gen.choicemap((:chain => t => :next_location, Coordinate(1,2)))
        obs = Gen.choicemap((:chain => t => :next_location, locations[t])) #put the location
        obs[:chain => t => :time_spent_here] = time_spent_here[t] #and movement times
        #put times stuck
        println(locations[t])
        Gen.particle_filter_step!(state, (t,), (UnknownChange(),), obs)

        #rejuvination move




        #how_many_sampled_distracted = 0
        # for i = 1:num_particles
        #     if state.traces[i][:chain => t => :distracted]
        #         how_many_sampled_distracted = how_many_sampled_distracted + 1
        #         println("how_long_distracted ", state.traces[i][:chain => t => :how_long_distracted])
        #     else
        #         println("depth_limit ", state.traces[i][:chain => t => :depth_limit])
        #     end
        #     println("weight ", state.log_weights[i])
        # end
        # println("sampled_distracted ", how_many_sampled_distracted)

        ess = effective_sample_size(normalize_weights(state.log_weights)[2])
        println("ess after pf step ", ess)
        for i = 1:num_particles
            println("weight ", state.log_weights[i])
            # if (locations[t] == Coordinate(6, 6)) | (locations[t] == Coordinate(6, 7))
            #     println("depth ", state.traces[i][:chain => t => :depth_limit])
            #     println(state.traces[i][:chain => t => :distracted])
            #     println(state.traces[i][:chain => t => :how_long_distracted])
            #     println(state.traces[i][:chain => t => :time_spent_here])
            # end
            #println(state.traces[i][:chain => t => :distracted])
            #println(state.traces[i][:chain => t])
            #choices = get_choices(state.traces[i])
            #println(choices)
        end
    end

    # return a sample of traces from the weighted collection:
    return Gen.sample_unweighted_traces(state, num_samples)
end

@gen function perturbation_proposal(prev_trace)
    choices = get_choices(prev_trace)
    vy = @trace(normal(choices[(:vy, t)], 1e-3), (:vy, t))
end

function perturbation_move(trace)
    Gen.metropolis_hastings(trace, perturbation_proposal, ())
end



function effective_sample_size(log_normalized_weights::Vector{Float64})
    log_ess = -logsumexp(2. * log_normalized_weights)
    return exp(log_ess)
end

function normalize_weights(log_weights::Vector{Float64})
    log_total_weight = logsumexp(log_weights)
    log_normalized_weights = log_weights .- log_total_weight
    return (log_total_weight, log_normalized_weights)
end

include("mh.jl")

#t_pause is the time of the pause
function MCMC_inference(num_iter::Int, locations::Array{Coordinate,1}, time_spent_here::Array{Float64,1}, t_pause::Int64)
    #println("smaller constraints, wacky custom proposal")
    #println("smaller constraints, selection rather than proposal function")
    println("smaller constraints, selection rather than proposal function. increased sd in gm a lot.")
    #println("smaller constraints, selection rather than proposal function. increased sd in gm a lot. alternate mh steps on depth_limit and time_distracted")
    #println("smaller constraints, custom propose based on current values. kept increased sd in gm")
    #observations = make_constraints(locations, time_spent_here)
    observations = make_constraints(locations, time_spent_here, t_pause)
    (tr, _) = generate(unfold_model, (length(locations),), observations)

    ###MCMC on the other locations where there aren't pauses
    ts = collect(1:length(locations))
    #filter!(x->x!=t_pause, ts)
    #try mcmc on all the steps, not just non-pauses
    for iter_everyone = 1:100
        for t in ts
            tr, accepted = mh(tr, proposal_nonpauses, (t,))
            #println("accepted ", accepted)
        end
    end

    println("fun starts!")

    inferred_how_long_distracted = zeros(num_iter)
    for iter = 1:num_iter
        if iter % 10000 == 0
            println("iteration ", iter)
            for iter_everyone = 1:100
                for t in ts
                    tr, accepted = mh(tr, proposal_nonpauses, (t,))
                    #println("accepted ", accepted)
                end
            end
        end
        tr = block_resimulation_update(tr, t_pause, time_spent_here[t_pause])
        inferred_how_long_distracted[iter] = tr[:chain => t_pause => :how_long_distracted]
    end

    return inferred_how_long_distracted, tr
end

# Perform a single block resimulation update of a trace.
function block_resimulation_update(tr, t_pause::Int64, time_spent_at_pause::Float64)
    # All in one block
    params = select(:chain => t_pause => :depth_limit, :chain => t_pause => :how_long_distracted)
    (tr, accepted) = mh(tr, params)

    # #Alternate
    # params = select(:chain => t_pause => :depth_limit)
    # (tr, accepted) = mh(tr, params)
    #
    # println(accepted)
    # println("log prob current trace ", get_score(tr))
    #
    # params = select(:chain => t_pause => :how_long_distracted)
    # (tr, accepted) = mh(tr, params)

    #tr, accepted = mh(tr, proposal_pauses, (t_pause, time_spent_at_pause))
    #tr, accepted = mh(tr, proposal2, (t_pause,))

    println(accepted)
    println("log prob current trace ", get_score(tr))

    if accepted
        println("accepted ", accepted)
        println("depth_limit ", tr[:chain => t_pause => :depth_limit])
        println("how_long_distracted ", tr[:chain => t_pause => :how_long_distracted])
        println("log prob ", get_score(tr))
    end

    # Return the updated trace
    tr
end

#custom MH proposals for the pause
@gen function proposal_pauses(trace, t_pause::Int64, time_spent_at_pause::Float64)
    println("proposal")
    rand() < 0.5 ? depth_limit = @trace(trunc_poisson(15, 1, 30), :chain => t_pause => :depth_limit) : depth_limit = @trace(trunc_poisson(5, 1, 30), :chain => t_pause => :depth_limit)
    D = trunc_normal(1.5*depth_limit, 0.5*depth_limit, 0.0, 100.0) #crappy attempt to estimate what the counter would be for a search with this max_depth.
    estimate_of_distraction = maximum([0.0, (time_spent_at_pause - 10*D)/10]) #10 is from speed_of_thought_factor. should actually get that from the trace but hacking
    how_long_distracted_proposal = @trace(trunc_normal(estimate_of_distraction, 0.1, 0.0, 10000.0), :chain => t_pause => :how_long_distracted) #don't need to add noise to my estimate
    println("depth_limit ", depth_limit)
    println("guess at counter ", D)
    println("time_spent_at_pause ", time_spent_at_pause)
    println("estimate of distraction ", estimate_of_distraction)
    println("how_long_distracted_proposal ", how_long_distracted_proposal)
end

# #custom MH proposals for the pause
# @gen function proposal2(trace, t_pause::Int64)
#     println("proposal")
#     choices = get_choices(trace)
#     current_depth_limit = choices[:chain => t_pause => :depth_limit]
#     current_how_long_distracted = choices[:chain => t_pause => :how_long_distracted]
#     depth_limit_proposal = @trace(trunc_poisson(current_depth_limit, 1, 30), :chain => t_pause => :depth_limit) #don't need to add noise to my estimate
#     how_long_distracted_proposal = @trace(trunc_normal(current_how_long_distracted, 20.0, 0.0, 10000.0), :chain => t_pause => :how_long_distracted) #don't need to add noise to my estimate
#     println("depth_limit_proposal ", depth_limit_proposal)
#     println("time_spent_at_pause ", time_spent_at_pause)
#     println("how_long_distracted_proposal ", how_long_distracted_proposal)
# end

#custom MH proposals for the non-pauses. t is the locations of the non-pauses
@gen function proposal_nonpauses(trace, t::Int64)
    depth_limit = @trace(trunc_poisson(5, 1, 30), :chain => t => :depth_limit) #same as small search
    #println("depth_limit in proposal ", depth_limit)
    how_long_distracted = @trace(exponential(0.5), :chain => t => :how_long_distracted) #lots more 0s
end


function make_constraints(locations::Array{Coordinate,1}, time_spent_here::Array{Float64,1})
    constraints = Gen.choicemap()
    for t=1:length(locations)
        constraints[:chain => t => :next_location] = locations[t]
        constraints[:chain => t => :time_spent_here] = time_spent_here[t]
    end
    constraints
end

#just do constraints +-2 around t_pause
function make_constraints(locations::Array{Coordinate,1}, time_spent_here::Array{Float64,1}, t_pause::Int64)
    constraints = Gen.choicemap()
    ts = collect(t_pause-3:t_pause+3)
    for t in ts
        constraints[:chain => t => :next_location] = locations[t]
        constraints[:chain => t => :time_spent_here] = time_spent_here[t]
    end
    constraints
end

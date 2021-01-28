#t_pause is the time of the pause
function MCMC_inference(num_iter::Int, locations::Array{Coordinate,1}, time_spent_here::Array{Float64,1}, t_pause::Int64)

    observations = make_constraints(locations, time_spent_here)
    (tr, _) = generate(unfold_model, (length(locations),), observations)

    #MCMC on the other locations where there aren't pauses
    ts = collect(1:length(locations))
    filter!(x->x!=t_pause, ts)
    for iter = 1:100
        for t in ts
            tr, accepted = mh(tr, proposal, (t,))
            #println("accepted ", accepted)
        end
    end


    inferred_how_long_distracted = zeros(num_iter)
    for iter = 1:num_iter
        if iter % 10000 == 0
            println(iter)
        end
        tr = block_resimulation_update(tr, t_pause)
        inferred_how_long_distracted[iter] = tr[:chain => t_pause => :how_long_distracted]
    end

    return inferred_how_long_distracted, tr
end

# Perform a single block resimulation update of a trace.
function block_resimulation_update(tr, t_pause::Int64)
    # All in one block
    #params = select(:chain => t => :depth_limit, :chain => t => :distracted, :chain => t => :how_long_distracted)
    params = select(:chain => t_pause => :depth_limit, :chain => t_pause => :how_long_distracted)
    (tr, accepted) = mh(tr, params)

    #if accepted
        #println("depth_limit", tr[:chain => 7 => :depth_limit])
        #println("distracted", tr[:chain => 7 => :distracted])
        #println("how_long_distracted", tr[:chain => 7 => :how_long_distracted])
    #end

    # Return the updated trace
    tr
end

#custom MH proposals for the non-pauses. t is the locations of the non-pauses
@gen function proposal(trace, t::Int64)
    depth_limit = @trace(trunc_poisson(4, 1, 30), :chain => t => :depth_limit)
    #println("depth_limit in proposal ", depth_limit)
    how_long_distracted = @trace(geometric(0.5), :chain => t => :how_long_distracted) #lots more 0s
end


function make_constraints(locations::Array{Coordinate,1}, time_spent_here::Array{Float64,1})
    constraints = Gen.choicemap()
    for t=1:length(locations)
        constraints[:chain => t => :next_location] = locations[t]
        constraints[:chain => t => :time_spent_here] = time_spent_here[t]
    end
    constraints
end

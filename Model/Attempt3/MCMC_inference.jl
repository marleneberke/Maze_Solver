function MCMC_inference(num_iter::Int, locations::Array{Coordinate,1}, time_spent_here::Array{Float64,1})

    observations = make_constraints(locations, time_spent_here)
    (tr, _) = generate(unfold_model, (length(locations),), observations)

    #MCMC on the other locations where there aren't pauses
    ts = collect(1:length(locations))
    filter!(x->x!=7, ts)
    for iter = 1:100
        for t in ts
            tr, _ = mh(tr, proposal, (t,))
        end
    end


    inferred_how_long_distracted = zeros(num_iter)
    for iter = 1:num_iter
        tr = block_resimulation_update(tr)
        inferred_how_long_distracted[iter] = tr[:chain => 7 => :how_long_distracted]
    end

    return inferred_how_long_distracted, tr
end

# Perform a single block resimulation update of a trace.
function block_resimulation_update(tr)
    t = 7 #will have to improve this so it's the location of the pause

    # All in one block
    #params = select(:chain => t => :depth_limit, :chain => t => :distracted, :chain => t => :how_long_distracted)
    params = select(:chain => t => :depth_limit, :chain => t => :how_long_distracted)
    (tr, accepted) = mh(tr, params)

    if accepted
        println("depth_limit", tr[:chain => 7 => :depth_limit])
        #println("distracted", tr[:chain => 7 => :distracted])
        println("how_long_distracted", tr[:chain => 7 => :how_long_distracted])
    end

    # Return the updated trace
    tr
end

#custom MH proposals for the non-pauses. t is the locations of the non-pauses
@gen function proposal(trace, t::Int64)
    depth_limit = @trace(poisson(4), :chain => t => :depth_limit)
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

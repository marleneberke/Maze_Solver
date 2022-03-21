using PuzzleSolver
using Gen

include("mcmc.jl")

puzzle = ["S" 1 2 5; 1 0 0 1; 3 2 5 "F"]
correct_path = [CartesianIndex(1, 1), CartesianIndex(2, 1), CartesianIndex(3, 1), CartesianIndex(3, 2), CartesianIndex(3, 3)]
display(puzzle)
paths = PuzzleSolver.get_paths(puzzle) #not sure why I have to name the package. Seems I didn't have to do this with MetaGen
println(paths)
lengths = map(x -> length(x), paths)

puzzle_args = Puzzle_Args(paths, lengths, puzzle, correct_path)

#burn in and thin by thin factor
function thin(array::Array{Any,1}, burn_in::Int64, thin_factor::Int64)
    total = length(array)
    to = total/thin_factor
    from = (burn_in+thin_factor)/thin_factor
    index = convert(Vector{Int64}, collect(from:to)*thin_factor)
    return array[index]
end


function mh_inference(num_iters::Int64, params::Params, puzzle_args::Puzzle_Args, observation::DynamicChoiceMap, to_record::Symbol)
    max = 10

    (trace, _) = generate(gm, (max, params, puzzle_args), observation)
    display(get_choices(trace))

    values = Array{Any}(undef, num_iters)

    for iter = 1:num_iters
        #vanilla proposal for redoing the chain. from the prior.
        selection = select(:chain)
        trace, accepted = mh(trace, selection)
        println("path_to_check first ", trace[:chain => 1 => :path_to_check])
        # println("new chain accepted ", accepted)
        # display(get_choices(trace))

        # #propose better thinking times, given chain
        trace, accepted = mh(trace, proposal, (params,))
        #println("new times accepted ", accepted)
        #display(get_choices(trace))
        values[iter] = trace[to_record]
    end
    return values
end

# @gen function proposal(trace, params::Params)
#     #sample a new time per unit think
#     time_per_unit_think = @trace(normal(params.mu_time_per_unit_think, params.sd_time_per_unit_think), :time_per_unit_think)
#     println("time_per_unit_think ", time_per_unit_think)
# end


@gen function proposal(trace, params::Params)
    #sample a new time per unit think
    time_per_unit_think = @trace(normal(params.mu_time_per_unit_think, params.sd_time_per_unit_think), :time_per_unit_think)
    println("time_per_unit_think ", time_per_unit_think)

    #calculate time spent thinking
    total_thinking_time = time_per_unit_think * get_retval(trace)[end].thinking_units_used

    total_time = trace[:total_time] #should be the same as the observation

    println("total_time ", total_time)
    #truncate at 0, and would like upper bound to be total time, but that creates -Inf weights
    #would also like smaller sd, but that makes it too hard to accept proposals. seems very sensitive to the sd here
    time_distracted = @trace(trunc_normal(total_time - total_thinking_time, 10., 0., Inf), :time_distracted)
    println("time_distracted ", time_distracted)
end

#Thinking vs distracted

params = PuzzleSolver.Params(mu_time_per_unit_think = 100.,
sd_time_per_unit_think = 10.,
lambda_distracted = 0.001, #bigger means less often distracted
p_already_knew = 0.,
p_guessing = 0.,
p_mistake_action_level = 0.,
p_thinking_mistake = 0.)

pause_duration = 500.
observation = choicemap((:total_time, pause_duration))

num_iters = 1000
times_distracted = mh_inference(num_iters, params, puzzle_args, observation, :time_distracted)
times_distracted = thin(times_distracted, Int(length(times_distracted)/2), 20)

mean(times_distracted/pause_duration)

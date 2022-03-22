using PuzzleSolver
using Gen
using Statistics

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


function mh_inference(num_iters::Int64, params::Params, puzzle_args::Puzzle_Args, observation::DynamicChoiceMap)
    max = 10

    (trace, _) = generate(gm, (max, params, puzzle_args), observation)
    display(get_choices(trace))

    values = Array{Any}(undef, num_iters)

    i = 0
    for iter = 1:num_iters
        println("iter ", iter)
        #vanilla proposal for redoing the chain. from the prior.
        #selection = select(:chain)
        selection = select(:chain, :distracted, :time_per_unit_think)
        #selection = select(:chain, :distracted)
        trace, accepted = mh(trace, selection)
        #println("path_to_check first ", trace[:chain => 1 => :path_to_check])
        #println("path_to_check first ", trace[:distracted])
        # println("new chain accepted ", accepted)
        # display(get_choices(trace))

        # #propose better thinking times, given chain
        #trace, accepted = metropolis_hastings_homemade(trace, proposal_distraction_time, ())
        i = i + accepted
        #println("new times accepted ", accepted)
        #display(get_choices(trace))
        values[iter] = trace[:distracted]
    end
    println("i ", i)
    return values
end

#Thinking vs distracted

params = PuzzleSolver.Params(mu_time_per_unit_think = 100.,
sd_time_per_unit_think = 10.,
p_distracted = 0.5,
lambda_distracted = 0.001, #bigger means less often distracted
p_already_knew = 0.,
p_guessing = 0.,
p_mistake_action_level = 0.,
p_thinking_mistake = 0.)

pause_duration = 100.
observation = choicemap((:total_time, pause_duration))

num_iters = 10000
distracted = mh_inference(num_iters, params, puzzle_args, observation, :distracted)
println("before thinning ", mean(distracted))
distracted = thin(distracted, Int(length(distracted)/2), 20)
println("after thinning ", mean(distracted))

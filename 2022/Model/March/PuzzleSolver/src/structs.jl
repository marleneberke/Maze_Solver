Base.@kwdef struct Puzzle_Args
    paths::Vector{Any}
    puzzle::Matrix{Any}
    correct_path::Vector{CartesianIndex{2}}
end

Base.@kwdef struct State
    possible_paths::Vector{Any}
    segments_of_path_to_be_checked::Vector{Vector{Any}} #can have multiple pieces of a path that need to be checked
    thinking_units_used::Int64
    goal_found::Bool
end

Base.@kwdef struct Params #assuming p_guessing and p_already knew can't both the the case
    tau_softmax::Float64 = 0.5 #tau = 0 means perfectly rational
    mu_time_per_unit_think::Float64 = 100.
    sd_time_per_unit_think::Float64 = 1.
    p_distracted::Float64 = 0.00001
    lambda_distracted::Float64 = 10000. #bigger means less often distracted
    p_already_knew::Float64 = 0.00001
    p_guessing::Float64 = 0.00001
    p_mistake_action_level::Float64 = 0.00001
    p_thinking_mistake = 0.05
end

export Puzzle_Args
export Params

export choose_path_distribution

struct Choose_Path_Distribution <: Gen.Distribution{Vector{Any}} end

const choose_path_distribution = Choose_Path_Distribution()

function Gen.random(::Choose_Path_Distribution, paths::Vector{Vector{Any}},
                desired_path::Vector{Any}, p_mistake::Float64)

    desired_index = findall(x -> x==desired_path, paths)[1]

    n = length(paths)
    ps = fill(p_mistake/(n-1), n)
    ps[desired_index] = 1-p_mistake
    return paths[categorical(ps)]
end

function Gen.logpdf(::Choose_Path_Distribution, chosen_path::Vector{Any}, paths::Vector{Vector{Any}},
                desired_path::Vector{Any}, p_mistake::Float64)

    chosen_index = findall(x -> x==chosen_path, paths)[1]
    n = length(paths)
    ps = fill(p_mistake/(n-1), n)
    ps[desired_index] = 1-p_mistake
    Gen.logpdf(categorical, chosen_index, ps)
end

function Gen.logpdf_grad(::Choose_Path_Distribution, chosen_path::Vector{Any}, paths::Vector{Vector{Any}},
                desired_path::Vector{Any}, p_mistake::Float64)
    gerror("Not implemented")
    (nothing, nothing)
end

(::Choose_Path_Distribution)(paths, desired_path, p_mistake) = Gen.random(Choose_Path_Distribution(), paths, desired_path, p_mistake)

has_output_grad(::Choose_Path_Distribution) = false
has_argument_grads(::Choose_Path_Distribution) = (false,)

export choose_path_distribution

export choose_path_distribution

struct Choose_Path_Distribution <: Gen.Distribution{Vector{Any}} end

const choose_path_distribution = Choose_Path_Distribution()

function Gen.random(::Choose_Path_Distribution, paths::Vector{Vector{Any}},
                desired_path::Vector{Any}, p_mistake::Float64)

    desired_index = findall(x -> x==desired_path, paths)[1]

    n_options = length(paths)
    if n_options==1
        ps = fill(1., 1)
    else
        ps = fill(params.p_mistake_action_level/(n_options-1), n_options)
        ps[desired_index] = 1-params.p_mistake_action_level
    end
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

##############################################################################################
using Distributions

#TruncatedNormal
export trunc_normal

#small issue where all of the inputs need to by Float64. Doesn't accept Int64s
struct TruncatedNormal <: Gen.Distribution{Float64} end

const trunc_normal = TruncatedNormal()

function Gen.random(::TruncatedNormal, mu::U, std::U, low::U, high::U)  where {U <: Real}
	n = Distributions.Normal(mu, std)
	rand(Distributions.Truncated(n, low, high))
end

function Gen.logpdf(::TruncatedNormal, x::U, mu::U, std::U, low::U, high::U) where {U <: Real}
	n = Distributions.Normal(mu, std)
	tn = Distributions.Truncated(n, low, high)
	Distributions.logpdf(tn, x)
end

function Gen.logpdf_grad(::TruncatedNormal, x::U, mu::U, std::U, low::U, high::U)  where {U <: Real}
    precision = 1. / (std * std)
    diff = mu - x
    deriv_x = diff * precision
    deriv_mu = -deriv_x
    deriv_std = -1. / std + (diff * diff) / (std * std * std)

    if x<=low
        deriv_x = log(0.001) #trying to have a very small positive gradient
    elseif x>=high
        deriv_x = log(-0.001) #trying to have a very small negative gradient
    end

    (deriv_x, deriv_mu, deriv_std)
end

(::TruncatedNormal)(mu, std, low, high) = random(TruncatedNormal(), mu, std, low, high)
is_discrete(::TruncatedNormal) = false
has_output_grad(::TruncatedNormal) = true
has_argument_grads(::TruncatedNormal) = (true, true, false, false) #just has output gradients for mu and std

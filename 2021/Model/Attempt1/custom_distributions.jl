struct Coordinate
    x::Int64
    y::Int64
end

export location_distribution

struct LocationDistribution <: Gen.Distribution{Coordinate} end

const location_distribution = LocationDistribution()

function Gen.random(::LocationDistribution, x::Int64, y::Int64)
	Coordinate(x, y)
end

function Gen.logpdf(::LocationDistribution, location::Coordinate, x::Int64, y::Int64)
    (location.x==x && location.y==y) ? 0.0 : -Inf
end

function Gen.logpdf_grad(::LocationDistribution, location::Coordinate, x::Int64, y::Int64)
	gerror("Not implemented")
	(nothing, nothing)
end

(::LocationDistribution)(x, y) = random(LocationDistribution(), x, y)
is_discrete(::LocationDistribution) = true

has_output_grad(::LocationDistribution) = false
has_argument_grads(::LocationDistribution) = (false,)

##############################################################################################
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
	gerror("Not implemented")
	(nothing, nothing)
end

(::TruncatedNormal)(mu, std, low, high) = random(TruncatedNormal(), mu, std, low, high)
is_discrete(::TruncatedNormal) = false
has_output_grad(::TruncatedNormal) = false
has_argument_grads(::TruncatedNormal) = (false,)

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

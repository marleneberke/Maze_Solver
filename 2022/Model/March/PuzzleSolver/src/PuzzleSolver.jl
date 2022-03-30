module PuzzleSolver

using Gen
#using Plots
# using PyPlot
# const plt = PyPlot
#import PyPlot; const plt = PyPlot

include("custom_distributions.jl")
include("structs.jl")
include("parse_puzzle_and_helpers.jl")
include("gm.jl")

function __init__()
    @load_generated_functions
end

end # module

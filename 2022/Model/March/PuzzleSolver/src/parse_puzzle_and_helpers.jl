#Contains non-Gen functions

#Get all possible paths from start to finish
function get_paths(puzzle::Matrix{Any})
    start = findall(x -> x=="S", puzzle)[1]
    visited = []
    paths = []
    DFS(puzzle, visited, paths, start)
    return paths
end
export get_paths

function DFS(puzzle::Matrix{Any}, visited::Vector{Any}, paths::Vector{Any}, current_place::CartesianIndex{2})
    visited = deepcopy(visited)
    if puzzle[current_place]=="F" #if goal found
        #println("visited ", visited)
        push!(paths, visited)
        return paths
    end

    push!(visited, current_place)
    neighbors = get_neighbors(puzzle, visited, current_place)

    for neighbor in neighbors
        DFS(puzzle, visited, paths, neighbor)
    end
end


function get_neighbors(puzzle::Matrix{Any}, visited::Vector{Any}, current_place::CartesianIndex{2})
    dims = size(puzzle)
    neighbors = []
    if current_place[1]+1 <= dims[1] && puzzle[current_place + CartesianIndex(1, 0)]!=0 &&
        !(current_place + CartesianIndex(1, 0) in visited) #check to the right
        push!(neighbors, current_place + CartesianIndex(1, 0))
    end
    if current_place[2]+1 <= dims[2] && puzzle[current_place + CartesianIndex(0, 1)]!=0 &&
        !(current_place + CartesianIndex(0, 1) in visited) #check downward
        push!(neighbors, current_place + CartesianIndex(0, 1))
    end
    if current_place[1]-1 >= 1 && puzzle[current_place + CartesianIndex(-1, 0)]!=0 &&
        !(current_place + CartesianIndex(-1, 0) in visited) #check downward#check leftwards
        push!(neighbors, current_place + CartesianIndex(-1, 0))
    end
    if current_place[2]-1 >= 1 && puzzle[current_place + CartesianIndex(0, -1)]!=0 &&
        !(current_place + CartesianIndex(0, -1) in visited) #check downward#check leftwards#check leftwards
        push!(neighbors, current_place + CartesianIndex(0, -1))
    end
    return neighbors
end

################################################################################


function softmax(costs, tau)
    return exp.(-1/tau.*costs) ./ (sum(exp.(-1/tau.*costs)))
end

#vision gives you the possible paths and their lengths
puzzle = ["S" 1 2 5; 1 0 0 1; 3 2 5 "F"]
display(puzzle)

dims = size(puzzle)
start = findall(x -> x=="S", puzzle)[1]

paths = []
get_paths(puzzle)

#println("paths ", paths)
lengths = map(x -> length(x), paths)


#Get all possible paths from start to finish
function get_paths(puzzle::Matrix{Any})
    visited = []
    DFS(puzzle, visited, start)
end


function DFS(puzzle::Matrix{Any}, visited::Vector{Any}, current_place::CartesianIndex{2})
    visited = deepcopy(visited)
    if puzzle[current_place]=="F" #if goal found
        #println("visited ", visited)
        push!(paths, visited)
        return paths
    end

    push!(visited, current_place)
    neighbors = get_neighbors(puzzle, visited, current_place)

    for neighbor in neighbors
        DFS(puzzle, visited, neighbor)
    end
end


function get_neighbors(puzzle::Matrix{Any}, visited::Vector{Any}, current_place::CartesianIndex{2})
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
#Evaluate if a possible path follows the up-down rule.
#Return how many comparisons were needed to assess if it follows the rule.
function evaluate_rule(possible_path)
    if puzzle[possible_path[1]] == "S"
        possible_path = possible_path[2:end]
    end

    if length(possible_path) == 1
        return true, 0 #no eval needed
    end

    i = 1
    rule_not_broken = true
    previous_up = true
    previous_down = true
    while i < length(possible_path) && rule_not_broken
        up = puzzle[possible_path[i]] < puzzle[possible_path[i+1]]
        down = puzzle[possible_path[i]] > puzzle[possible_path[i+1]]
        rule_not_broken = (previous_down && up) || (previous_up && down)
        i = i + 1
        previous_up = up
        previous_down = down
    end

    # if length(possible_path) < 3
    #     return true, ?? #or 0 because no evaluation was needed???
    # end
    #
    # #println("possible_path ", possible_path)
    #
    # i = 2 #start by evaluating relationship between two
    # rule_not_broken = true
    # while i < length(possible_path) && rule_not_broken
    #     up_down = puzzle[possible_path[i-1]] < puzzle[possible_path[i]] && puzzle[possible_path[i]] > puzzle[possible_path[i+1]]
    #     down_up = puzzle[possible_path[i-1]] > puzzle[possible_path[i]] && puzzle[possible_path[i]] < puzzle[possible_path[i+1]]
    #     rule_not_broken = up_down || down_up
    #     i = i + 1
    # end

    return rule_not_broken, i-1
end


function softmax(costs, tau)
    return exp.(-1/tau.*costs) ./ (sum(exp.(-1/tau.*costs)))
end

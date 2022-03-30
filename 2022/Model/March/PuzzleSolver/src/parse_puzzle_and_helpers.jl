#Contains non-Gen functions

#Get all possible paths from start to finish
function get_paths(puzzle::Matrix{Any})
    start = findall(x -> x=="S", puzzle)[1]
    visited = []
    paths = []
    DFS(puzzle, visited, paths, start)
    #pop start off
    for path in paths
        path = popfirst!(path)
    end
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

################################################################################
#check if a path contains some segment
function is_in(segment, path)
    if (segment[1] in path)
        j = findall(x -> x==segment[1], path)[1] #only works since no cycles in path
        for i = 2:length(segment)
            if path[j+i-1] != segment[i]
                return false
            end
        end
    else
        return false
    end
    return true
end

#returns the first overlap and the indexes of it from segmentA's perspective
function first_overlap(segmentA, segmentB)
    for i = 1:length(segmentA)
        if (segmentA[i] in segmentB)
            index_start = i
            j = findall(x -> x==segmentA[i], segmentB)[1]
            match = true
            while match && i < length(segmentA) && j < length(segmentB)
                i = i + 1
                j = j + 1
                match = segmentA[i] == segmentB[j]
            end
            index_end = match ? i : i - 1
            return segmentA[index_start:index_end], index_start, index_end
        end
    end
    return [], 0, 0
end

#return how the segment of the path gets changed by checking against segment checked.
#this function is recursive
function fun_outer(segment_of_path, segment_checked)
    segments = []
    fun(segment_of_path, segment_checked, segments)
end

function fun(segment_of_path, segment_checked, segments)
    overlapping_section, index_of_start, index_of_end = first_overlap(segment_of_path, segment_checked) #returns first overlap
    #println("overlapping_section ", overlapping_section)
    if length(overlapping_section) >= 3
        if index_of_start == 1 && index_of_end == length(segment_of_path) #the overlap stretches over the whole segment
            #do not push anything to segments
            println("total overlap")
        elseif index_of_start == 1 #overlap starts at the beginning
            temp2 = segment_of_path[index_of_end - 1 : end]
            fun(temp2, segment_checked, segments) #still need to check for if there's a second overlap later
        elseif index_of_end == length(segment_of_path) #the overlap goes to the end
            temp1 = segment_of_path[1 : index_of_start + 1] #keep the part before the overlap
            push!(segments, temp1)
        else
            #split into two new segments, cutting out the middle
            temp1 = segment_of_path[1 : index_of_start + 1]
            temp2 = segment_of_path[index_of_end - 1 : end]
            #println("temp1 ", temp1)
            #println("temp2 ", temp2)
            push!(segments, temp1)
            fun(temp2, segment_checked, segments) #since only got the first overlap, might be another overlap later on
        end
    else
        push!(segments, segment_of_path)
    end
    return segments
end

function update_state(state::State, path_to_check::Int64, works::Bool, evals_until_end::Int64, n_segments_evaluated::Int64, section_last_evaluated::Array{Any}, where_left_off::Int64)
    thinking_units_used = state.thinking_units_used + evals_until_end
    segments_checked = state.segments_of_path_to_be_checked[path_to_check]
    segments_checked[n_segments_evaluated] = segments_checked[n_segments_evaluated][1:where_left_off] #shorten it to what was actually searched
    possible_paths = state.possible_paths
    segments_of_path_to_be_checked = state.segments_of_path_to_be_checked
    #update state
    if works #found path to end
        #println("works")
        possible_paths = [possible_paths[path_to_check]]
        segments_of_path_to_be_checked = []
        goal_found = true
    else
        #delete paths containing the area that broke the rule
        println("section_last_evaluated ", section_last_evaluated)
        println("possible_paths ", possible_paths)
        indices_to_delete = []
        for i = 1:length(possible_paths)
            if is_in(section_last_evaluated, possible_paths[i])
                push!(indices_to_delete, i)
            end
        end
        possible_paths = deleteat!(possible_paths, indices_to_delete)
        segments_of_path_to_be_checked = deleteat!(segments_of_path_to_be_checked, indices_to_delete)
        #println("possible_paths ", possible_paths)

        for i = 1:length(possible_paths)
            new_segments_of_paths_to_be_checked = []
            for j = 1:n_segments_evaluated
                for s = 1:length(segments_of_path_to_be_checked[i])
                    #println("before segments_of_path_to_be_checked[i][s] ", segments_of_path_to_be_checked[i][s])
                    #println("segments_checked[j] ", segments_checked[j])
                    to_add = fun_outer(segments_of_path_to_be_checked[i][s], segments_checked[j])
                    for a = 1:length(to_add)
                        push!(new_segments_of_paths_to_be_checked, to_add[a]) #want each element
                    end
                end
                segments_of_path_to_be_checked[i] = new_segments_of_paths_to_be_checked #update segments for this path
            end
        end

        goal_found = false
    end

    next_state = State(possible_paths, segments_of_path_to_be_checked, thinking_units_used, goal_found)
    println("next_state: ", next_state)
    return next_state
end

function estimate_costs(state::State)

end

#takes an array, and makes each element an array containing one thing
function make_double_array(array::Vector{Any})
    new_array = Vector{Any}(undef, length(array))
    for i = 1:length(array)
        new_array[i] = [array[i]]
    end
    return new_array
end

# #takes an array that might have multiple arrays embedded, and unrolls them into
# #one array where each entry is an array of length 1
# #not done yet
# function straighten_out(array::Vector{Any})
#     new_array = []
#     for i = 1:length(array)
#         if typeof(array[i]) == CartesianIndex{2} #if we're down to an element
#             push!(new_array, array[i])
#         else
#             temp = straighten_out(array[i])
#             push!(new_array, temp)
#         end
#     end
#     return new_array
# end

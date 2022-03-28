#functions for generating a puzzle
function generate_puzzle(dim::Int64)
    puzzle = Matrix{Any}(undef, dim, dim)
    fill!(puzzle, 0)

    #start and finish could be in random location
    start_x = 2
    start_y = 2
    puzzle[start_x, start_y] = "S"
    finish_x = dim-1
    finish_y = dim-1
    puzzle[finish_x, finish_y] = "F"

    n_path_to_generate = rand(1:3)

    for i in 1:n_path_to_generate
        path = random_walk(puzzle)
        puzzle = fill_in_numbers(puzzle, path, 0.8)
    end

    return puzzle
end

export generate_puzzle

#do a random walk to make a path. no backtracking
function random_walk(puzzle::Matrix{Any})
    start = findall(x -> x=="S", puzzle)[1]
    finish = findall(x -> x=="F", puzzle)[1]

    dims = size(puzzle)

    current_location = start
    path = []
    push!(path, start)

    still_good = true
    while puzzle[current_location] != "F" && still_good
        current_location, still_good = take_step(current_location, finish, dims, path)
        push!(path, current_location)
        println("still_good ", still_good)
    end

    if !still_good #if random walk got stuck, try again
        println("here")
        path = random_walk(puzzle)
    end

    return path
end

#take a random step biased in the direction of finish
function take_step(current_location::CartesianIndex, finish::CartesianIndex, dims::Tuple{Int64, Int64}, path::Array{Any})
    diff_x = finish[1] - current_location[1]
    diff_y = finish[2] - current_location[2]

    i = 0
    limit = 20

    new_location = CartesianIndex(0, 0) #initialize so as to enter while loop
    #while loop takes care of edges in puzzle by just resampling
    while (new_location[1] <= 0 || new_location[2] <= 0 || new_location[1] > dims[1] || new_location[2] > dims[2] ||
        (new_location in path)) && #avoid backtracking
        i <= limit #unreasonable long time in this while loop, indicative of getting stuck

        #20% chance go in wrong direction.
        #80% chance go in correct direction.
        to_go = rand(Categorical([0.1, 0.1, 0.4, 0.4]))
        if diff_x == 0
            to_go = rand(Categorical([0.1, 0.1, 0., 0.8]))
        elseif diff_y == 0
            to_go = rand(Categorical([0.1, 0.1, 0.8, 0.]))
        end

        if to_go == 1 #go in wrong direction in x
            new_location = CartesianIndex(current_location[1] + (-1 * sign(diff_x)), current_location[2])
        elseif to_go == 2 #go in wrong direction in y
            new_location = CartesianIndex(current_location[1], current_location[2] + (-1 * sign(diff_y)))
        elseif to_go == 3 #go in correct direction in x
            new_location = CartesianIndex(current_location[1] + sign(diff_x), current_location[2])
        elseif to_go == 4 #go in correct direction in y
            new_location = CartesianIndex(current_location[1], current_location[2] + sign(diff_y))
        end

        println("to_go ", to_go)

        println("current_location ", current_location)
        println("new_location ", new_location)

        println("i ", i)
        i = i + 1
    end

    still_good = i <= limit #if did too many iterations, returnt false

    return new_location, still_good
end

#given a path, fills in numbers in the puzzle along that path.
function fill_in_numbers(puzzle::Matrix{Any}, path::Array{Any,1}, prob_break_rule::Float64)
    #don't want to overwrite start and finish
    if puzzle[path[end]] == "F"
        deleteat!(path, length(path))
    end
    if puzzle[path[1]] == "S"
        deleteat!(path, 1)
    end

    first_number = rand(1:9)
    puzzle[path[1]] = first_number

    if length(path) == 1
        return puzzle
    end

    temp = deleteat!(collect(1:9), first_number)
    previous_number = rand(temp)
    puzzle[path[2]] = previous_number

    if length(path) == 2
        return puzzle
    end

    previous_up = puzzle[path[2]] > puzzle[path[1]]
    previous_down = puzzle[path[2]] < puzzle[path[1]]
    for i in 3:length(path)
        if rand(1)[1] < prob_break_rule #break the rule
            if previous_up
                range = (previous_number+1):9
                if length(range) > 0
                    puzzle[path[i]] = rand((previous_number+1):9)
                else #if you can't break the rule without repeating
                    puzzle[path[i]] = rand(1:previous_number-1)
                end
            else #previous_down
                range = 1:(previous_number-1)
                if length(range) > 0
                    puzzle[path[i]] = rand(1:(previous_number-1))
                else #if you can't break the rule without repeating
                    puzzle[path[i]] = rand((previous_number+1):9)
                end
            end
        else
            if previous_up
                puzzle[path[i]] = rand(1:(previous_number-1))
            else #previous_down
                puzzle[path[i]] = rand((previous_number+1):9)
            end
        end
        previous_up = puzzle[path[i]] > puzzle[path[i-1]]
        previous_down = puzzle[path[i]] < puzzle[path[i-1]]
        previous_number = puzzle[path[i]]
    end
    return puzzle
end

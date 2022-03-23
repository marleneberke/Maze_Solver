#Script for generating a puzzle

dim = 10

puzzle = Matrix{Any}(undef, dim, dim)
fill!(puzzle, 0)

#start and finish could be in random location
start_x = 2
start_y = 2
puzzle[start_x, start_y] = "S"
finish_x = dim-1
finish_y = dim-1
puzzle[finish_x, finish_y] = "F"

n_path_to_generate = rand(1:4)

#do a random walk to make a path
function random_walk(puzzle::Matrix{Any})
    start = findall(x -> x=="S", puzzle)[1]
    finish = findall(x -> x=="F", puzzle)[1]

    dims = size(puzzle)

    current_location = start
    path = []

    while puzzle[current_location] != "F"
        current_location = take_step(current_location, finish, dims)
        push!(path, current_location)
    end

    return path
end

#take a random step biased in the direction of finish
function take_step(current_location::CartesianIndex, finish::CartesianIndex, dims::Tuple{Int64, Int64})
    diff_x = finish[1] - current_location[1]
    diff_y = finish[2] - current_location[2]

    new_location = CartesianIndex(0, 0) #initialize so as to enter while loop
    #while loop takes care of edges in puzzle by just resampling
    while new_location[1] <= 0 && new_location[2] <= 0 && new_location[1] <= dims[1] && new_location[2] <= dims[2]
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
    end

    return new_location
end

path = random_walk(puzzle)

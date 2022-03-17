include("maze_generator.jl")
include("helpers.jl")

################################################################################
#Setting up environment

Random.seed!(1);

function generate_maze(h::Int64, w::Int64)
    m = maze(h,w);
    printmaze(m);

    maze_matrix = Matrix{TreeNode}(undef, h, w)
    for x = 1:h
        for y = 1:w
            neigh = find_children(x, y, m)
            maze_matrix[x,y] = TreeNode(Coordinate(x,y), deepcopy(neigh)) #location, neighbors, children
        end
    end

    goal_location = Coordinate(h, w)

    return(maze_matrix, goal_location)
end

#n_action_space = 800

################################################################################
function to_abstract_tree(belief_matrix, current_pos::Coordinate)
    tree = AbstractNode[]
    belief_matrix = deepcopy(belief_matrix)
    return to_abstract_tree(belief_matrix, current_pos::Coordinate, tree::Vector{AbstractNode})
end

function to_abstract_tree(belief_matrix, current_pos::Coordinate, tree::Vector{AbstractNode})
    #root node is the current position and goes at the beginning of the array
    children = belief_matrix[current_pos.x, current_pos.y].children
    root_node = AbstractNode(length(children), Int64[])
    push!(tree, root_node)

    for child in children
        #println("child ", child)
        if isassigned(belief_matrix, child.x, child.y)
            #println("tree 1", tree)
            push!(root_node.children_indices, length(tree)+1)
            #println("tree 2", tree)

            #to avoid infinite loops, have to adjust child.
            filter!(x -> x !== current_pos, belief_matrix[child.x, child.y].children)
            #deleteat!(belief_matrix[child.x, child.y].children, belief_matrix[child.x, child.y].children .== current_pos)
            tree = to_abstract_tree(belief_matrix, child, tree)
            #println("tree 3", tree)
        end
    end
    return tree
end
################################################################################
#check if two trees have the same structure
function same_tree(treeA::Vector{AbstractNode}, treeB::Vector{AbstractNode})
    if length(treeA) != length(treeB)
        return false
    end

    return same_tree(treeA, treeB, 1, 1)
end

function same_tree(treeA::Vector{AbstractNode}, treeB::Vector{AbstractNode}, A_root_index::Int64, B_root_index::Int64)
    rootA = treeA[A_root_index]
    rootB = treeB[B_root_index]

    if length(rootA.children_indices) != length(rootB.children_indices)
        return false
    end

    n_children = length(rootA.children_indices)

    rootB = deepcopy(rootB)
    for indexA = 1:n_children
        child_match = 0 #each child in treeA has to match with a child in treeB
        #if it's the last child, go to end
        #last_index = indexA == n_children ? length(treeA) : rootA.children_indices[indexA+1]
        #subtreeA_root_index = treeA[rootA.children_indices[indexA] : last_index]
        println("rootA.children_indices ", rootA.children_indices)
        subtreeA_root_index = rootA.children_indices[indexA]

        to_delete = 0
        for indexB = 1:length(rootB.children_indices)
            #last_index = indexB == n_children ? length(treeB) : rootB.children_indices[indexB+1]
            #subtreeB = treeB[rootB.children_indices[indexB] : last_index]
            subtreeB_root_index = rootB.children_indices[indexB]
            if same_tree(treeA, treeB, subtreeA_root_index, subtreeB_root_index)
                child_match = 1 #mark that A's child has a match
                #remove subtreeB so it can't get matched again
                #treeB = deleteat!(treeB, rootB.children_indices[indexB] : last_index)
                #deleteat!(rootB.children_indices, indexB)
                to_delete = indexB
            end
        end
        if to_delete != 0
            deleteat!(rootB.children_indices, to_delete)
        end

        if child_match == 0 #if didn't find a match for indexA
            return false
        end
    end

    return true
end
################################################################################
#Q_table = zeros(n_action_space)


################################################################################
action_time = 5
think_time = 1
goal_reward = 1000000

#just for now, only actions are moving.
function take_action(maze_matrix::Matrix{TreeNode}, move::Bool, search_budget::Int64, belief_matrix, current_location::Coordinate, goal_location::Coordinate)

    children = belief_matrix[current_location.x, current_location.y].children

    reward = 0

    #move
    if move
        selected = rand(children)
        if !isassigned(belief_matrix, selected.x, selected.y)
            belief_matrix[selected.x, selected.y] = deepcopy(maze_matrix[selected.x, selected.y])
        end
        if length(children) == 1 #this is where pruning happens. If you are going to an only child, cut the parent out.
            filter!(x->x!=current_location, belief_matrix[selected.x, selected.y].children)
        end
        current_location = selected
        reward = reward - action_time
    end

    if current_location == goal_location
        reward = reward + goal_reward
    end

    return (belief_matrix, current_location, reward)
end

################################################################################
#Try counting how many unique belief trees there are
unique_trees = []


################################################################################
#Setting up agent

#initializing
function run()
    h = 3
    w = 3
    maze_matrix, goal_location = generate_maze(h, w)

    current_location = Coordinate(1, 1)
    belief_matrix = Matrix{TreeNode}(undef, h, w)
    belief_matrix[1, 1] = deepcopy(maze_matrix[1, 1])

    # println(current_location)
    # println(belief_matrix)

    tree = to_abstract_tree(belief_matrix, current_location)
    # println(tree)
    already_seen = 0
    j = 1
    while already_seen == 0 & j < length(unique_trees)
        already_seen = same_tree(tree, unique_trees[j])
        j = j + 1
    end
    if already_seen == 0
        # print("added ", tree)
        push!(unique_trees, tree)
    end

    n_steps = 100
    i = 1
    done = false
    while i < n_steps && !done
        #do something random
        move = true#rand([true, false])
        search_budget = rand([0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
        #leaf_to_search = rand() #something to do with the belief tree's leaves

        #leaf to search
        belief_matrix, current_location, reward = take_action(maze_matrix, move, search_budget, belief_matrix, current_location, goal_location)

        # println(current_location)
        # println(belief_matrix)

        tree = to_abstract_tree(belief_matrix, current_location)

        # println(tree)

        already_seen = 0
        j = 1

        while already_seen == 0 && j <= length(unique_trees)
            #println(tree)
            #println(unique_trees[j])
            already_seen = same_tree(tree, unique_trees[j])
            j = j + 1
        end
        if already_seen == 0
            # print("added ", tree)
            push!(unique_trees, tree)
        end

        done = current_location == goal_location
        i = i + 1

        println("i ", i)

        #println(reward)

        #println(belief_matrix)
    end
end

n_runs = 20000
for i = 1:n_runs
    run()

    println(length(unique_trees))
    for i = 1:length(unique_trees)
        println(unique_trees[i])
    end
end

#

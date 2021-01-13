include("custom_distributions.jl")

struct State
    current_location::Coordinate
    search_tree::Matrix{Union{TreeNode, Missing}}
    distracted::Bool
    time_since_last_move::Int64
    time_since_last_thought::Int64
    path_to_goal::Array{Any,1}
end

@gen function kernel(t::Int64, state::State, time_per_thought::Int64, time_per_move::Int64, max_tree_size::Int64, goal_location)
    current_location = state.current_location
    search_tree = state.search_tree
    distracted = state.distracted
    time_since_last_move = state.time_since_last_move
    time_since_last_thought = state.time_since_last_thought
    path_to_goal = state.path_to_goal

    @trace(location_distribution(current_location.x, current_location.y), :location)

    if current_location==Coordinate(5,2)
        #println("time_since_last_move ", time_since_last_move)
        #println("children of (5,2) ", search_tree[current_location.x, current_location.y].children)
        #println("t ", t)
    end

    #1% chance of becoming newly distracted, 95% remaining distracted if already so
    distracted = @trace(bernoulli(0.01+distracted*0.94), :distracted)
    if distracted #don't do anything
        ##println("distracted")
        return State(current_location, search_tree, distracted, time_since_last_move, time_since_last_thought, path_to_goal)
        #should time since last thought/move actually increase while distracted??? maybe not? what about movement time?
    end

    #if at the goal location, just return the goal location
    if current_location==goal_location
        return State(current_location, search_tree, distracted, time_since_last_move, time_since_last_thought, path_to_goal)
    end

    #this is all an else

    #if enough time has passed since last thought and tree is small enough and goal has not previously been found, expand search tree
    if (time_since_last_thought >= time_per_thought) && (size_of_downstream_tree(current_location, search_tree) < max_tree_size) && isempty(path_to_goal)
        #if frontier is empty and there's no path to a goal, means this is a dead end. in that case, keeping starting search from parent node until you find new frontier
        current_location_to_search_from = current_location
        frontier = get_downstream_frontier(current_location_to_search_from, search_tree[current_location_to_search_from.x, current_location_to_search_from.y].parent, search_tree)
        while isempty(frontier)
            current_location_to_search_from = search_tree[current_location_to_search_from.x,current_location_to_search_from.y].parent
            frontier = get_downstream_frontier(current_location_to_search_from, search_tree[current_location_to_search_from.x, current_location_to_search_from.y].parent, search_tree)
        end

        #pick the next node to add randomly
        #to_add = sample(frontier) #may want to trace this later. to_add should be a tree node
        #to_add = frontier[1] #temporarily make everything deterministic

        frontier_index = @trace(uniform_discrete(1, length(frontier)), :frontier_index)
        to_add = frontier[frontier_index]

        search_tree = add_to_search_tree(to_add, search_tree)
        #should add something for checking if it's the goal
        if to_add.location == goal_location
            path_to_goal = find_path(current_location, goal_location, search_tree)
        elseif length(to_add.children) < 1 #if it doesn't have children, prune the search tree
            search_tree = prune(to_add, search_tree)
        end
        time_since_last_thought = 1
    else
        time_since_last_thought = time_since_last_thought  +  1
    end

    moved = false
    #if movement is an option
    if time_since_last_move >= time_per_move
        if !isempty(path_to_goal) #if goal found, move toward it
            if current_location==Coordinate(5,2)
                ##println("goal found")
            end
            current_location = pop!(path_to_goal)
            moved = true
        #if just one possible move, take it
        elseif length(search_tree[current_location.x, current_location.y].children) == 1
            if current_location==Coordinate(5,2)
                #println("only one option")
            end
            next_location = search_tree[current_location.x, current_location.y].children[1]
            #if it's not already there, make sure to add this node to the search tree. won't make the search tree too big because we only count downstream stuff
            if ismissing(search_tree[next_location.x, next_location.y])
                search_tree = add_to_search_tree(TreeNode(next_location, current_location, filter!(x->x!=current_location, deepcopy(node_matrix[next_location.x, next_location.y].neighbors))), search_tree)
            end
            current_location = next_location
            moved = true
        #deadend, go back to parent
        elseif length(search_tree[current_location.x, current_location.y].children) < 1
            if current_location==Coordinate(5,2)
                #println("deadend")
            end
            current_location = search_tree[current_location.x, current_location.y].parent
            moved = true
        elseif size_of_downstream_tree(current_location, search_tree) >= max_tree_size #if search tree is too big, move based on heuristic
            if current_location==Coordinate(5,2)
                #println("search tree too big")
                #println("size_of_downstream_tree ", size_of_downstream_tree(current_location, search_tree))
                #println("printing search tree")
                # (w, h) = size(search_tree)
                # for i = 1:w
                #     for j = 1:h
                #         #println(i, " ", j)
                #         #println(search_tree[i,j])
                #     end
                # end
            end
            current_location = find_best_move(current_location, goal_location, search_tree)
            moved = true
        else
            #println("could have but didn't move")
            #println("size_of_downstream_tree ", size_of_downstream_tree(current_location, search_tree))
            ##println(current_location)
            #print the search tree
            #println("printing search tree")
            # (w, h) = size(search_tree)
            # for i = 1:w
            #     for j = 1:h
            #         #println(i, " ", j)
            #         #println(search_tree[i,j])
            #     end
            # end
        end
    end

    if moved
        time_since_last_move = 1
    else
        time_since_last_move = time_since_last_move + 1
    end

    next_state = State(current_location, search_tree, distracted, time_since_last_move, time_since_last_thought, path_to_goal)
    return next_state
end

chain = Gen.Unfold(kernel)
Gen.load_generated_functions()

@gen function unfold_model(T::Int64)
    #set parameters and such
    time_per_thought = @trace(uniform_discrete(1, 3), :time_per_thought)
    time_per_move = @trace(uniform_discrete(4, 8), :time_per_move)
    max_tree_size = @trace(uniform_discrete(5, 25), :max_tree_size)

    tree = Matrix{Union{TreeNode, Missing}}(missing, h, w)
    start_node = TreeNode(start_location, start_location, deepcopy(node_matrix[start.location.x, start.location.y].neighbors))#location, parents, children
    add_to_search_tree(start_node, tree)
    path_to_goal = []
    # record initial state
    init_state = State(start_location, tree, false, 0, 0, path_to_goal)

    # run `chain` function under address namespace `:chain`, producing a vector of states
    states = @trace(chain(T, init_state, time_per_thought, time_per_move, max_tree_size, goal_location), :chain)

    result = (init_state, states)
    return result
end

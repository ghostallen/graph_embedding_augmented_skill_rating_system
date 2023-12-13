### Construct a skill gap graph.


# Parse the input data into Julia dataframes.
function encoding_player(df_local, encoding_dict=Dict())
    if (length(encoding_dict) == 0) == true

        to_be_encoded = [i for i in 1:length(unique(df_local[:, 3]))]
        raw_list = unique(df_local[:, 3])
        encoding = Dict(raw_list.=>to_be_encoded)
        decoding = Dict(to_be_encoded.=>raw_list)
        df_local[:, 3] =  [encoding[i] for i in df_local[:, 3]]

    elseif (length(encoding_dict)==0) == false
        existed_encoded_pid = collect(values(encoding_dict))
        new_pid_count = 1
        encoding = copy(encoding_dict)

        for possible_new_pid in unique(df_local[:, 3])
            if possible_new_pid in keys(encoding)
                continue
            else
                new_encoded_pid = maximum(existed_encoded_pid) + new_pid_count
                encoding[possible_new_pid] = new_encoded_pid
                new_pid_count += 1
            end
        end

        df_local[:, 3] = [encoding[i] for i in df_local[:, 3]]
        println("Encoding complete.")

    end
    return df_local, encoding
end


function sgg_add_edges_by_game(graph, specific_game)
    win_loss = Dict(1=>1, 0=>-1)
    current_players = specific_game[:, 3]
    for (iter, player1) in enumerate(current_players)
        lefted = current_players[(iter+1):end]

        s = specific_game
        for player2 in lefted

            small_p = min(player1, player2)
            big_p = max(player1, player2)

            small_p_outcome = s[s[:, 3].==small_p, 2][end]
            big_p_outcome = s[s[:, 3].==big_p, 2][end]

            if small_p_outcome != big_p_outcome
            # Indicates that they are on different teams.
                if add_edge!(graph, player1, player2) == true
                    set_prop!(graph, player1, player2, :matches, 1)
                    set_prop!(graph, player1, player2,
                     :wins, win_loss[small_p_outcome])
                else
                    x = get_prop(graph, player1, player2, :matches)
                    set_prop!(graph, player1, player2,
                     :matches, (1+x))

                    c = get_prop(graph, player1, player2, :wins)
                    set_prop!(graph, player1, player2, :wins,
                     (win_loss[small_p_outcome]+c))
                end
            end
        end
    end
    return graph
end


function sgg_add_edges(graph, df_local)
    game_list = unique(df_local[:, 1]) |> collect
    for gameid in game_list
        graph = sgg_add_edges_by_game(graph, df_local[df_local[:, 1].==gameid, :])
    end
    return graph
end


function sgg_weight_function(x::Number)::Number
    return 1 - tanh(abs(x))
end


function sgg_set_weight(graph)
    weights = []
    matches_list = []
    wins_list = []
    #println("setting weights.")

    for edge in collect(edges(graph))
        wins = get_prop(graph, edge, :wins)
        matches = get_prop(graph, edge, :matches)
        x = wins/matches

        if matches >= 2
            new_weight = sgg_weight_function(x)
        else
            new_weight = 0.01
        end

        set_prop!(graph, edge, :weight, new_weight)
        push!(weights, new_weight)
        push!(matches_list, matches)
        push!(wins_list, wins)
    end

    return graph
end


function get_skill_gap_graph(df_local)
    g = MetaGraph()
    add_vertices!(g, maximum(df_local[:, 3]))
    g = sgg_add_edges(g, df_local)
    g = sgg_set_weight(g)
    return g
end

# Retrieve neighbor relations in dictionary form.
function get_dict_nei(graph)
    dict_nei = Dict{Int, Vector}()
    for node in collect(vertices(graph))
        push!(dict_nei, node=>neighbors(graph, node))
    end
    return dict_nei
end

# Get adjacent matrix.
function get_adj_matrix(graph)::Array{Float64, 2}
    nodes = collect(vertices(graph))
    weight_mat = Array{Float64, 2}(undef, (length(nodes), length(nodes)))
    for (i, node_1) in enumerate(nodes)
        temp_node_list = copy(nodes)
        for node_2 in deleteat!(temp_node_list, i)
            if has_edge(graph, node_1, node_2) == true
                weight_mat[node_1, node_2] = get_prop(graph, node_1, node_2, :weight)
            end
        end
    end
    return weight_mat
end

# "Transition Distance" function from DeepWalk.
function d_tx(prev::Int, target::Int, graph)::Int
    if has_edge(graph, prev, target)
        d = 1
    elseif prev == target
        d = 0
    else
        d = 2
    end
    return d
end

# Save walks to csv. Debugging usage.
function walks2csv(walks, output="output.csv")
    starting_node_list = []
    rows = 0
    for walk in walks
        append!(starting_node_list, walk[1])
        rows += 1
    end
    node_length = unique(starting_node_list)

    walks_mat = zeros((rows, length(walks[1])))

    for (index, walk) in enumerate(walks)
        walks_mat[index, :] = walk
    end
    test = DataFrame(walks_mat, :auto)
    CSV.write(output, test, writeheader=false)
end
### Get a SGG; classifying active players; calculating rating scores.

## Calling Python.
#using Conda
using PyCall
scriptdir = @__DIR__
pushfirst!(PyVector(pyimport("sys")."path"), scriptdir)
player_emb = pyimport("node_embedding")
np = pyimport("numpy")
pd = pyimport("pandas")

using StatsBase
using LinearAlgebra
using Graphs
using MetaGraphs
using Random
using Distributions
using DataFrames
using CSV
using Dates

include("sgg.jl")
include("elo.jl")
include("score_tracker.jl")

# "sgg" stands for "skiil gap graph".
function random_walk_on_sgg(starting_node::Number, walk_length::Int64,
     dict_nei::Dict{Int,Array{T,1} where T}, weight_mat::Array{Float64, 2})::Array{Int}

    i::Int, v::Int = 0, 0
    walk = Array{Int, 1}([starting_node])

    s = starting_node
    init_nei = [weight_mat[s, n] for n in dict_nei[s]]
    append!(walk, dict_nei[s][rand(Categorical(init_nei/sum(init_nei)))])
    
    while (i+3) <= walk_length
        v, t = walk[end], walk[end-1]
        pai = Array{Float64}([weight_mat[v, X] for X in dict_nei[v]])
        push!(walk, dict_nei[v][rand(Categorical(pai/sum(pai)))])
        i += 1
    end
    
    return walk
end


function get_random_walks(graph, repeat_time=10, walk_length=50)

    nodes = collect(vertices(graph))
    dict_nei = get_dict_nei(graph)
    weight_mat = get_adj_matrix(graph)
    #global weight_mat_debug = copy(weight_mat)

    walks = [Array{Int64}(undef, walk_length) for i in 1:(repeat_time*length(nodes))]
    index = [i for i in 1:length(walks)]

    w = []
    for i in 1:repeat_time
        append!(w, nodes)
    end

    # Enable multi-threading.
    Threads.@threads for id in index
        walks[id] = random_walk_on_sgg(w[id], walk_length, dict_nei, weight_mat)

    end
    
    global walks_debug = copy(walks)
    return walks
end


function pipeline_learn_player_emb(df_local, repeat_time, walk_length, window_size)
    g = get_skill_gap_graph(df_local)

    println("Performing random walks.")

    rw_start_time = Dates.now().instant.periods.value
    rw_walks = get_random_walks(g, repeat_time, walk_length)
    rw_time_cost = (Dates.now().instant.periods.value - rw_start_time)/1000
    global rw_walks_debug = copy(rw_walks)

    emb_start_time = Dates.now().instant.periods.value
    result_emb = player_emb.learn_node_emb(rw_walks, vector_size=300, window=window_size)
    emb_time_cost = (Dates.now().instant.periods.value - emb_start_time)/1000

    println("RW costs ",string(rw_time_cost),
     " seconds; ", "embedding costs ",string(emb_time_cost), " seconds.")

    return result_emb, g, (rw_time_cost, emb_time_cost)
end



## Post-adjustment to player scores.

function cosm(x::Array, y::Array)::Number
    result = dot(x, y)/(norm(x)*norm(y))
    return result
end

function get_matches(df_local)
    gameid = collect(unique(df_local[:, 1]))
    playerid = sort(collect(unique(df_local[:, 3])))
    matches = [0 for i in 1:length(playerid)]
    for game in gameid
        specific_game = df_local[df_local[:, 1].==game, 3]
        #global specific_game_debug = copy(specific_game)
        matches[specific_game] .+= 1
    end
    return matches
end

# Get a proper proportion for defining activeness players.
function get_best_AP_prop(match_count)::Number
    x = transpose(
     hcat([[i, count(==(i), match_count)] for i in unique(match_count)]...)
     )
    x = sortslices(x, dims=1)

    sd = Array{Float32, 1}(undef, 0)
    for i in 2:(size(x)[1]-1)
        sd_value = x[i+1, 2] + x[i-1, 2] - 2*x[i, 2]
        append!(sd, sd_value)
    end

    cutting_point = argmax(sd)+1
    best_prop = round(1-sum(x[x[:, 1].<=cutting_point, 2])/sum(x[:, 2])[1], digits=3)
    println("Elbow point: ", string(cutting_point), "; Best AP prop: ", string(best_prop))

    return max(0.2, best_prop) # Set a minimum "AP proportion" of 20%.
end

# Calculate Elo and adjusted(gelo) rating scores.
function cal_ratings_elo_adj(r_dict::Dict{Any,Number}, nodevec, g=graph, df=df_local;
     K::Number=50, dataset::String)

    nodes = sort(collect(keys(r_dict)))

    r_adj = copy(r_dict)
    r_elo = copy(r_dict)

    sw = get_matches(df)
    best_prop = get_best_AP_prop(sw)
    embedding_mat_raw = hcat(nodevec[nodes, :],
     sw, [r_dict[key] for key in nodes], [i for i in nodes])
    embedding_mat_raw = sortslices(embedding_mat_raw, dims=1, by=x->x[end-2], rev=true)

    folder_embs = folder_results * "embeddings/"

    if isdir(folder_embs) == false
        mkdir(folder_embs)
    end

    pd.DataFrame(embedding_mat_raw[:, 1:(end-2)]).to_csv(
     folder_embs*dataset*"_emb.csv",
      index=false)

    embedding_mat = embedding_mat_raw[
     1:Int(round(best_prop*(size(embedding_mat_raw)[1]), digits=0)), :]

    #global embedding_mat_raw_debug = copy(embedding_mat)

    e = embedding_mat
    f = e[:, 1:end-3]
    head = argmax(e[:, end-1])
    tail = argmin(e[:, end-1])

    head_emb = f[head, :]
    tail_emb = f[tail, :]

    sim_range = cosm(head_emb, tail_emb)

    for (i, node) in enumerate(embedding_mat[:, end])
        ch = cosm(f[i, :], head_emb)
        cb = cosm(f[i, :], tail_emb)

        if (ch < 0 | 1-cb < 0)
            println(r_adj[Int(node)])
        end

        r_adj[Int(node)] += K*(mean([abs(ch), abs(1-cb)])/abs(sim_range))
    end

    return r_elo, r_adj
end


### Misc functions.

# Split dataframe by specfing dates.
function d(df_local, date::Int)
    return df_local[df_local[:, 4].==date, :]
end

function d(df_local, date_start::Int, date_end::Int)
    df_output = df_local[df_local[:, 4].>=date_start, :]
    return df_output[df_output[:, 4].<=(date_end), :]
end
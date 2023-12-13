scriptdir = @__DIR__
include("gelo.jl")

function gelo_test(dataset::String, start::Int, ends::Int, prev_period::Int=1,
     K_value::Number=50, step::Int=1, use_prev_dict::Bool=false,
     p_repeat_time::Number=p_repeat_time, p_walk_length::Number=p_walk_length;
     RV_per_match::Bool=false, RV_per_subdataset::Bool=false)


    if (RV_per_match & RV_per_subdataset) == true
        global folder_results = scriptdir*"/experiments_detail/" * dataset * "_result/"
    elseif (RV_per_match & RV_per_subdataset) == false
        global folder_results = scriptdir*"/experiments/" * dataset * "_result/"
    end

    if isdir(folder_results) == false
        mkpath(folder_results)
    end

    df = CSV.File(scriptdir*"/datasets/"*dataset*".csv") |> Tables.matrix
    println("---------Dataset: ", dataset, "---------")
    features = ["date", "error_elo", "error_adj", "added_players",
     "new_pid_percentage", "matches_count", "p_repeat_time",
     "p_walk_length", "rw_time_cost", "emb_time_cost","nv", "ne", "period",
      "window_size"]
    global df_output = pd.DataFrame(columns=features)

    println("Start: ", start, "; ends: ", ends,
     "; preiods: ", prev_period, "; step: ", step)

    r_dict = Dict()
    for date in start:step:ends

        start = date - prev_period
        ends = date

        #global df_debug = d(df, start, ends)

        global df_now, encoding_now = encoding_player(d(df, start, ends))
        global df_next, encoding_next = encoding_player(d(df, start, ends+future_range))

        #matches_count = length(df_now[df_now[:, 3].==date, :])
        matches_count = length(unique(df_now[:, 1]))

        result = []
        detailed = []

        r_elo_before = calculate_elo(df_now, K_value)

        #println("---------------performing rw & embedding---------------")

        nodevec_test, g_test, time_cost = pipeline_learn_player_emb(
         df_now, p_repeat_time, p_walk_length, window_size)

        global g_debug = copy(g_test)

        println("-----------------------")
        println("Date: ", date-2, "; dataset:", dataset,
         "; prev_period:", prev_period)
        r_elo_before, r_adj_before = cal_ratings_elo_adj(r_elo_before,
         nodevec_test, g_test, df_now, K=K_value, dataset=dataset)
        global debug_test = d(df_next, date+1)
        global r_adj_before_debug, r_elo_before_debug = copy(r_adj_before),
         copy(r_elo_before)


        if RV_per_subdataset == false

            error_elo, elo_match_log, r_elo_after = error_test(df_next,
             r_elo_before, date+1, date+future_range, K_value)
            error_adj, adj_match_log, r_adj_after = error_test(df_next,
             r_adj_before, date+1, date+future_range, K_value)

        elseif RV_per_subdataset == true

            error_elo, elo_match_log, r_elo_after = error_test_detail(df_next,
             r_elo_before, date+1, date+future_range, K_value)
            error_adj, adj_match_log, r_adj_after = error_test_detail(df_next,
             r_adj_before, date+1, date+future_range, K_value)


            # "dfr" is the abbrev of`` "detailed final results".
            dfr_folder = folder_results*"final_rank/"
            if isdir(dfr_folder) == false
                mkdir(dfr_folder)
            end
            dfr_b4 = dfr_folder*"before_"*string(dataset)*"_"*string(date)*".csv"
            dfr_af = dfr_folder*"after_"*string(dataset)*"_"*string(date)*".csv"
            get_final_rank(r_elo_before, r_adj_before, dfr_b4)
            # active players list.
            active_p_list = unique(df_next[df_next[:, 4].>maximum(df_now[:, 4]), 3])
            get_final_rank(r_elo_after, r_adj_after, dfr_af, active_p_list)

            dfr_col = ["gameid", "score_winner_before",
            "score_winner_after","score_loser_before","score_loser_after",
             "error_pred", "rank_var"]
   
            if track_RV_detail == true
                output_dfr_folder = folder_results*"rank_detail/"
                if isdir(output_dfr_folder) == false
                    mkdir(output_dfr_folder)
                end
            end
    
            dfr = output_dfr_folder*dataset
            pd.DataFrame(elo_match_log, columns=dfr_col).to_csv(
                dfr*"_elo_"*string(date)*".csv", index=false)
            pd.DataFrame(adj_match_log, columns=dfr_col).to_csv(
                dfr*"_adj_"*string(date)*".csv", index=false)

        end

        println("elo: ", string(error_elo*100))
        println("adj: ", string(error_adj*100))

        added_pid = length(keys(r_elo_after)) - length(keys(r_elo_before))
        new_pid_percentage = added_pid/length(keys(r_elo_after))
        #matches_count = length(unique(df_next[:, 1])) - length(unique(df_now[:, 1]))

        push!(detailed, (error_elo, error_adj))

        global result = Dict(features .=> [date, error_elo, error_adj, added_pid,
        new_pid_percentage, matches_count, p_repeat_time, p_walk_length,
        time_cost[1], time_cost[2], nv(g_test), ne(g_test),
        prev_period, window_size])

        df_output = pd.concat([df_output, pd.DataFrame([result])], ignore_index=true)

        println("=========Round Over=========")

    end
    println("=================  TEST OVER  =================")

    output_file = folder_results*dataset*"_iter"*string(
     loop_counter)*"_result.csv"

    df_output.to_csv(output_file , index=false)


    output = [df_output."error_elo".to_numpy(),
     df_output."error_adj".to_numpy()]

    global output_debug = copy(output)

    return output
end


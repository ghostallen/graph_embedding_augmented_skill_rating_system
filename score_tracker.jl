## Score tracker for experiments.


function error_test(df_input::Array{Int64,2}, r_dict_input::Dict{Any,Number},
    start_date::Number, end_date::Number, K::Number=50)

   r_dict = copy(r_dict_input)
   df = d(df_input, start_date, end_date)
   nodes = sort(collect(keys(r_dict)))
   total_match = length(unique(df[:, 1]))
   pids = unique(df[:, 3])
   errors::Int = 0
   mean_score = mean(values(r_dict))
   game_list = unique(df[:, 1])
   game_log = []

   for pid in df[:, 3]
       if (pid in nodes) == false
           r_dict[pid] = mean_score
       end
   end

   for gameid in game_list

       append!(game_log, gameid)

       game = df[df[:, 1].==gameid, :]
       players = game[:, 3]
       winners = game[game[:, 2].==1, :]
       losers = game[game[:, 2].==0, :]
       r_team_winner = get_mean_score(winners, r_dict)
       r_team_loser = get_mean_score(losers, r_dict)

       if r_team_winner < r_team_loser
           errors += 1
       end

       for winner in winners[:, 3]
           Ra, Rb = elo(r_dict[winner], r_team_loser, K)
           r_dict[winner] = Ra
       end

       for loser in losers[:, 3]
           Ra, Rb = elo(r_team_winner, r_dict[loser], K)
           r_dict[loser] = Rb
       end


   end

   l = length(game_log)
   score_winner_before = zeros((l, 1))
   score_winner_after = zeros((l, 1))
   score_loser_before = zeros((l, 1))
   score_loser_after = zeros((l, 1))
   error_log = zeros((l, 1))
   rank_var = zeros((l, 1))

   log_mat = hcat(game_log, score_winner_before,
    score_winner_after, score_loser_before,
     score_loser_after, error_log, rank_var)


   return errors/total_match, log_mat, r_dict
end


function error_test_detail(df_input::Array{Int64,2}, r_dict_input::Dict{Any,Number},
    start_date::Number, end_date::Number, K::Number=50)

   r_dict = copy(r_dict_input)
   df = d(df_input, start_date, end_date)
   nodes = sort(collect(keys(r_dict)))
   total_match = length(unique(df[:, 1]))
   pids = unique(df[:, 3])
   errors = 0
   mean_score = mean(values(r_dict))
   game_list = unique(df[:, 1])

   game_log = []

   score_var = []

   error_log = []

   score_winner_before = []

   score_winner_after = []

   score_loser_before = []

   score_loser_after = []

   rank_var = []

   for pid in df[:, 3]
       if (pid in nodes) == false
           r_dict[pid] = mean_score
           #r_dict[pid] = 1500
       end
   end

   for gameid in game_list

       append!(game_log, gameid)

       game = df[df[:, 1].==gameid, :]

       #global game_debug = copy(game)

       players = game[:, 3]

       winners = game[game[:, 2].==1, :]
       losers = game[game[:, 2].==0, :]
       r_team_winner = get_mean_score(winners, r_dict)
       r_team_loser = get_mean_score(losers, r_dict)

       append!(score_winner_before, r_team_winner)
       append!(score_loser_before, r_team_loser)

       #winner_id, loser_id = winner[:, 3], loser[:, 3]

       r_rank_dict_before_match = get_player_rank_dict(r_dict)

       if r_team_winner < r_team_loser
           #predict error
           errors += 1
           append!(error_log, 1)
       else
           append!(error_log, 0)
       end

       for winner in winners[:, 3]
           Ra, Rb = elo(r_dict[winner], r_team_loser, K)
           r_dict[winner] = Ra
       end

       for loser in losers[:, 3]
           Ra, Rb = elo(r_team_winner, r_dict[loser], K)
           r_dict[loser] = Rb
       end

       r_rank_dict_after_match = get_player_rank_dict(r_dict)

       rank_before_match = []
       rank_after_match = []

       for p in players
           push!(rank_before_match, r_rank_dict_before_match[p])
           push!(rank_after_match, r_rank_dict_after_match[p])
       end

       push!(rank_var, sum(abs.(rank_before_match-rank_after_match)))

       append!(score_winner_after, get_mean_score(winners, r_dict))
       append!(score_loser_after, get_mean_score(losers, r_dict))

   end

   log_mat = hcat(game_log, score_winner_before,
    score_winner_after,score_loser_before,score_loser_after,
     error_log, rank_var)

   return errors/total_match, log_mat, r_dict
end


function get_player_rank_dict(r_dict::Dict{Any,Number})::Dict{Any,Number}
   x = collect(values(r_dict))
   y = collect(keys(r_dict))
   length_x = length(x)
   output = Dict(y.=>( (length_x + 1) .- ordinalrank(x)))
   return output
end


function get_final_rank(r_elo::Dict{Any,Number}, r_adj::Dict{Any,Number},
    output_loc::String)
   a = get_player_rank_dict(r_elo)
   b = get_player_rank_dict(r_adj)
   output = []
   for key in keys(a)
       push!(output, (key, a[key], b[key]))
   end
   df = pd.DataFrame(output, columns=["id", "elo", "adj"]).sort_values(by="id")

   df.to_csv(output_loc, index=false)

   return df
end

function get_final_rank(r_elo::Dict{Any,Number}, r_adj::Dict{Any,Number},
    output_loc::String, active_players::Vector)
   a = get_player_rank_dict(r_elo)
   b = get_player_rank_dict(r_adj)

   keys_list = collect(keys(a))
   is_active_dict = Dict()
   for key in keys_list
       if (key in active_players) == true
           is_active_dict[key] = 1
       else
           is_active_dict[key] = 0
       end
   end

   output = []
   for key in keys_list
       push!(output, (key, a[key], b[key], is_active_dict[key]))
   end
   df = pd.DataFrame(output, columns=["id", "elo", "adj", "active"]).sort_values(by="id")
   df.to_csv(output_loc, index=false)

   return df
end
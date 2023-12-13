### Elo alogrithm.


function elo_probability(rating1::Number, rating2::Number)::Number
    return 1/(1 + 10^((rating1-rating2)/400))
end


function elo(Ra::Number, Rb::Number, K::Number=50)::Tuple{Number,Number}
    #println(K)
    #Ra is the winner. 
    Pb = elo_probability(Ra, Rb)
    Pa = 1 - Pb
    Ra = Ra + K * (1 - Pa)
    Rb = Rb + K * (0 - Pb)
    return (Ra, Rb)
end


function get_mean_score(df::Array{Int64,2}, r_dict::Dict{Any,Number})::Number
    return mean(getindex.(Ref(r_dict), (df[:, 3])))
end


function calculate_elo(df::Array{Int64,2}, K::Number=50,
     R_initial::Number=1500)::Dict{Any,Number}

    #println("inaltize ratings.")
    r_dict = Dict{Any, Number}()
    for i in unique(df[:, 3])
        push!(r_dict, i=>R_initial)
    end
    game_list = unique(df[:, 1])
    for gameid in game_list
        game = df[df[:, 1].==gameid, :]
        winners = game[game[:, 2].==1, :]
        losers = game[game[:, 2].==0, :]
        r_team_winner = get_mean_score(winners, r_dict)
        r_team_loser = get_mean_score(losers, r_dict)
        for winner in winners[:, 3]
            Ra, Rb = elo(r_dict[winner], r_team_loser, K)
            r_dict[winner] = Ra
        end

        for loser in losers[:, 3]
            Ra, Rb = elo(r_team_winner, r_dict[loser], K)
            r_dict[loser] = Rb
        end

    end

    return r_dict
end

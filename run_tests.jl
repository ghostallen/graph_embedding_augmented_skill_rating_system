include("test.jl")
loop_iterations = 5
datasets = ["sc2", "cs1", "cs2", "lol_champ", "atp"]

### Parameters#


## Number of CPU threads for random walking. 
ENV["JULIA_NUM_THREADS"] = 1

## Key hyper parameters for player embedding.
# Length of a single random walk.
global p_walk_length = 100
# Repeat times of walking processes starting from each node.
global p_repeat_time = 16
# Context window.
global window_size = 5

## Rank variation tracker for TABLE-II from the paper.
global track_RV_detail = false # Rv represnts rating variation

struct RV_details
    per_match::Bool
    per_subdataset::Bool
end
if track_RV_detail == true
    RV_tracker = RV_details(true, true)
    loop_iterations = 1 # Shortening testing time costs, as tracking RV details is slow.
else
    RV_tracker = RV_details(false, false)
end

## Other parameters. 
# Prediction range.
global future_range = 2
# Range of match history for learning embeddings per sub-dataset.
global prev_periods = [1]
# Specify the range of data to be tested. 
global start_date = 3
global end_date = 12

# K value for Elo alogrithm.
global K_value = 50

# Seeds.
#global rng_seed = 0
#Random.seed!(rng_seed)

#####################################

### Initiate tests

for dataset in datasets
    #println(dataset)
    for i in 1:loop_iterations

        global loop_counter = i

        prev_dur_str = Dict(1=>"one")

        for prev_dur in prev_periods
            println("")
            println("%%%%%%%%%%%% Loop round: ", string(loop_counter), " %%%%%%%%%%%%")

            gelo_result = gelo_test(dataset, start_date, end_date, prev_dur, K_value, 
             RV_per_match=RV_tracker.per_match, 
             RV_per_subdataset=RV_tracker.per_subdataset)

        end
    end
end

println("Window size: ", string(window_size), "; future range: ", string(future_range))

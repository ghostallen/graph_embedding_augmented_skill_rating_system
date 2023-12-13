import pandas as pd
import numpy as np
from tqdm import tqdm
df_results = pd.read_csv('./raw_data/cs/results.csv').sort_values(by=['date', 'match_id'])
df_players = pd.read_csv('./raw_data/cs/players.csv').sort_values(by=['date', 'match_id'])

df_players['team_id'] = pd.factorize(df_players['team'])[0]

team_encode_dict = dict(zip(df_players['team'].unique(), df_players['team_id'].unique()))

for (i, row) in tqdm(df_results.iterrows()):
    if (row['team_1'] in team_encode_dict)&(row['team_2'] in team_encode_dict):
        row['team_1'] = team_encode_dict[row['team_1']]
        row['team_2'] = team_encode_dict[row['team_2']]


df1 = pd.DataFrame(columns=['game_id', 'is_win', 'player_id', 'date', 'id1'])

df_results['month'] = df_results['date'].apply(lambda x: str(x)[:-3])
df_results['encoded_date'] = pd.factorize(df_results['month'])[0]

#%%

cols = ['game_id', 'is_win', 'player_id', 'date']
vc_1 = df_players['match_id'].value_counts()

gamelist = df_players['match_id'].unique()
gamelist = gamelist[vc_1==10]

vc_2 = df_results['match_id'].value_counts()

temp = []

for gameid in tqdm(gamelist):
    x = df_results[df_results['match_id']==gameid]
    if len(x) != 0:
        temp_game_x = x.iloc[-1, :]
        #considering bo3, bo5 games.
        date = temp_game_x['encoded_date']
        if temp_game_x['match_winner'] == 1:
            is_team1_win, is_team2_win = 1, 0
        else:
            is_team1_win, is_team2_win = 0, 1
        temp_game = df_players[df_players['match_id']==gameid]
        
        team1 = temp_game[temp_game['team']==temp_game_x['team_1']]
        team2 = temp_game[temp_game['team']==temp_game_x['team_2']]
        
        if is_team1_win == 1:
            winner, loser = team1, team2
        else:
            winner, loser = team2, team1
        
        for (i, row) in winner.iterrows():
            temp.append([gameid, 1, row['player_id'], date])
        for (i, row) in loser.iterrows():
            temp.append([gameid, 0, row['player_id'], date])
        


df1 = pd.DataFrame(temp, columns=cols)
df1_backup = df1.copy()

#%%

gamelist = df1['game_id'].unique()

vc = (df1['game_id'].value_counts() == 10)
df1 = df1.loc[df1['game_id'].isin(vc.index[vc]), :]

#df1['game_id'] = df1['game_id'].astype('category').cat.codes.astype('Int32')
df1['game_id'] = pd.factorize(df1['game_id'])[0] + 1
df1['player_id'] = pd.factorize(df1['player_id'])[0] + 1
df1['date'] = df1['date'] + 1


#%%

df2 = df1[df1['date']>=(df1['date'].max() - 13)]

#df2.loc[:, 'date'] = df['date'].astype('category').cat.codes.astype('Int32')
df2.loc[:, 'date'] = df2['date'] - min(df2['date']) + 1
df2['game_id'] = pd.factorize(df2['game_id'])[0] + 1
df2['player_id'] = pd.factorize(df2['player_id'])[0] + 1

df1.to_csv(r'cs1.csv', index=False)
df2.to_csv(r'cs2.csv', index=False)



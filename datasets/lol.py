import pandas as pd
import numpy as np

df = pd.read_csv(r'./raw_data/lol_championship.csv')

df['id'] = range(len(df))
df['player'] = df['player'].replace('Team', np.nan)
df['player_id'] = df['player'].astype('category').cat.codes
df['gameid'] = df['gameid'] + df['league']
df1 = df[['gameid', 'split', 'result', 'player_id']]
df1.columns = ['game_id', 'split', "is_win", "player_id"]
df1['split'] = df1['split'].str[:6]
df1['date'] = pd.factorize(df1['split'])[0]

df1['game_id'] = pd.factorize(df1['game_id'])[0]

df1 = df1.drop(columns='split')
df1 = df1.replace(-1, np.nan)
df1_debug = df1.copy()
df1 = df1.dropna()
df1['player_id'] = pd.factorize(df1['player_id'])[0]
df1['game_id'] = df1['game_id'] + 1
df1['player_id'] = df1['player_id'] + 1
df1['date'] = df1['date'] + 1

# Remove error games.
vc = (df1['game_id'].value_counts() == 10)
df_output = df1.loc[df1['game_id'].isin(vc.index[vc]), :]

df_output.to_csv(r'lol_champ.csv', index=False)
import pandas as pd
import numpy as np
from tqdm import tqdm
filelist = ['atp_matches_' + str(i) + '.csv' for i in range(2003, 2016)]

merged = pd.DataFrame()

na = np.nan

for f in filelist:

    df = pd.read_csv(r'./raw_data/tennis/'+f)
    df.index = range(len(df))
    df = df.loc[:, ['winner_name', 'loser_name', 'tourney_date', 'match_num']]
    df = df.dropna()

    merged = pd.concat([merged, df], ignore_index=True)
    
merged = merged.sort_values(by=['tourney_date', 'match_num'])

merged = merged.reset_index(drop=True)

merged_backup = merged.copy()

merged['tourney_date'] = merged['tourney_date'].apply(lambda x: str(x)[:4])
#merged['tourney_date'] = merged['tourney_date'].astype('category').cat.codes.astype('Int32')
merged['tourney_date'] = pd.factorize(merged['tourney_date'])[0]


#%%

cols = ['game_id', 'is_win', 'player_id', 'date']
df1 = pd.DataFrame(columns=cols)
df = merged.copy()

#%%
'''

#df:gameid, is_win, playerid, date.
for (i, row) in tqdm(df.iterrows()):
    
    d = row['tourney_date']

    df1.loc[len(df1)] = [i, 1, row['winner_name'], d]
    df1.loc[len(df1)] = [i, 0, row['loser_name'], d]
'''    
    
#%%

temp = []

for (i, row) in tqdm(df.iterrows()):
    d = row['tourney_date']
    #df1.loc[len(df1)] = [i, 1, row['winner_name'], d]
    #df1.loc[len(df1)] = [i, 0, row['loser_name'], d]
    #a.append([i, 1, row['winner_name'], d])
    #a.append([i, 0, row['loser_name'], d])
    temp.extend([[i, 1, row['winner_name'], d], [i, 0, row['loser_name'], d]])


df1 = pd.DataFrame(temp, columns=cols)

df2 = df1.copy()

#%%


'''

df2.index = [i for i in range(len(df2))]
for (i, row) in tqdm(df2.iterrows()):
    last_row = df2.iloc[i-1, :]

    if last_row['gameid'] == row['gameid']:
        if last_row['playerid'] == row['playerid']:
            df2.iloc[[i-1, i], 0] = na
            print('repeative pid')
        if last_row['date'] != row['date']:
            df2.iloc[i, 3] = df2.iloc[i-1, 3]
            print(i, ' changed')
'''
       
#%%

df2 = df2.dropna()

# Remove error games.
vc = (df2['game_id'].value_counts() == 2)
df2 = df2.loc[df2['game_id'].isin(vc.index[vc]), :]


df2['game_id'] = pd.factorize(df2['game_id'])[0] + 1
#df2['playerid'] = df2['playerid'].astype('category').cat.codes.astype('Int32')
df2['player_id'] = pd.factorize(df2['player_id'])[0] + 1
df2['date'] = df2['date'] + 1

df2.astype('Int32').dropna().to_csv(r'atp.csv', index=False)

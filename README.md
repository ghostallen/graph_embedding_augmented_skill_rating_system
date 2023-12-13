This repository contains the source code (with datasets included) for the research paper titled "Graph Embedding Augmented Skill Rating System," published in IEEE Transactions on Games (DOI: 10.1109/TG.2022.3221849). The paper can be accessed on [arXiv](https://arxiv.org/abs/2304.08257).
This method/framework aims to improve skill rating accuracy in games.

## Usage

- Reproduction: Run "run_tests.jl". Setting "global track_RV_detail" to decide whether to track "rank variations" mentioned in Section V-D from the paper (tracking RV is slow). The experiment results are outputed to "/experiments" and "/experiments_detail"

- Application: Use "gelo.jl". 

## File Descriptions

### 1. Skill-Rating Framework

- **gelo.jl:**. This main/pipeline file of the skill-rating framework. 
  
- **sgg.jl:** constructs a Skill Gap Graph based on datasets.
  
- **node_embedding.py:** learn node embedding from random walks.
  
- **elo.jl:** implements the Elo algorithm.

### 2. Experimental Simulation Scripts

- **test.jl:** Houses the main experiments.

- **score_tracker.jl:** Provides detailed experiment tracking.

### 3. Experimental Results

- Files in "/experiments" & "/experiments_detail." The latter tracks "rank variations" results.

### 4. Datasets

- Located in "/datasets." 

- "*.csv" files represent data directly used by the program.

- ".py" files are scripts for processing raw data from "/raw_data/*.csv." 

## Dependencies

The program was implemented using Julia (primarily) and Python, as stated in the paper. 

As of sending this communication, the program has been successfully executed it in the following environments:

- **Julia:** Version 1.9.4, with all packages installed at their latest versions.

- **Python:** Anaconda Distribution 2023.09 (Python 3.11).

- Noted that PyCall.jl is used for calling Python modules in Julia. This may require some extra configurations based on your environment.

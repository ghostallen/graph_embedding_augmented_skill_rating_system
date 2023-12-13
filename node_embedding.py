import numpy as np
from gensim.models import Word2Vec


def nest_function(walk):
    return list(map(lambda x: str(x), walk))


def vocab(walks):#convert walks to vec of vecs, and string
    return list(map(lambda x: nest_function(x), walks))


def learn_node_emb(walks, vector_size=300, window:int=5, workers:int=16, skip_gram:int=1):
    tokenized = vocab(walks)
    model = Word2Vec(tokenized, vector_size=vector_size,
                     window=window, workers=workers, min_count=1, sg=skip_gram,
                      epochs=10, batch_words=10000)
    nodes = model.wv.index_to_key
    node_vec = np.zeros((len(nodes), vector_size))
    for i in range(len(nodes)):
        node_vec[i, :] = model.wv[str(i+1)]
    return node_vec

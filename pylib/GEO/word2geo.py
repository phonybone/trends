import os, sys, re, yaml
from Mongoid import Mongoid

#from warn import *

class Word2Geo(Mongoid):
    ''' 
    A class to model word <-> geo mappings.
    A single object in this class contains the fields: geo_id, word, count, source
    w2g.source can (currently) be one of: [title, description, summary, MeshHeading, ArticleTitle, AbstractText]
    '''

    db_name='geo'
    collection_name='word2geo'
    indexes=[{'keys': 'word', 'options': {}},
             {'keys': 'geo_id', 'options': {}},
             ]

    @classmethod
    def __class_init__(self):
        self.ensure_indexes()

Word2Geo.__class_init__()

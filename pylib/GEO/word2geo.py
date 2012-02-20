import os, sys, re, yaml
from Mongoid import Mongoid

from pubmed import Pubmed
from string_helpers import sanitized_list
from warn import *


class Word2Geo(Mongoid):
    ''' 
    A class to model word <-> geo mappings.
    A single object in this class contains the fields: geo_id, word, count, source
    w2g.source can (currently) be one of: [title, description, summary, MeshHeading, ArticleTitle, AbstractText]
    Because of this, there can be 
    '''

    db_name='geo'
    collection_name='word2geo'
    word_fields=['title', 'description', 'summary']
    indexes=[{'keys': 'word', 'options': {}},
             {'keys': 'geo_id', 'options': {}},
             ]

    @classmethod
    def __class_init__(self):
        self.ensure_indexes()

    @classmethod
    def insert_geo(self, geo):
        '''
        insert all words associated with a geo object into the word2geo db
        '''
        self.mongo().remove({'geo_id': geo.geo_id})

        # words: k=tag, v=list of sanitized words (may have dups)
        words=self.get_field_words(geo)
        if hasattr(geo, 'pubmed_id'):
            warn("%s: pubmed_id is %s" % (geo.geo_id, geo.pubmed_id))
            if type(geo.pubmed_id)==type([]):
                for pmid in [int(x) for x in geo.pubmed_id]:
                    words.update(self.get_pubmed_words(pmid))
            else:
                words.update(self.get_pubmed_words(int(geo.pubmed_id)))
        
        for source, words in words.items():
            for word in words:
                query={'geo_id':geo.geo_id, 'word':word, 'source':source}
                record=self.mongo().find_one(query)
                if record:
                    if 'count' in record: record['count']+=1
                    else: record['count']=1
                else:
                    record=query
                    record['count']=1
                self.mongo().save(record)
                    
        return
    
    @classmethod
    def get_field_words(self, geo):
        '''
        collect words from certain fields in the record:
        '''
        words={}
        for field in self.word_fields:
            words[field]=[]
            if hasattr(geo, field):
                word_list=getattr(geo, field)
                if type(word_list)==type(""):
                    word_list=[word_list]
                for wl in word_list:
                    for w in sanitized_list(wl):
                        words[field].append(w)
        return words


    @classmethod
    def get_pubmed_words(self, pubmed_id):
        ''' 
        return a dict in the same format as get_field_words: k=field, v=sanitized list of words
        '''
        words=dict()
        pubmed=Pubmed(pubmed_id).populate()
        for tag in Pubmed.text_tags:
            try: 
                words[tag]=getattr(pubmed, tag)
                warn("got %d words for %s" % (len(words[tag]), tag))
            
            except AttributeError as ae:
                warn("(%s): no %s words for %s?" % (ae, tag, pubmed_id))


        return words

Word2Geo.__class_init__()

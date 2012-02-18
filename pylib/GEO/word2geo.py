import os, sys, re
from Mongoid import Mongoid
sys.path.append('/usr/lib64/python2.6/site-packages') # need this for Entrez
from Bio import Entrez
from xml.dom.minidom import parseString
from string_helpers import sanitized_list
from warn import *
            

# recursive function to get all the words from a node:
# returns a list of words
def findText(anode):
    words=[]
    if anode.nodeType == anode.TEXT_NODE:
        return sanitized_list(anode.data)

    elif anode.hasChildNodes():
        for node in anode.childNodes:
            words.extend(findText(node))

    return words



class Word2Geo(Mongoid):
    db_name='geo'
    collection_name='word2geo'

    @classmethod
    def insert_geo(self, geo):
        self.mongo().remove({'geo_id': geo.geo_id})

        words=self.get_field_words(geo)
        if hasattr(geo, 'pubmed_id'):
            words.update(self.get_pubmed_words(geo.pubmed_id))
        
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
        words={}
        for field in ['title', 'description', 'summary']:
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
        words={}
        doc=parseString(Entrez.efetch(db="pubmed", id=pubmed_id, retmode='xml').read())
        for tag in ["MeshHeading" , "AbstractText", "ArticleTitle"]:
            words[tag]=[]
            for node in doc.getElementsByTagName(tag):
                words[tag].extend(findText(node))
        return words



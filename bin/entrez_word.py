from pymongo import Connection
from Bio import Entrez
import re
from xml.dom.minidom import parseString
"""
get pubmed words and add to mongodb
"""
def getPubmedIds(db, geo_id, limit=0):
    """
    given pymongo databaseand a regex object (or string) for geo_id
    return (pubmed_id, geo_id)
    """
    pm_tups = []
    for ds in db.datasets.find({ '$or' : [{'reference_series':geo_id} , {"geo_id" :geo_id }]}).limit(limit):
        if 'pubmed_id' in ds:
            pm_tups.append((ds['pubmed_id'], ds['geo_id']))
            pm_tups.append((ds['pubmed_id'], ds['reference_series']))
    return pm_tups

def getWords(pubmed_id, fields=["MeshHeading" , "AbstractText", "ArticleTitle"]):
    """
    given a pubmed id, return a list of words from the given fields
    """
    def findText(anode):
        if anode.nodeType == anode.TEXT_NODE:
            return anode.data
        elif anode.hasChildNodes():
            return ' '.join(map(findText, anode.childNodes))
        else:
            return ''

    handle = Entrez.efetch(db="pubmed", id=pubmed_id, retmode='xml')
    myfile = handle.read()
    doc = parseString(myfile)
    a = ["MeshHeading" , "AbstractText", "ArticleTitle"]
    myt = ' '.join( [' '.join(map( findText, doc.getElementsByTagName(tag))) for tag in a] )
    word_list = []
    for word in myt.split():
        clean_word = word.strip(r'.!?:;\'",)(%&').lower()
        if len(clean_word) > 1:
            word_list.append(clean_word)
    return word_list

def insertWords(db, geo_id, words):
    """
    given mongo db, geo_id and a list of words insert into word2geo collection
    """
    def f( word):
        return {'geo_id' : geo_id, 'word': word}
    try:
        db.word2geo.insert(map( f, words))
    except:
        print "error in " + geo_id
        print map( f, words)

if __name__ == "__main__":
    Entrez.email = "john.c.earls+entrez@gmail.com"

    connection = Connection('localhost', 27017)
    db = connection.geo
    for pm_id, geo_id in getPubmedIds(db, re.compile(r'GSE\d+')):
         insertWords(db, geo_id, getWords(pm_id))
            
            
        
    

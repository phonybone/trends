import sys, os, yaml, pymongo
from Mongoid import Mongoid

sys.path.append('/usr/lib64/python2.6/site-packages') # need this for Entrez
from Bio import Entrez
from xml.dom.minidom import parseString
from warn import *
from string_helpers import sanitized_list

class Pubmed(Mongoid):
    '''
    A class for storing a subset of information about Pubmed articles
    Record structure: pmid, tag, value
    EG pmid=1028384, tag="MeshHeading", value=["frogs", "purple", "helicopter", "Milan", ...]
    Because of this, there are (currently) 3 entries in the mongo db for each pubmed, one for each
    tag value; see self.text_tags
    '''
    
    db_name='geo'
    collection_name='pubmed'
    subdir='pubmeds'
    text_tags=["MeshHeading" , "AbstractText", "ArticleTitle"]
    indexes=[{'keys': 'pmid', 'options': {}},
             {'keys': [('pmid', pymongo.ASCENDING), ('tag', pymongo.ASCENDING)], 'options': {'unique':True}},
             ]

    def __init__(self, *args):
        assert len(args)==1
        try:
            self.pubmed_id=int(args[0])
        except Exception as e:
            warn("args[0]: %s; caught %s" % (args[0], e))

    @classmethod
    def __class_init__(self):
        Entrez.email=self._get_user_email()
        self.ensure_indexes()

    @classmethod
    def _get_user_email(self):
        if    'HOSTNAME' in os.environ: 
            hostname=os.environ['HOSTNAME']
        elif 'HOST' in os.environ:     
            hostname=os.environ['HOST']
        else: 
            hostname=os.system('hostname')
#        warn("hostname is %s" % (hostname))
        return '@'.join([os.environ['USER'], hostname])

    ########################################################################

    def path(self):
        ''' Return the path to the stored document (fetched from NCBI) '''
        return os.path.join(os.environ['TRENDS_HOME'], 'data', 'GEO', self.subdir, '%s.xml' % self.pubmed_id)

    ########################################################################

    def populate(self):
        cursor=self.mongo().find({'pubmed_id': self.pubmed_id})
        for record in cursor:
            warn("tag %s: %d words" % (record['tag'], len(record['words'])))
            setattr(self, record['tag'], record['words'])

        return self


    def remove(self, pubmed_id=None):
        if not pubmed_id:
            try: pubmed_id=self.pubmed_id
            except AttributeError as ae:
                raise Exception('no pubmed_id passed (%s)' % ae)

        self.mongo().remove({'pubmed_id':pubmed_id})

    def fetch(self):
        ''' Return Document object for this pubmed id, obtained from NCBI if necessary '''
        if os.access(self.path(), os.R_OK):
            warn("%d: already on disk" % ())
            f=open(self.path(), 'r')
            xml_doc=f.read()
            f.close()
        else: 
            warn("%d: fetching from pubmed" % (self.pubmed_id))
            xml_doc=Entrez.efetch(db="pubmed", id=self.pubmed_id, retmode='xml').read()
            f=open(self.path(), 'w')
            f.write(xml_doc+"\n")
            f.close()

        doc=parseString(xml_doc)
        return doc

    def store(self):
        ''' 
        Store all the text elements from the xml doc into the db.
        Record structure: pmid, tag, value
        EG pmid=1028384, tag='MeshHeading', value=['frogs', ... ]
        only accesses tags listed in self.text_tags (for now)
        '''
        doc=self.fetch()
        for tag_name in self.text_tags:
            elems=doc.getElementsByTagName(tag_name)
            for elem in elems:
                words=self._findText(elem, tag_name)
                self._add_words(tag_name, words)
        return self             # indent-fixer

    # recursive function to get all the words from a node:
    # returns a list of words
    def _findText(self, elem, tag_name):
        words=[]
        if elem.nodeType == elem.TEXT_NODE:
            words.extend(sanitized_list(elem.data))
            
        elif elem.hasChildNodes():
            for node in elem.childNodes:
                words.extend(self._findText(node, tag_name))
                
        return words




    def _add_words(self, tag_name, words):
        query={'pubmed_id': self.pubmed_id, 'tag':tag_name}
        record=self.mongo().find_one(query)
        if not record:
            record={'pubmed_id': self.pubmed_id, 'tag':tag_name, 'words':words}
        else:
            record['words'].extend(words)
        self.mongo().update(query, record, True) # True for upsert


Pubmed.__class_init__()

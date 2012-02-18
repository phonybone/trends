import unittest, sys, os

sys.path.append(os.path.join(os.environ['AUREA_HOME'], 'src'))
sys.path.append(os.path.join(os.environ['TRENDS_HOME'], 'pylib'))

from GEO.pubmed import Pubmed
from warn import *

class TestStore(unittest.TestCase):
    
    def setUp(self):
        pass
        
    def test_store(self):
        warn("\n")
        pmid=18297132
        pubmed=Pubmed(pmid)
        self.assertIsInstance(pubmed, Pubmed)
        self.assertEqual(pubmed.pubmed_id, pmid)

        pubmed.remove()
        pubmed.store()
        self.assertTrue(os.access(pubmed.path(), os.R_OK))
        cursor=Pubmed.mongo().find({'pubmed_id':pmid})
        self.assertEqual(cursor.count(), len(Pubmed.text_tags))
        
        tag2count={'MeshHeading':22,
                   'AbstractText':247,
                   'ArticleTitle':15}
        for record in cursor:
            tag=record['tag']
            self.assertEqual(len(record['words']), tag2count[tag])



suite = unittest.TestLoader().loadTestsFromTestCase(TestStore)
unittest.TextTestRunner(verbosity=2).run(suite)


        


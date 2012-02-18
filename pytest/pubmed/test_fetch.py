import unittest, sys, os

sys.path.append(os.path.join(os.environ['AUREA_HOME'], 'src'))
sys.path.append(os.path.join(os.environ['TRENDS_HOME'], 'pylib'))

from GEO.pubmed import Pubmed
from warn import *

class TestStore(unittest.TestCase):
    
    def setUp(self):
        pass
        
    def test_store(self):
        pmid=18297132
        pubmed=Pubmed(pmid)
        self.assertEqual(pubmed.pubmed_id, pmid)

        try: os.unlink(pubmed.path())
        except OSError: pass

        pubmed.fetch()
        self.assertTrue(os.access(pubmed.path(), os.R_OK))
        self.assertEqual(os.path.getsize(pubmed.path()), 17990)


suite = unittest.TestLoader().loadTestsFromTestCase(TestStore)
unittest.TextTestRunner(verbosity=2).run(suite)


        


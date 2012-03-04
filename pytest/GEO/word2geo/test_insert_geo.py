import unittest, sys, os

sys.path.append(os.path.join(os.environ['TRENDS_HOME'], 'pylib'))

from GEO.Series import Series
from GEO.word2geo import Word2Geo

from warn import *

class TestInsertGeo(unittest.TestCase):
    
    def setUp(self):
        pass
        
    def test_insert_GSE10072(self):
        series=Series('GSE10072').populate()
        Word2Geo.insert_geo(series)


suite = unittest.TestLoader().loadTestsFromTestCase(TestInsertGeo)
unittest.TextTestRunner(verbosity=2).run(suite)


        


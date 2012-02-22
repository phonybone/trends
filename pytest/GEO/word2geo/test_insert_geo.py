import unittest, sys, os

sys.path.append(os.path.join(os.environ['AUREA_HOME'], 'src'))
sys.path.append(os.path.join(os.environ['TRENDS_HOME'], 'pylib'))

from warn import *

class TestInsertGeo(unittest.TestCase):
    
    def setUp(self):
        pass
        
    def test_insert_geo(self):
        series=Series('GSE10072')
        Word2Geo.insert_geo(series)



suite = unittest.TestLoader().loadTestsFromTestCase(TestInsertGeo)
unittest.TextTestRunner(verbosity=2).run(suite)


        


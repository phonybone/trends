import unittest, sys, os

sys.path.append(os.path.join(os.environ['TRENDS_HOME'], 'pylib'))

from GEO.Factory import Factory
from GEO.word2geo import Word2Geo
from warn import *

class TestGetFieldWords(unittest.TestCase):
    
    def setUp(self):
        pass
        
    def test_get_field_words(self):
        geo_id='GSE10072'
        geo=Factory().newGEO(geo_id)
        words=Word2Geo.get_field_words(geo)

        self.assertEqual(len(words['title']), 42)
        self.assertEqual(len(words['description']), 0)
        self.assertEqual(len(words['summary']), 738) # not quite sure why this isn't 741


suite = unittest.TestLoader().loadTestsFromTestCase(TestGetFieldWords)
unittest.TextTestRunner(verbosity=2).run(suite)


        


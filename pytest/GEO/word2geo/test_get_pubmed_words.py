import unittest, sys, os, yaml

sys.path.append(os.path.join(os.environ['AUREA_HOME'], 'src'))
sys.path.append(os.path.join(os.environ['TRENDS_HOME'], 'pylib'))

from warn import *
from GEO.word2geo import Word2Geo
from GEO.Dataset import Dataset

class TestGetPubmedWords(unittest.TestCase):
    
    def setUp(self):
        warn("\n")
        
    def test_get_pubmed_words(self):
        dataset=Dataset('GDS987').populate()
        self.assertEqual(dataset.pubmed_id, str(15476476))
        words=Word2Geo.get_pubmed_words(dataset.pubmed_id)

        for tag, n_words in {"MeshHeading":43 , "AbstractText":206, "ArticleTitle":17}.items():
            self.assertIn(tag, words)
            self.assertIsInstance(words[tag], list)
            warn("words[%s] (%d): %s" % (tag, len(words[tag]), words[tag]))
            self.assertEqual(len(words[tag]), n_words)

    def test_get_field_words(self):
        dataset=Dataset('GDS987').populate()
        words=Word2Geo.get_field_words(dataset)
        expected={"description" : [u'analysis', u'of', u'kidneys', u'from', u'adult', u'renal', u'transplant', u'recipients', u'subjected', u'to', u'calcineurin', u'inhibitor-free', u'immunosuppression', u'using', u'sirolimus', u'patients', u'treated', u'with', u'sirolimus', u'have', u'a', u'lower', u'prevalence', u'of', u'chronic', u'allograft', u'nephropathy', u'compared', u'to', u'those', u'treated', u'with', u'cyclosporine', u'a', u'calcineurin', u'inhibitor'],
                  "title" : ['kidney', u'transplant', u'response', u'to', u'calcineurin', u'inhibitor-free', u'immunosuppression', u'using', u'sirolimus'],
                  "summary" : []}
        self.maxDiff=None
        self.assertEqual(words, expected)
        
    def test_insert_geo(self):
        dataset=Dataset('GDS987').populate()
        Word2Geo.insert_geo(dataset)
        
        w2gs=list(Word2Geo.mongo().find({'geo_id': dataset.geo_id}))

        self.assertEqual(len(w2gs), 175)



suite = unittest.TestLoader().loadTestsFromTestCase(TestGetPubmedWords)
unittest.TextTestRunner(verbosity=2).run(suite)


        


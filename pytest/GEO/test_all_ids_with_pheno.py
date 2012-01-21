import unittest, sys, os
sys.path.append(os.path.join(os.environ['TRENDS_HOME'], 'pylib'))

from warn import *
from GEO.Sample import Sample

class TestAllIdsWithPheno(unittest.TestCase):
    
    def setUp(self):
        pass
        
    def test_all_ids_with_pheno(self):
        phenos=[
            "normal",
            "adenocarcinoma",
            "squamous cell carcinoma",
            "asthma",
            "chronic obstructive pulmonary disease",
            "large cell lung carcinoma"
            ]

        for pheno in phenos:
            ids=Sample.all_ids_with_pheno(pheno)
            self.assertIsInstance(ids, list)
            warn("got %d '%s' samples" % (len(ids), pheno))
            self.assertTrue(len(ids) > 0)

            ids_with_data=[x for x in ids if os.access(Sample.data_path_of(geo_id=x), os.R_OK)]
            warn("got %d '%s' samples with data" % (len(ids_with_data), pheno))


suite = unittest.TestLoader().loadTestsFromTestCase(TestAllIdsWithPheno)
unittest.TextTestRunner(verbosity=2).run(suite)


        


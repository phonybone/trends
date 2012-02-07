import unittest, sys, os

sys.path.append(os.path.join(os.environ['AUREA_HOME'], 'src'))
sys.path.append(os.path.join(os.environ['TRENDS_HOME'], 'pylib'))

from warn import *
import GEO.Sample

class TestWithPheno(unittest.TestCase):
    
    def setUp(self):
        pass
        
    def test_with_phenos(self):
        for pheno in ["adenocarcinoma","normal","asthma","squamous cell carcinoma","chronic obstructive pulmonary disease","large cell lung carcinoma"]:
            samples=GEO.Sample.Sample.with_pheno(pheno)
            warn("%s: got %d samples" % (pheno, len(samples)))
            for sample in samples:
                self.assertEqual(sample.phenotype, pheno)
            





suite = unittest.TestLoader().loadTestsFromTestCase(TestWithPheno)
unittest.TextTestRunner(verbosity=2).run(suite)


        


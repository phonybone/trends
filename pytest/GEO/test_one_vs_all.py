import unittest, sys, os

sys.path.append(os.path.join(os.environ['AUREA_HOME'], 'src'))
sys.path.append(os.path.join(os.environ['TRENDS_HOME'], 'pylib'))

from warn import *
import GEO
Sample=GEO.Sample.Sample

class TestOneVsAll(unittest.TestCase):
    
    def setUp(self):
        pass
        
    def test_bad_id_type(self):
        self.assertRaises(ProgrammerGoof, Sample.all_ids_with_data, id_type='monkey')

    def test_all_ids_with_data(self):
        for id_type in ['probe', 'gene']:
            warn("calling Sample.all_ids_with_data(id_type='%s'...)" % id_type)
            all_samples=Sample.all_ids_with_data(id_type='probe')

            self.assertIsInstance(all_samples, list)
            self.assertIn('GSM32106', all_samples) # it's in both lists
            self.assertNotIn('GSM1', all_samples)

    def test_one_vs_all(self):
        sample_list=['GSM254625','GSM254626','GSM254627','GSM254628','GSM254629','GSM254630',
                     'GSM254631','GSM254632','GSM254633','GSM254634','GSM254635','GSM254636',
                     'GSM254637','GSM254638','GSM254639','GSM254640','GSM254641','GSM254642',                     
                     'GSM254643','GSM254644','GSM254645','GSM254646','GSM254647','GSM254648',
                     'GSM254649','GSM254650','GSM254651','GSM254652','GSM254653','GSM254654',
                     'GSM254655','GSM254656','GSM254657','GSM254658','GSM254659','GSM254660',
                     'GSM254661','GSM254662','GSM254663','GSM254664','GSM254665','GSM254666',
                     'GSM254667','GSM254668','GSM254669','GSM254670','GSM254671','GSM254672',
                     'GSM254673','GSM254674','GSM254675','GSM254676','GSM254677','GSM254678',
                     'GSM254679','GSM254680','GSM254681','GSM254682','GSM254683','GSM254684',
                     'GSM254685','GSM254686','GSM254687','GSM254688','GSM254689','GSM254690',
                     'GSM254691','GSM254692','GSM254693','GSM254694','GSM254695','GSM254696',
                     'GSM254697','GSM254698','GSM254699','GSM254700','GSM254701','GSM254702',
                     'GSM254703','GSM254704','GSM254705','GSM254706','GSM254707','GSM254708',
                     'GSM254709','GSM254710','GSM254711','GSM254712','GSM254713','GSM254714',
                     'GSM254715','GSM254716','GSM254717','GSM254718','GSM254719','GSM254720',
                     'GSM254721','GSM254722','GSM254723','GSM254724','GSM254725','GSM254726',
                     'GSM254727','GSM254728','GSM254729','GSM254730','GSM254731',
                     ]

        pheno_samples=['GSM254625', 'GSM254675','GSM254671','GSM254703','GSM254726','GSM254715']
        '''
        We want to pass back a 2D matrix with rows and columns labeled (somehow; could be hashes 
        that map label to row/col index).
        '''
        matrix=Sample.one_vs_all(pheno_samples='pheno', all_samples=sample_list)

suite = unittest.TestLoader().loadTestsFromTestCase(TestOneVsAll)
unittest.TextTestRunner(verbosity=2).run(suite)


        


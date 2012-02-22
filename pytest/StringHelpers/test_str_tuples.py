import unittest, sys, os

sys.path.append(os.path.join(os.environ['TRENDS_HOME'], 'pylib'))

from string_helpers import *
from warn import *

class TestStrTuples(unittest.TestCase):
    
    def setUp(self):
        pass
        
    def test_basic(self):
        s='this is a string with some stuff in it'
        n_words=len(s.split(' '))

        ts=str_windows(s,1)
        self.assertEqual(ts, ['this', 'is', 'a', 'string', 'with', 'some', 'stuff', 'in', 'it'])
        self.assertEqual(len(ts), n_words)

        ts=str_windows(s,2)
        self.assertEqual(ts, ['this is', 'is a', 'a string', 'string with', 'with some', 'some stuff', 'stuff in', 'in it'])
        self.assertEqual(len(ts), n_words-1)
        
        ts=str_windows(s,3)
        self.assertEqual(ts, ['this is a', 'is a string', 'a string with', 'string with some', 'with some stuff', 'some stuff in', 'stuff in it'])
        self.assertEqual(len(ts), n_words-2)

        ts=str_windows(s,n_words)
        self.assertEqual(ts, [s])
        self.assertEqual(len(ts), 1)
        

    def test_n_too_big(self):
        s='this is a string with some stuff in it'
        n_words=len(s.split(' '))
        warn("n_words is %d" % (n_words))
        self.assertEqual(str_windows(s,n_words+1), [])

    def test_bad_s(self):
        self.assertRaises(ValueError, str_windows, 3, 5)

    def test_bad_n(self):
        s='this is a string with some stuff in it'
        n_words=len(s.split(' '))
        self.assertRaises(AssertionError, str_windows, s,0)

            

suite = unittest.TestLoader().loadTestsFromTestCase(TestStrTuples)
unittest.TextTestRunner(verbosity=2).run(suite)


        


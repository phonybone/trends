import re
from warn import *

def sanitized_list(string, cleaner='[^_a-z\d]', separator_re='[-\s]+'):
    ''' 
    convert a string to a list of cleaned up words.
    cleaner: a regex s.t. all characters NOT matching the regexp will be removed.
    (So pass a negated range of characters you want to keep, generally of form [^ ... ]
    If all characters of a word (delimited by separator_re) are removed, the (empty)
    word is omitted from the list.
    '''
    words=[]
    for w in re.split(separator_re, string.lower()):
        cleaned=re.sub(cleaner, '', w) # remove anything that's not "nice"
        if re.search('\S', cleaned): # only retain if there's anything left
            words.append(cleaned)
        
    return words


def str_windows(string, n):
    '''
    Return a list of (sanitized) word-pairs (triplets, etc) from a single string.
    EG str_tuples('this string has a bunch of words', 2) returns:
    ['this string', 'string has', 'has a', 'a bunch', 'bunch of', 'of words']

    Note that this routine makes use of santized_list, above, so if you
    pass a string containing character that get removed, you  may get
    unexpected results.
    '''
    if type(string) != str and type(string) != unicode:
        raise ValueError('%s (%s): not a string' % (string, type(string)))

    l=sanitized_list(string)
    assert n>0

    answer=[]
    n_windows=len(l)-n+1
    for i in range(n_windows):
        answer.append(' '.join(l[i:i+n]))
    return answer


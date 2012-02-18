import re

def sanitized_list(s, cleaner='[^-_a-z\d]', separator_re='\s+'):
    ''' 
    convert a long string to a list of cleaned up words.
    cleaner: a regex s.t. all characters NOT matching the regexp will be removed.
    (So pass a negated range of characters you want to keep, generally of form [^ ... ]
    If all characters of a word (delimited by separator_re) are removed, the (empty)
    word is omitted from the list.
    '''
    words=[]
    for w in re.split(separator_re, s.lower()):
        cleaned=re.sub(cleaner, '', w) # remove anything that's not "nice"
#        print "%s -> %s" % (w, cleaned)
        if re.search('\S', cleaned): # only retain if there's anything left
            words.append(cleaned)
        
    return words

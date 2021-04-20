#!/cm/shared/apps/python3.5.2/bin/python3.5
import random
with open('/home/maison2/lid/pyz/w2020/project/olr2020_pretrain_model/exp/local/data/dict/Tibetan/Tibet-chars.txt.1', 'r') as chars:
    lower_alphabet = ['a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z']
    upper_alphabet = []
    tibet_alphabet = []
    tibet_map = {}
    marks = []
    for each in lower_alphabet:
        upper_alphabet.append(each.upper())
    for each in chars.readlines():
        tibet_alphabet.append(each.replace('\n', ''))
    for each in tibet_alphabet:
        index1 = random.randint(0, 25)
        index2 = random.randint(0, 25)
        lower = lower_alphabet[index1]
        upper = upper_alphabet[index2]
        mark = lower + upper
        while mark in marks:
            index1 = random.randint(0, 25)
            index2 = random.randint(0, 25)
            lower = lower_alphabet[index1]
            upper = upper_alphabet[index2]
            mark = lower + upper
        marks.append(mark)
        tibet_map[each] = mark
    for alpha, mark in tibet_map.items():
        print(alpha + '\t' + mark)    

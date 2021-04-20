#!/cm/shared/apps/python3.5.2/bin/python3.5

tibet_maps = {}
lexicon_list = []
lexicon_map = {}
with open('/home/maison2/lid/pyz/w2020/project/olr2020_pretrain_model/exp/local/data/dict/Tibetan/tibet-maps.txt', 'r') as maps:
    for each in maps.readlines():
        tibet_maps[each.split('\t')[0]] = each.split('\t')[1].replace('\n', '')
with open('/home/maison2/lid/pyz/w2020/project/olr2020_pretrain_model/exp/local/data/dict/Tibetan/lexicon.txt', 'r') as lexicon:
    for each in lexicon.readlines():
        word  = each.split('\t')[0].replace(' ', '')
        lexicon_list.append(word)
        phones = []
        for each in list(word):
            phones.append(tibet_maps[each] + '_TBT')
        print(word + '\t' + ' '.join(phones))

with open('/home/maison2/lid/pyz/w2020/project/olr2020_pretrain_model/exp/local/data/Tibet/train/oov-count.txt', 'r') as oovs:
    oov = []
    for each in oovs.readlines():
        oov.append(each.split('\t')[0])
    for word in oov:
        phones = []
        word = word.replace('\n', '')
        for character in word:
            if character not in tibet_maps:
                break
            else:
                phones.append(tibet_maps[character] + '_TBT')
#        print(word + '\t' + ' '.join(phones))
        

#!/cm/shared/apps/python3.5.2/bin/python3.5

import jieba
def preprocess(text, dict_dir):
    text_result = ""
#    jieba.load_userdict('/home/maison2/lid/pyz/w2020/project/olr2020_pretrain_model/exp/local/data/JAP/japanese_words.dict')
    fenci = jieba.cut(text)
    for word in fenci:
        text_result=text_result + " " + word
    return text

with open('/home/maison2/lid/pyz/w2020/project/olr2020_pretrain_model/exp/local/data/JAP/japanese_final.txt', 'w', encoding='utf-8') as final:
    with open('/home/maison2/lid/pyz/w2020/project/olr2020_pretrain_model/exp/local/data/JAP/japanese_text.txt', 'r', encoding='utf-8') as jap:
#        jieba.set_dictionary('/home/maison2/lid/pyz/w2020/project/olr2020_pretrain_model/exp/local/data/JAP/japanese_words.dict')
        text = jap.readline()
#        for line in text:
        results = preprocess(text, '/home/maison2/lid/pyz/w2020/project/olr2020_pretrain_model/exp/local/data/JAP/japanese_words.dict')
        final.write(results)

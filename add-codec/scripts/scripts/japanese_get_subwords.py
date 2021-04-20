#!/cm/shared/apps/python3.5.2/bin/python3.5
# encoding=utf8

import sys  
  
# reload(sys)  
# sys.setdefaultencoding('utf8') 

with open('/home/maison2/lid/pyz/w2020/project/olr2020_pretrain_model/exp/local/data/JAP/test', 'r', encoding='utf-8') as text:
    with open('/home/maison2/lid/pyz/w2020/project/olr2020_pretrain_model/exp/local/data/JAP/text.origin.1', 'r', encoding='utf-8') as utt2text:
        with open('/home/maison2/lid/pyz/w2020/project/olr2020_pretrain_model/exp/local/data/JAP/final', 'w', encoding='utf-8') as final:
            u_t={}
            all_text = utt2text.readlines()
            for line in all_text:
#                print(line.split(' '))
                u, t = line.split(' ')[0], line.split(' ')[0]
                u_t[u] = t
print(u_t['ja-jp-0007-0000'])

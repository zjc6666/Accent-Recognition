with open('/home/maison2/lid/pyz/w2020/project/olr2020_pretrain_model/exp/local/data/Kazak/dev/text','r',encoding='utf-16 le') as f:
    content = f.read()

with open('/home/maison2/lid/pyz/w2020/project/olr2020_pretrain_model/exp/local/data/Kazak/dev/text.origin',"w",encoding='utf-8') as f1:
            #f1.write(bytes.decode(content))
    f1.write(content)
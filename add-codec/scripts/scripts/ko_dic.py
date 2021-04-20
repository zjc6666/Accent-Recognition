#!/cm/shared/apps/python3.5.2/bin/python3.5

def combine(list1, list2):
    combined = []
    for phone1 in list1:
        for phone2 in list2:
            combined.append(phone1 + ' ' + phone2)
    return combined

with open('/home/maison2/lid/pyz/w2020/project/olr2020_pretrain_model/exp/local/data/KRN/korean-character-lexicon.txt', 'r', encoding='utf-8') as pairs:
    with open('/home/maison2/lid/pyz/w2020/project/olr2020_pretrain_model/exp/local/data/KRN/oov-transfer-dict.txt', 'r', encoding='utf-8') as words:
        pair = pairs.readlines()
        word = words.readlines()
        w = []
        p = {}
        for each in word:
            w.append(each.split('\t')[0])
        for each in pair:
            char, phone = each.split('\t')[0], each.split('\t')[1].replace('\n', '')
            p[phone] = char
#        print(p)
#        print(len(p))
        new_phone = []
        for each in w:
            w_phone = []
            for char_dict in each:
                char_phone = []
                for phone, char in p.items():
                    if char_dict == char:
                        char_phone.append(phone)
                w_phone.append(char_phone)
            new_phone.append(w_phone)
word_dict={}
word_dict_new={}
for i in range(len(new_phone)):
    word_dict[w[i]] = new_phone[i]
for word, phones in word_dict.items():
    if [] in phones:
        pass
    else:
        if len(phones) < 2:
            phone = phones[0]
            for item in phone:
                print(word, item)
        elif len(phones) == 2:
            combined = combine(phones[0], phones[1])
            for item in combined:
                print(word, item)
        elif len(phones) > 2:
            combined = combine(phones[0], phones[1])
            for i in range(2,len(phones)):
                combined = combine(combined, phones[i])
            for item in combined:
                print(word, item)
                


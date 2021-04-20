#!/bin/bash

# prepare dict

sdata=/home/maison2/lid/w2020/project/olr2020_pretrain_model/data/local/dict
tdata=./olr2020/data/local/data/dict

[ -d $tdata ] || mkdir -p $tdata

# prepare cantonese dict
dir=$tdata/canton
[ -d $dir ] || mkdir -p $dir

dos2unix <  $sdata/ct-cn.lex  | ./olr2020/scripts/normalize-cantonese-lex.pl | grep -Pv '<s>|</s>|<|>' | sort -u |     cat <(echo -e "<noise>\t<sss>\n<unk>\t<oov>\n<v-noise>\t<vns>") - |./olr2020/scripts/add-language-id.pl CNT > $dir/lexicon.txt 
grep -Pv '<|>' $dir/lexicon.txt | perl -ane 'use utf8; use open qw(:std :utf8); chomp ; @A = split(/\s+/); shift @A;  for($i = 0; $i < scalar @A; $i ++) { print "$A[$i]\n";  }' | sort -u > $dir/nonsilence_phones.txt
grep -P '<|>' $dir/lexicon.txt | perl -ane 'use utf8; use open qw(:std :utf8); chomp; @A = split(/\s+/); shift @A; print "$A[0] "; ' | cat - <(echo "SIL") > $dir/silence_phones.txt
echo "SIL" > $dir/optional_silence.txt
echo -n > $dir/extra_questions.txt  
./utils/validate_dict_dir.pl $dir

# check oov status

sdir=/home/maison2/lid/w2020/project/olr2020_pretrain_model/data/train/ct-cn
tdir=olr2020/data/local/data/CNT
[ -d $tdir ] || mkdir -p $tdir
cp -rL $sdir/* $tdir/
[ -f $tdir/text.origin ] || cp $tdir/text $tdir/text.origin

# do character segmentation

cat  ./olr2020/data/local/data/CNT/text.origin |  ./source-scripts/egs/mandarin/update-april-03-2017-with-pruned-lexicon/segment-chinese-text.py --do-character-segmentation > $tdir/text.char

cat $tdir/text.char | ./nsc-part3/scripts/show-oov-with-count.pl  --from=2 $dir/lexicon.txt  > $tdir/oov-count.txt

cat $tdir/oov-count.txt | ./nsc-part3/scripts/make_transfer_dict.pl  > $tdir/oov-transfer-dict.txt
 [ -f $tdir/oov-transfer-dict-edit.txt ] || cp $tdir/oov-transfer-dict.txt $tdir/oov-transfer-dict-edit.txt

cat $tdir/text.char | ./source-scripts/w2020/projects/ubs/transfer-utterance-with-dict-ignore-oov.pl $tdir/oov-transfer-dict-edit.txt > $tdir/text

cat $tdir/text.char | ./source-scripts/w2020/projects/ubs/transfer-utterance-with-dict-ignore-oov.pl $tdir/oov-transfer-dict-edit.txt > $tdir/text
utils/fix_data_dir.sh $tdir
utils/data/get_utt2dur.sh --cmd "slurm.pl --exclude=node0[1-4]" --nj 10 $tdir
cat $tdir/utt2dur | perl -ane 'use utf8; use open qw(:std :utf8); chomp; m/(\S+)\s+(.*)/g or next; print "$1 $1 0.0 $2\n"; ' > $tdir/segments
kdata=./olr2020/data/CNT
utils/copy_data_dir.sh $tdir $kdata

# now we are preparing Chinese data

sdict=/home/maison2/lid/w2020/project/olr2020_pretrain_model/data/local/dict/zh-cn.lex
dict=./olr2020/data/local/data/dict/CHN
mandarin_if_dict=./mandarin-syllable-transcript/if-syl-dict-update-20200114.txt
[ -d $dict ] || mkdir -p $dict
cat $sdict | perl -ane 'use utf8; use open qw(:std :utf8); chomp; s/\(.*\)//g; print "$_\n";' | ./olr2020/scripts/transfer-utterance-with-dict-ignore-oov.pl --print-warning  $mandarin_if_dict | ./olr2020/scripts/add-language-id.pl CHN | sort -u | cat <(echo -e "<noise>\t<sss>\n<unk>\t<oov>\n<v-noise>\t<vns>") - > $dict/lexicon.txt

grep -Pv '<|>' $dict/lexicon.txt | perl -ane 'use utf8; use open qw(:std :utf8); chomp ; @A = split(/\s+/); shift @A;  for($i = 0; $i < scalar @A; $i ++) { print "$A[$i]\n";  }' | sort -u > $dict/nonsilence_phones.txt
grep -P '<|>' $dict/lexicon.txt | perl -ane 'use utf8; use open qw(:std :utf8); chomp; @A = split(/\s+/); shift @A; print "$A[0] "; ' | cat - <(echo "SIL") > $dict/silence_phones.txt
echo "SIL" > $dict/optional_silence.txt
echo -n > $dict/extra_questions.txt  
./utils/validate_dict_dir.pl $dict

# now, we are re-organizing 
sdata=/home/maison2/lid/w2020/project/olr2020_pretrain_model/data/train/zh-cn
data=./olr2020/data/local/data/CHN
[ -d $data ] || mkdir -p $data
utils/data/copy_data_dir.sh $sdata $data
cat $data/text | ./source-scripts/egs/mandarin/update-april-03-2017-with-pruned-lexicon/segment-chinese-text.py --do-character-segmentation > $data/text.origin
cat $data/text.origin | ./nsc-part3/scripts/show-oov-with-count.pl  --from=2 $dict/lexicon.txt  > $data/oov-count.txt
cat $data/oov-count.txt | ./nsc-part3/scripts/make_transfer_dict.pl  > $data/oov-transfer-dict.txt
 [ -f $data/oov-transfer-dict-edit.txt ] || cp $data/oov-transfer-dict.txt $data/oov-transfer-dict-edit.txt
cat $data/text.origin | ./source-scripts/w2020/projects/ubs/transfer-utterance-with-dict-ignore-oov.pl $data/oov-transfer-dict-edit.txt > $data/text
utils/fix_data_dir.sh $data
utils/data/get_utt2dur.sh --cmd "slurm.pl --quiet --exclude=node0[1-4]" --nj 10 $data
cat $data/utt2dur | perl -ane 'use utf8; use open qw(:std :utf8); chomp; m/(\S+)\s+(.*)/g or next; print "$1 $1 0.0 $2\n"; ' > $data/segments
kdata=./olr2020/data/CHN
utils/copy_data_dir.sh $data $kdata

# 
./olr2020/scripts/compute_output.sh --nj 18  --output-name output-xent  --online-ivector-dir  /home/maison2/lid/pyz/w2020/project/olr2020_pretrain_model/exp_asr/combine1/ivector-train \
/home/maison2/lid/pyz/w2020/project/olr2020_pretrain_model/exp_asr/combine1/data/train_sperturb/mfcc-hires \
/home/maison2/lid/pyz/w2020/project/olr2020_pretrain_model/exp_asr/layer_9_spec_0.2_0.2_leaves_20000/tdnnf \
./
model_dir=/home/maison2/lid/pyz/w2020/project/olr2020_pretrain_model/exp_asr/layer_9_spec_0.2_0.2_leaves_20000/tdnnf
 "nnet3-copy '--edits-config=echo remove-output-nodes name=output; echo rename-node old-name=output-xent new-name=output|' $model_dir/final.mdl -|"

#  nnet3-am-info /home/maison2/lid/pyz/w2020/project/olr2020_pretrain_model/exp_asr/layer_9_spec_0.2_0.2_leaves_20000/tdnnf/final.mdl


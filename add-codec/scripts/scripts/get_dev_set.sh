#!/bin/bash

for set in CHN CNT IDN JAP KRN RUS VTN; do
    dir=/home/maison2/lid/pyz/w2020/project/olr2020_pretrain_model/exp/data/$set/utt2spk
    cat $dir | awk 'BEGIN{srand()} {print rand()"\t"$0}' | sort -nk 1 | head -n 150 | awk -F "\t" '{print $2}' > $dir.dev || exit 1;
    cat $dir.dev | awk 'NR==FNR{a[$0];next} !($0 in a)' - $dir  >> $dir.train || exit 1;
    for sub in dev train; do
	target=/home/maison2/lid/pyz/w2020/project/olr2020_pretrain_model/exp/data/$set/$sub
	[ -d $target ] || mkdir -p $target
	utils/subset_data_dir.sh --utt-list $dir.$sub /home/maison2/lid/pyz/w2020/project/olr2020_pretrain_model/exp/data/$set $target
    done
done

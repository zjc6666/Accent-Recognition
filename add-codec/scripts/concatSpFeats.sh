#!/bin/bash

# Zhang Haobo
# July 2, 2020

nj=30
cmd="slurm.pl --quiet"
feat_type="mfcc"
fname="train"

. parse_options.sh
. path.sh

no_aug=$1
srcdir=$2
tardir=$3
featsdir=$tardir/data

echo "$0 $@"

log=$featsdir/log
[ -e $tardir ] && rm -rf $tardir
mkdir -p $tardir
mkdir -p $log

cp ${no_aug}/{wav.scp,utt2spk,spk2utt,reco2dur,utt2dur,utt2lang} $tardir

split_scps=""
for n in $(seq $nj); do
    split_scps="$split_scps $log/wav_concat_${fname}.${n}.scp"
done

utils/split_scp.pl $no_aug/wav.scp $split_scps || exit 1;

$cmd JOB=1:$nj $log/concat_${feat_type}_$fname.JOB.log \
    awk 'NR==FNR{a[$1]=$2}NR>FNR{
        printf $1" ";system("concat-feats --binary=false "a[$1"-sp0.9"]" "a[$1]" "a[$1"-sp1.1"]" - 2>/dev/null");
    }' $srcdir/feats.scp $log/wav_concat_${fname}.JOB.scp \| \
    copy-feats --compress=true ark:- \
    ark,scp:$featsdir/concat_${feat_type}_$fname.JOB.ark,$featsdir/concat_${feat_type}_$fname.JOB.scp || exit 1;

for n in $(seq $nj); do
  cat $featsdir/concat_${feat_type}_$fname.$n.scp || exit 1;
done > $tardir/feats.scp || exit 1
utils/fix_data_dir.sh $tardir
echo "Succeeded concatenating speed-perturb-features from ${srcdir}"
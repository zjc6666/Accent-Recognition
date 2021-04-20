#!/bin/bash
#####################
#  
#
#
#####################
nj=10
steps=1,2
# cmd="slurm.pl --quiet --exclude=node0[3-9]"
# train_cmd="slurm.pl --quiet --exclude=node0[3-9]"
cmd="run.pl"
###------------------------------------------------

# end option

echo 
echo "$0 $@"
echo

set -e

. path.sh

. parse_options.sh || exit 1

steps=$(echo $steps | perl -e '$steps=<STDIN>;  $has_format = 0;
  if($steps =~ m:(\d+)\-$:g){$start = $1; $end = $start + 10; $has_format ++;}
        elsif($steps =~ m:(\d+)\-(\d+):g) { $start = $1; $end = $2; if($start == $end){}
        elsif($start < $end){ $end = $2 +1;}else{die;} $has_format ++; }
      if($has_format > 0){$steps=$start;  for($i=$start+1; $i < $end; $i++){$steps .=":$i"; }}
      print $steps;' 2>/dev/null)  || exit 1

if [ ! -z "$steps" ]; then
  for x in $(echo $steps|sed 's/[,:]/ /g'); do
  index=$(printf "%02d" $x);
  declare step$index=1
  done
fi
source_dir=/home/maison2/lid/zjc/w2021/add-codecs
des_dir=/home/maison2/lid/zjc/w2021/add-codecs

sdata=$source_dir/librispeech960
data_8k=$source_dir/librispeech960_8k
data_codec=$source_dir/data/librispeech960_codec

sample_rate=8000
codec_set="train"
# down sample

if [ ! -z $step01 ]; then
  echo -e "\n ##LOG [step 1] down-sample to 8k data start @ `date`\n"
  for x in librispeech960 test;do
    utils/data/copy_data_dir.sh $source_dir/$x $source_dir/${x}_8k
    utils/data/resample_data_dir.sh $sample_rate $source_dir/${x}_8k
  done
  echo -e "\n ##LOG [step 1] down-sample to 8k data ended @ `date`\n"
fi

# codec

if [ ! -z $step02 ]; then
    for x in librispeech960;do
        utils/data/get_utt2dur.sh $source_dir/$x
        data_8k=$source_dir/${x}_8k
        data_codec=$des_dir/${x}_codec
        echo -e "\n ##LOG [step 2] codec data start @ `date`\n"
        codec_list=./codec-list_full.txt
        ./scripts/copy-data-by-adding-codec.sh  --cmd "run.pl"  --steps 1,2,3 $data_8k $codec_list $data_codec
        cp $data_codec/tmp/{utt2dur,text,spk2utt,utt2spk} $data_codec
        echo -e "\n ## LOG $x add-codecs done "
   done
   echo -e "\n ##LOG [step 2] codec data ended @ `date`\n"
fi



#!/bin/bash

# Copyright 2017 Johns Hopkins University (Shinji Watanabe)
#  Apache 2.0  (http://www.apache.org/licenses/LICENSE-2.0)

. ./path.sh || exit 1;
. ./cmd.sh || exit 1;


# cuda_cmd="slurm.pl --quiet"
# decode_cmd="slurm.pl --quiet"
cmd="run.pl"
# general configuration
backend=pytorch
steps=1
ngpu=1         # number of gpus ("0" uses cpu, otherwise use gpu)
nj=20
debugmode=1
dumpdir=dump   # directory to dump full features
N=0            # number of minibatches to be used (mainly for debugging). "0" uses all minibatches.
verbose=0      # verbose option
resume=        # Resume the training from snapshot
log=100
vocab_size=2000
bpemode=bpe
# feature configuration
do_delta=false

train_track1_config=conf/e2e_asr_transformer_only_accent.yaml
decode_config=conf/espnet_decode.yaml
preprocess_config=conf/espnet_specaug.yaml

# rnnlm related
lm_resume=         # specify a snapshot file to resume LM training
lmtag=0             # tag for managing LMs

# decoding parameter
recog_model=model.acc.best # set a model to be used for decoding: 'model.acc.best' or 'model.loss.best'
n_average=5

# others
accum_grad=2
n_iter_processes=2
lsm_weight=0.0
epochs=30
elayers=6
batch_size=32

# exp tag
tag="base" # tag for managing experiments.

# Set bash to 'debug' mode, it will exit on :
# -e 'error', -u 'undefined variable', -o ... 'error in pipeline', -x 'print commands',
set -e
# set -u
set -o pipefail

. utils/parse_options.sh || exit 1;

steps=$(echo $steps | perl -e '$steps=<STDIN>;  $has_format = 0;
  if($steps =~ m:(\d+)\-$:g){$start = $1; $end = $start + 10; $has_format ++;}
        elsif($steps =~ m:(\d+)\-(\d+):g) { $start = $1; $end = $2; if($start == $end){}
        elsif($start < $end){ $end = $2 +1;}else{die;} $has_format ++; }
      if($has_format > 0){$steps=$start;  for($i=$start+1; $i < $end; $i++){$steps .=":$i"; }}
      print $steps;' 2>/dev/null)  || exit 1

if [ ! -z "$steps" ]; then
#  echo $steps
  for x in $(echo $steps|sed 's/[,:]/ /g'); do
     index=$(printf "%02d" $x);
    # echo $index
     declare step$index=1
  done
fi

data=$1 # 
exp=$2 # 
train_set="train"
recog_set="cv_all test"
valid_set="valid"


if [ ! -z $step01 ]; then
   echo "step01 extracting filter-bank features and cmvn"
   for i in $recog_set $valid_set $train_set;do
      utils/fix_data_dir.sh $data/$i
      steps/make_fbank_pitch.sh --cmd "$cmd" --nj $nj --write_utt2num_frames true \
          $data/$i $data/$i/feats/log $data/$i/feats/ark
      utils/fix_data_dir.sh $data/$i
   done

   compute-cmvn-stats scp:$data/${train_set}/feats.scp $data/${train_set}/cmvn.ark
   echo "step01 Extracting filter-bank features and cmvn Done"
fi

if [ ! -z $step02 ]; then
   echo "step01 02 dump features :E2E"

   for x in ${train_set} ;do
       dump.sh --cmd "$cmd" --nj $nj  --do_delta false \
          $data/$x/feats.scp $data/${train_set}/cmvn.ark $data/$x/dump/log $data/$x/dump 
   done

   for x in ${valid_set} $recog_set;do 
       dump.sh --cmd "$cmd" --nj $nj  --do_delta false \
          $data/$x/feats.scp $data/${train_set}/cmvn.ark $data/$x/dump_${train_set}/log $data/$x/dump_${train_set}
   done
   echo "step02 dump features for track2:E2E Done"   
fi

dict=$data/lang/accent.dict
### prepare for accent recogniton json file
if [ ! -z $step03 ]; then
    echo "stage 03: Make Json Labels"
    # make json labels
    local/tools/data2json.sh --nj $nj --cmd "${cmd}" --feat $data/${train_set}/dump/feats.scp  \
       --text $data/$train_set/utt2accent --oov 8 $data/$train_set ${dict} > ${data}/${train_set}/${train_set}_accent.json

    for x in $recog_set $valid_set;do 
       local/tools/data2json.sh --nj 10 --cmd "${cmd}" --feat $data/$x/dump_${train_set}/feats.scp \
           --text $data/$x/utt2accent --oov 8 $data/$x ${dict} > ${data}/$x/${train_set}_accent.json
    done
    echo "stage 03: Make Json Labels Done"
fi

epochs=30
if [ ! -z $step04 ]; then
    train_set=train
    elayers=3
    expname=${train_set}_${elayers}_layers_${backend}
    expdir=$exp/${expname}
    epoch_stage=0
    mkdir -p ${expdir}
    echo "stage 04: Network Training"
    ngpu=1
    if  [ ${epoch_stage} -gt 0 ]; then
        echo "stage 04: Resume network from epoch ${epoch_stage}"
        resume=${exp}/${expname}/results/snapshot.ep.${epoch_stage}
    fi
    train_track1_config=conf/e2e_asr_transformer_only_accent.yaml
    ## attention network, if you want to use attention to replace std+mean layer, you can cancel the comment
    # train_track1_config=conf/e2e_asr_transformer_only_accent_with_attention.yaml
    ${cuda_cmd} --gpu ${ngpu} ${expdir}/train.log \
        asr_train.py \
        --config ${train_track1_config} \
        --preprocess-conf ${preprocess_config} \
        --ngpu ${ngpu} \
        --backend ${backend} \
        --outdir ${expdir}/results \
        --debugmode ${debugmode} \
        --debugdir ${expdir} \
        --minibatches ${N} \
        --verbose ${verbose} \
        --resume ${resume} \
        --report-interval-iters ${log} \
        --accum-grad ${accum_grad} \
        --n-iter-processes ${n_iter_processes} \
        --elayers ${elayers} \
        --lsm-weight ${lsm_weight} \
        --epochs ${epochs} \
        --batch-size ${batch_size} \
        --dict ${dict} \
        --num-save-ctc 0 \
        --train-json $data/${train_set}/${train_set}_accent.json \
        --valid-json $data/${valid_set}/${train_set}_accent.json
fi

# pretrained asr model, if you want to use asr initialization the accent recognition encoder, plase set the "pretrained_model" variable to you own path
pretrained_model=/home/maison2/lid/zjc/w2020/AESRC2020/result/track2-accent-160/train_12enc_6dec_pytorch/results/model.val5.avg.best
if [ ! -z $step05 ]; then
    train_set=train
    elayers=12
    expname=${train_set}_${elayers}_layers_init_libri_${backend}
    expdir=$exp/${expname}
    epoch_stage=0
    mkdir -p ${expdir}
    echo "stage 05: Network Training"
    ngpu=1
    if  [ ${epoch_stage} -gt 0 ]; then
        echo "stage 05: Resume network from epoch ${epoch_stage}"
        resume=${exp}/${expname}/results/snapshot.ep.${epoch_stage}
    fi
    train_track1_config=conf/e2e_asr_transformer_only_accent.yaml
    ## attention network, if you want to use attention to replace std+mean layer, you can cancel the comment
    # train_track1_config=conf/e2e_asr_transformer_only_accent_with_attention.yaml
    ${cuda_cmd} --gpu ${ngpu} ${expdir}/train.log \
        asr_train.py \
        --config ${train_track1_config} \
        --preprocess-conf ${preprocess_config} \
        --ngpu ${ngpu} \
        --backend ${backend} \
        --outdir ${expdir}/results \
        --debugmode ${debugmode} \
        --debugdir ${expdir} \
        --minibatches ${N} \
        --verbose ${verbose} \
        --resume ${resume} \
        --report-interval-iters ${log} \
        --accum-grad ${accum_grad} \
        --n-iter-processes ${n_iter_processes} \
        --elayers ${elayers} \
        --lsm-weight ${lsm_weight} \
        --epochs ${epochs} \
        --batch-size ${batch_size} \
        --dict ${dict} \
        --num-save-ctc 0 \
        --train-json $data/${train_set}/${train_set}_accent.json \
        --valid-json $data/${valid_set}/${train_set}_accent.json \
        ${pretrained_model:+--pretrained-model $pretrained_model}

fi
if [ ! -z $step06 ]; then
    echo "stage 06: Decoding"
    nj=100
    for expname in train_3_layers_init_accent_pytorch;do
    expdir=$exp/$expname
    for recog_set in test cv_all;do
    use_valbest_average=true
    if [[ $(get_yaml.py ${train_track1_config} model-module) = *transformer* ]]; then
        # Average accent recognition models
        if ${use_valbest_average}; then
            [ -f ${expdir}/results/model.val5.avg.best ] && rm ${expdir}/results/model.val5.avg.best
            recog_model=model.val${n_average}.avg.best
            opt="--log ${expdir}/results/log"
        else
            [ -f ${expdir}/results/model.last5.avg.best ] && rm ${expdir}/results/model.last5.avg.best
            recog_model=model.last${n_average}.avg.best
            opt="--log"
        fi
        # recog_model=model.acc.best
        echo "$recog_model"
        average_checkpoints.py \
            ${opt} \
            --backend ${backend} \
            --snapshots ${expdir}/results/snapshot.ep.* \
            --out ${expdir}/results/${recog_model} \
            --num ${n_average}
    fi
    decode_dir=decode_${recog_set}
    # split data
    dev_root=$data/${recog_set}
    splitjson.py --parts ${nj} ${dev_root}/${train_set}_accent.json
    #### use CPU for decoding
    ngpu=0

    ${decode_cmd} JOB=1:${nj} ${expdir}/${decode_dir}/log/decode.JOB.log \
        asr_recog.py \
        --ngpu ${ngpu} \
        --backend ${backend} \
        --batchsize 0 \
        --recog-json ${dev_root}/split${nj}utt/${train_set}_accent.JOB.json \
        --result-label ${expdir}/${decode_dir}/${train_set}_accent.JOB.json \
        --model ${expdir}/results/${recog_model} 
        
    concatjson.py ${expdir}/${decode_dir}/${train_set}_accent.*.json >  ${expdir}/${decode_dir}/${train_set}_accent.json
    python local/tools/parse_track1_jsons.py  ${expdir}/${decode_dir}/${train_set}_accent.json ${expdir}/${decode_dir}/result.txt
    python local/tools/parse_track1_jsons.py  ${expdir}/${decode_dir}/${train_set}_accent.json ${expdir}/${decode_dir}/result.txt > ${expdir}/${decode_dir}/acc.txt
    done
    done
    echo "stage06 Decoding finished"
fi


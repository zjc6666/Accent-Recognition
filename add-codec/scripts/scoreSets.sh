#!/bin/bash

# ---------------------------------------Scoring-----------------------------------------
# -------------------------------Params Setting------------------------------------
eval=false # if true, will just generate the score rather than compute metric
extra_name= # it could be used to mark a trainset in score name
trainset= # for convenience with using default config. if NULL, will be set by enrollset

# Process could consist of "lda" "whiten" "norm" "mean" and "submean" now. 
enroll_process="mean-lda-submean-whiten-norm" # this process could have "mean" process for multi-utterance enroll.
test_process="lda-submean-whiten-norm" # this process should not contain "mean" because the testset should be kept in all utterances.

lda=false # if false, forcely ignore lda process
clda=10
lda_process="norm-trainlda"
lda_data_config="train[train dev]"  # if NULL, will be set "$enrollset[$enrollset $testset]"

submean=false
submean_process="lda-getmean" # getmean means computing the global mean vector from a dataset
submean_data_config="train[train dev]" # if NULL, will be set "$enrollset[$enrollset $testset]"

whiten=false # if false, forcely ignore whiten process
whiten_process="lda-submean-trainwhiten" # trainwhiten means train a ZCA whitening mat and trainpcawhiten means PCA
whiten_data_config="train[train dev]" # if NULL, will be set "$enrollset[$enrollset $testset]"

#####################

score="cosine"  # cosine | plda | aplda | svm | gmm | lr #
metric="eer-Cavg" # eer | Cavg #

#####################

# SVM #
curve=rbf
Cvalue=0.1 
##svm_trainset is just the enrollset but has its own process
svm_process="lda-submean-whiten-norm" # this process should not contain "mean" for too few training data of every speaker (only one vector).

# GMM #
nj=20
mmi=true # for mmi 
init_mmi=true # for mmi
tau=400 # for mmi  
weight_tau=10 # for mmi 
smooth_tau=0 # for mmi
E=2 # for mmi
cnum=64 # num of Gaussions
num_iters_init=20
num_iters=4 # for every GMM
num_gselect=30 # Number of Gaussian-selection indices to use while training the model.
num_frames=500000 # for inition
num_frames_den=500000 # for mmi
min_gaussian_weight=0.0001
adapt=false # if true and mmi=false, use adapt-gmm
##gmm_trainset is just the enrollset but has its own process
gmm_process="norm" # this process should not contain "mean" for too few training data of every speaker (only one vector).

# Logistic Regression #
max_steps=20
mix_up=0
apply_log=true
scale= # for example: "[ 0.6 0.4]" for two classes
lr_process="lda-submean-whiten-norm" # this process should not contain "mean" for too few training data of every speaker (only one vector).

# plda #
plda_smoothing=0.0 # work for plda or adapt-plda
plda_trainset="train" # should be one set only
plda_process="lda-submean-whiten-norm-trainplda"

# adapt-plda #
aplda_smoothing=0.0
within_covar_scale=0.70
between_covar_scale=0.30
mean_diff_scale=1
aplda_trainset="train" # should be one set only
aplda_process="lda-submean-whiten-norm-trainaplda"

#####################
# clear existent generated file or not #
force_clear= # if NULL, the follows could be set up separately
process_force_clear=true
trials_force_clear=true
score_force_clear=true


# source fuctions #
################################################################################
. path.sh
. subtools/parse_options.sh
. subtools/score/process.sh
. subtools/score/score.sh
datadir=data
expdir=exp
# ------------------------------Do Scoring for task1----------------------------
if true; then
    vectordir=$expdir/kaldi_xvector/embedding1
    #enrollset=task1_dev_enroll
    enrollset=task2_enroll
    ivec_enrollset=$enrollset
    #testset=task1_dev
    testset=task2_dev
    ivec_testset=$testset
    lda=true
    clda=100
    submean=true
    score="lr-svm"
    metric="eer-Cavg"
    # check and generate config #
    # if [[ $stage -le 0 && 0 -le $endstage ]];then
        check "$enroll_process" "lda submean whiten norm mean" enroll_process
        check "$test_process" "lda submean whiten norm" test_process
        check "$lda_process" "submean whiten norm trainlda" lda_process
        check "$submean_process" "lda whiten norm getmean" submean_process
        check "$whiten_process" "lda norm submean trainwhiten trainpcawhiten" whiten_process
        check "$svm_process" "lda submean whiten norm" svm_process
        check "$gmm_process" "lda submean whiten norm" gmm_process
        check "$lr_process" "lda submean whiten norm" lr_process
        check "$plda_process" "lda submean whiten norm trainplda" plda_process
        check "$aplda_process" "lda submean whiten norm trainaplda" aplda_process
        check "$score" "cosine svm plda aplda gmm lr" score
        check "$metric" "eer Cavg" metric
        
    # fi
    [ -f $vectordir/$ivec_enrollset/xvector.scp ] && vectortype=xvector && echo -e "[Auto find] Your vectortype is xvector\n"
    [ -f $vectordir/$ivec_enrollset/ivector.scp ] && vectortype=ivector && echo -e "[Auto find] Your vectortype is ivector\n"
    [ "$vectortype" == "" ] && echo "Don't find xvector or ivector type in $vectordir/$enrollset and please specify your own vectortype" && exit 1
    [ "$trainset" == "" ] && trainset=$enrollset
    lda_data_config="$trainset[$trainset $testset]"
    submean_data_config="$trainset[$trainset $testset]"
    whiten_data_config="$trainset[$trainset $testset]"
    [ "$lda" != "true" ] && lda_data_config=""
    [ "$submean" != "true" ] && submean_data_config=""
    [ "$whiten" != "true" ] && whiten_data_config=""
    [[ "$score" != *"plda"* && "$score" != *"aplda"* ]] && plda_trainset=""
    [[ "$score" != *"aplda"* ]] && aplda_trainset=""

    echo "[INFO] vectortype: $vectortype; trainset: $trainset"
    echo "[INFO] lda_data_config: $lda_data_config; submean_data_config: $submean_data_config; whiten_data_config: $whiten_data_config"
    allsets="$enrollset $testset $plda_trainset $aplda_trainset \
    $(echo $lda_data_config | sed 's/]/ /g' | sed 's/\[/ /g') \
    $(echo $submean_data_config | sed 's/]/ /g' | sed 's/\[/ /g') \
    $(echo $whiten_data_config | sed 's/]/ /g' | sed 's/\[/ /g')"
    echo "[INFO] allsets: $allsets"
    #  i-vector settings
    
    for set in $(echo $allsets | sed 's/ /\n/g' | sed '/^$/d' | sort -u);do
        [ ! -d $datadir/$set ] && echo "[exit] No such dir $datadir/$set" && exit 1
        [ ! -d $vectordir/$set ] && echo "[exit] No such dir $vectordir/$set" && exit 1
        errorNum=0
        logNum=0
        [ -d $vectordir/$set/log ] && logNum=$(find $vectordir/$set/log/ -name "extract*.log" | wc -l)
        [[ "$logNum" -gt 0 ]] && errorNum=$(grep ERROR $vectordir/$set/log/*.log | wc -l)
        [[ "$errorNum" -gt 0 ]] && echo "There are some ERRORS in $vectordir/$set/log/*.log and it means you lose many vectors which is so bad thing and I suggest you to extract vectors of this dataset again." && exit 1
        echo -e "name $set\ndata $datadir/$set\ndir $vectordir/$set\ninput $vectortype.scp" > $vectordir/$set/config
    done
        if [ "$lda" == "true" ];then
            echo $lda_data_config | sed 's/]/\n/g' | sed 's/\[/ /g' | sed '/^$/d' | \
            awk -v vdir=$vectordir -v lda_process=$lda_process -v clda=$clda '{
                if($1){print "lda_process",lda_process >> vdir"/"$1"/config";}
                for(i=2;i<=NF;i++){
                    if(!a[$i]){
                        print "lda_data_conf",vdir"/"$1"/config" >> vdir"/"$i"/config";
                        a[$i]=1;
                    }
                }
            }'
        fi

        if [ "$submean" == "true" ];then
            echo $submean_data_config | sed 's/]/\n/g' | sed 's/\[/ /g' | sed '/^$/d'| \
            awk -v vdir=$vectordir -v submean_process=$submean_process '{
                if($1){print "submean_process",submean_process >> vdir"/"$1"/config";}
                for(i=2;i<=NF;i++){
                    if(!a[$i]){
                        print "submean_data_conf",vdir"/"$1"/config" >> vdir"/"$i"/config";
                        a[$i]=1;
                    }
                }
            }'
        fi
    # fi
    enroll_conf=$vectordir/$enrollset/config
    test_conf=$vectordir/$testset/config
    # config for trials and get trials
    # if [[ $stage -le 3 && 3 -le $endstage ]];then
        if [ "$trials" == "" ];then
            trials=$vectordir/$testset/trials
            writeconf "trials" $trials $test_conf
            [[ ! -f $trials || $trials_force_clear == "true" ]] && \
            get_trials $enroll_conf $test_conf  # calculate trials for enroll using enroll-spk2utt and test-utt2spk
        else
            writeconf "trials" $trials $test_conf
        fi
        list="$vectordir/$testset/list.tmp" # a global file which is used to avoiding re-computation
        > $list
        [ "$process_force_clear" == "true" ] && rm -f $vectordir/$enrollset/num_utts.ark # Fix a bug when using this script in a bad way
    # fi

    [ "$eval" == "true" ] && metric=""
    outsets=""
    outscores=""

        list="$vectordir/$testset/list.tmp"
        for the_classfier in $(echo $score | sed 's/-/ /g');do
            echo "[ $the_classfier ]"
            if [ "$the_classfier" == "svm" ];then
                enroll_file=$(process $enroll_conf $svm_process)
                writeconf final $enroll_file $enroll_conf
            elif [ "$the_classfier" == "gmm" ];then
                enroll_file=$(process $enroll_conf $gmm_process)
                writeconf final $enroll_file $enroll_conf
            elif [ "$the_classfier" == "lr" ];then
                enroll_file=$(process $enroll_conf $lr_process)
                writeconf final $enroll_file $enroll_conf
            else
                enroll_file=$(process $enroll_conf $enroll_process)
                writeconf final $enroll_file $enroll_conf
            fi
            test_file=$(process $test_conf $test_process)
            writeconf "final" $test_file $test_conf
            tmp=$(get_params_for_score $the_classfier $enroll_conf $test_conf $extra_name)
            outname=$(echo "$tmp" | awk '{print $1}')
            params=$(echo "$tmp" | awk '{$1="";print $0}')
            [[ ! -f "${outname}.score" || "$score_force_clear" == "true" ]] && $the_classfier $params
            outscores="$outscores ${outname}.score"
        

            trials=$vectordir/$testset/trials

                for the_metric in $(echo $metric | sed 's/-/ /g');do
                [ "$the_metric" == "eer" ] && subtools/computeEER.sh --write-file ${outname}.eer ${outname}.score 3 $trials 3 && outsets="$outsets ${outname}.eer"
                [ "$the_metric" == "Cavg" ] && subtools/computeCavg.py -pairs $trials ${outname}.score > ${outname}.Cavg && \
                    cat ${outname}.Cavg && outsets="$outsets ${outname}.Cavg" 
            done
            outsets="$outsets ${outname}.Cavg"
        done
        echo -e "\n[ $testset ]"
        for x in $outsets;do
            echo -e `cat $x`"\t$x"
        done
    # fi
fi

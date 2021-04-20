#!/bin/bash

# Build a baseline for OLR Challenge 2020
# Zhang Haobo June 17, 2020

nj=20
steps=
cmd="slurm.pl --quiet"

echo 
echo "$0 $@"
echo

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

#Training set
train=data/train
#AP20-OLR-test
task1_test=data/task1_test
task2_test=data/task2_test
task3_test=data/task3_test
#AP20-OLR-ref-enroll
task1_enroll=data/task1_enroll
task2_enroll=data/task2_enroll
task3_enroll=data/task3_enroll
#AP20-OLR-ref-dev
task1_dev=data/task1_dev
task2_dev=data/task2_dev

# step 1: data preparation for training

temp=data/temp
if [ ! -z $step01 ]; then
    src_db_dir=/mipirepo/data/olr2020data/AP19-OLR-data/AP18-OLR_data/AP17-OLR_train_dev    
    data1=$temp/AP16AP17
    if true; then
        [ -d $data1 ] || mkdir -p $data1
        cp $src_db_dir/utt2lang $data1 || exit 1;
        cp $src_db_dir/data/train/{spk2utt,utt2spk} $data1 || exit 1;
        cat $src_db_dir/data/train/wav.scp | \
        sed 's#data#/mipirepo/data/olr2020data/AP19-OLR-data/AP18-OLR_data/AP17-OLR_train_dev/data#g' > $data1/wav.scp
        echo "## LOG(Part1 Done)"
    fi
    src_db_dir=/mipirepo/data/olr2020data/AP19-OLR-data/AP18-OLR_data/AP17-OLR_test
    data2=$temp/AP17test
    if true; then
        [ -d $data2 ] || mkdir -p $data2
        cp $src_db_dir/utt2lang $data2 || exit 1;
        awk '{print $1,$1}' $src_db_dir/utt2lang > $data2/utt2spk || exit 1;
        cp $data2/utt2spk $data2/spk2utt || exit 1;
        cat $src_db_dir/data/test_all/wav.scp | \
        sed 's#data#/mipirepo/data/olr2020data/AP19-OLR-data/AP18-OLR_data/AP17-OLR_test/data#g' > $data2/wav.scp
        utils/copy_data_dir.sh --spk-prefix AP17test- --utt-prefix AP17test- $data2 $data2-prefix || exit 1;
        sed 's/^/AP17test-/g' $data2/utt2lang > $data2-prefix/utt2lang
        echo "## LOG(Part2 Done)"
    fi
    train=data/train
    if true; then
        utils/combine_data.sh $train $data1 $data2-prefix || exit 1;
        utils/data/fix_data_dir.sh $train || exit 1;
    fi
fi

# --------------------------------------------------------
# step 2: data preparation for task1 enrollment
# All data in training sets of languages:
#   Cantonese, Indonesian, Japanese, Russian, Korean, Vietnamese.
#   (AP20-ref-enroll-task1)
#   ct-cn
#   id-id
#   ja-jp
#   ko-kr
#   ru-ru
#   vi-vn

if [ ! -z $step02 ]; then
    echo $task1_enroll
    [ -d $task1_enroll ] || mkdir -p $task1_enroll
    cat $train/utt2lang | \
    perl -ane 'chomp;m/(\S+)\s+(\S+)/g or die; ($utt, $lang)=($1,$2);
                if($utt=~m/(^ct-cn|^id-id|^ja-jp|^ko-kr|^ru-ru|^vi-vn)/g){
                    print("$utt\n"); }' > $task1_enroll/uttlist.txt
    utils/subset_data_dir.sh --utt-list $task1_enroll/uttlist.txt $train $task1_enroll || exit 1;
    utils/data/fix_data_dir.sh $task1_enroll || exit 1;
fi

# step 3: data preparation for task2 enrollment
sr_dir=/mipirepo/data/olr2020data/AP20-OLR-dialect
if [ ! -z $step03 ]; then
    echo $task2_enroll
    [ -d $task2_enroll ] || mkdir -p $task2_enroll
    if true; then
        find $sr_dir -name "*.wav" | while read line; do
            uttid=$(echo $line | sed -e 's#/# #g;s#\.wav##g' | awk '{print $4"-"$5"-"$7}')
            echo "$uttid $line"
        done > $task2_enroll/wav.scp
    fi
    if true; then
        awk '{print $1}' $task2_enroll/wav.scp | while read line; do
            langid=$(echo $line|sed 's#.*-\([a-z]\+\)-[0-9]\+#\1#g')
            echo "$line $langid"
        done > $task2_enroll/utt2lang
    fi
    if true; then
        awk '{print $1" "$1}' $task2_enroll/wav.scp | sort > $task2_enroll/utt2spk
        cp $task2_enroll/utt2spk $task2_enroll/spk2utt
    fi
    utils/data/fix_data_dir.sh $task2_enroll || exit 1;
fi

# step 4: data preparation for task3 enrollment
# All data in training sets, of languages:
#       Cantonese, Japanese, Russian, Korean, Mandarin.(AP20-ref-enroll-task3)
if [ ! -z $step04 ]; then
    echo $task3_enroll
    [ -d $task3_enroll ] || mkdir -p $task3_enroll
    cat $train/utt2lang | \
    perl -ane 'chomp;m/(\S+)\s+(\S+)/g or die;($utt, $lang)=($1,$2);
        if($utt=~m/(^ct-cn|^ja-jp|^ko-kr|^ru-ru|^zh-cn)/g){print("$utt\n");}' > \
    $task3_enroll/uttlist.txt
    utils/subset_data_dir.sh --utt-list $task3_enroll/uttlist.txt $train $task3_enroll || exit 1;
    utils/data/fix_data_dir.sh $task3_enroll || exit 1;
fi

# --------------------------------------------------------
# step 5: data preparation for task1 dev
#         dev set: AP19-OLR-channel
sr_dir=/mipirepo/data/olr2020data/AP19-OLR-data/AP19-OLR_test/task_2
gr_dir=/mipirepo/data/olr2020data/AP19-OLR-data/AP19-OLR_test_groundtruth
if [ ! -z $step05 ]; then
    echo $task1_dev
    [ -d $task1_dev ] || mkdir -p $task1_dev
    cp $sr_dir/{spk2utt,utt2spk} $task1_dev
    cp $gr_dir/task_2_utt2lang $task1_dev/utt2lang
    sed 's#audio#/mipirepo/data/olr2020data/AP19-OLR-data/AP19-OLR_test/task_2/audio#g' \
        $sr_dir/wav.scp > $task1_dev/wav.scp
    utils/data/fix_data_dir.sh $task1_dev || exit 1;
fi

# step 6: data preparation for task2 dev 
#         dev set: AP19-OLR-dev&eval-task3-test
sr1_dir=/mipirepo/data/olr2020data/AP19-OLR-data/AP19-OLR_dev/task_3/test
sr2_dir=/mipirepo/data/olr2020data/AP19-OLR-data/AP19-OLR_test/task_3/test
if [ ! -z $step06 ]; then
    echo $task2_dev
    [ -d $task2_dev ] || mkdir -p $task2_dev
    [ -d data/temp ] || mkdir -p data/temp
    utils/copy_data_dir.sh --spk-prefix AP19dev-  --utt-prefix AP19dev-  $sr1_dir data/temp/AP19dev
    utils/copy_data_dir.sh --spk-prefix AP19test- --utt-prefix AP19test- $sr2_dir data/temp/AP19test
    cat $sr1_dir/utt2lang | sed 's/^/AP19dev-/g' > data/temp/AP19dev/utt2lang
    cat $gr_dir/task_3_utt2lang | sed 's/^/AP19test-/g' > data/temp/AP19test/utt2lang
    sed -i 's#audio#/mipirepo/data/olr2020data/AP19-OLR-data/AP19-OLR_dev/task_3/test/audio#g' data/temp/AP19dev/wav.scp
    sed -i 's#audio#/mipirepo/data/olr2020data/AP19-OLR-data/AP19-OLR_test/task_3/test/audio#g' data/temp/AP19test/wav.scp
    utils/combine_data.sh $task2_dev data/temp/AP19dev data/temp/AP19test || exit 1;
    utils/data/fix_data_dir.sh $task2_dev || exit 1;
fi

if [ ! -z $step07 ]; then
    echo "## LOG(Delete data/temp)"
    [ -e data/temp ] && rm -rf data/temp
    rm data/*/uttlist.txt
    tree data
fi
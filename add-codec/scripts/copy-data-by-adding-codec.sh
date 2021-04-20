#!/bin/bash 

# By Haihua, TL@NTU, 2019
# please note this script needs ffmpeg tool and codec list file
# we use ffmpeg to downsample data to 8k HZ randomly using the codec provided in the codec list
# we then upsample the audio stream back to 16k HZ.
# please note that some of nodes in NTU cluster have not been installed ffmpeg so far, and the installed nodes are node03, node04
# and node06.

. path.sh || exit 1

echo
echo "## LOG ($0): $@"
echo

# begin option
cmd="slurm.pl --quiet" # --exclude=node0[3-5]"
steps=
nj=400
do_clean=false
# end option

function Example {
 cat <<EOF

 [Usage]:

 $0  [options] <source_data> <codec_list_file> <target_encodec_data>

 [Example]:

 $0 --steps 1 --cmd "$cmd" --do-clean $do_clean \
/home4/hhx502/w2019/exp/test-copy-data-by-adding-codec/seame \
/home4/hhx502/w2019/source-scripts/egs/w2019/seame/codec-list.txt \
/home4/hhx502/w2019/exp/test-copy-data-by-adding-codec/seame-codec

EOF
}

. parse_options.sh || exit 1


steps=$(echo $steps | perl -e '$steps=<STDIN>;  $has_format = 0;
  if($steps =~ m:(\d+)\-$:g){$start = $1; $end = $start + 10; $has_format ++;}
        elsif($steps =~ m:(\d+)\-(\d+):g) { $start = $1; $end = $2; if($start == $end){}elsif($start < $end){ $end = $2 +1;}else{die;} $has_format ++; }  
      if($has_format > 0){$steps=$start;  for($i=$start+1; $i < $end; $i++){$steps .=":$i"; }} print $steps;' 2>/dev/null)  || exit 1

if [ ! -z "$steps" ]; then
  for x in $(echo $steps|sed 's/[,:]/ /g'); do
    index=$(printf "%02d" $x);
    declare step$index=1
  done
fi

if [ $# -ne 3 ]; then
  Example && exit 1
fi

source_data=$1
codec_list=$2
target_data=$3

# first copy data to the target folder
tmpdir=$target_data/tmp
[ -d $tmpdir ] || mkdir -p $tmpdir
if [ ! -z $step01 ]; then
  scripts/copy_data_dir.sh --spk-prefix codec1.0v- --utt-prefix codec1.0v- \
  $source_data $tmpdir 
fi
# now rewrite the wav.scp according to the segments
if [ ! -z $step02 ]; then
  [ -f $tmpdir/segments ] || \
  { echo "## ERROR ($0): segments file '$tmpdir/segments' expected"; exit 1;  }
  cat $tmpdir/segments | scripts/rewrite-wav-scp.pl $tmpdir/wav.scp > $target_data/new_wav.scp
fi
# do codec processing on wav.scp
if [ ! -z $step03 ]; then
  [ -f $target_data/new_wav.scp ] || \
  { echo "## ERROR ($0): wav.scp file '$target_data/new_wav.scp' expected"; exit 1; }
  cat $target_data/new_wav.scp | \
  ./scripts/add-codec-with-ffmpeg.pl  $codec_list > $target_data/wav.scp
  # utils/fix_data_dir.sh $target_data
fi

# make wav2dur and then prepare new segments file
if [ ! -z $step04 ]; then
  temp_data_dir=$target_data/wav${nj}split
  rm -rf $temp_data_dir
  wavscps=$(for n in `seq $nj`; do echo $temp_data_dir/$n/wav.scp; done)
  subdirs=$(for n in `seq $nj`; do echo $temp_data_dir/$n; done)
  if ! mkdir -p $subdirs >&/dev/null; then
    for n in `seq $nj`; do
      mkdir -p $temp_data_dir/$n
    done 
  fi
  utils/split_scp.pl $target_data/wav.scp $wavscps
  $cmd JOB=1:$nj $target_data/log/get_reco_durations.JOB.log \
      wav-to-duration --read-entire-file=true \
      scp:$temp_data_dir/JOB/wav.scp ark,t:$temp_data_dir/JOB/wav2dur || \
      { echo "$0: there was a problem getting the durations"; exit 1; } # This could  
  for n in `seq $nj`; do
    cat $temp_data_dir/$n/wav2dur
   done > $target_data/wav2dur
  rm -r $temp_data_dir
  # wav-to-duration --read-entire-file scp:$target_data/wav.scp ark,t:$target_data/wav2dur
fi
# make a trivial segments file 
if [ ! -z $step05 ]; then
  cat $target_data/wav2dur | \
  perl -ane 'use utf8; open qw(:std :utf8); chomp; m/(\S+)\s+(.*)/g or next; print "$1 $1 0.00 $2\n";' > $target_data/segments
  cp $tmpdir/{text,utt2spk,spk2utt} $target_data/
  utils/fix_data_dir.sh $target_data
fi

if $do_clean; then
    rm -rf $tmpdir $target_data/new_wav.scp  2>/dev/null
fi

echo "## Done !"

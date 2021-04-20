#!/bin/bash















for the metric in $(echo $metric | sed 's/-/ /g'); do
    subtools/computeEER.sh --write-file ${outname}.eer ${outname}.score 3 $trials 3
    outsets="$outsets ${outname}.eer"

















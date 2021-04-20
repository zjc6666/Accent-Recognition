#!/bin/bash
sdir=/home/maison2/lid/pyz/w2020/project/olr2020_pretrain_model/data/dev/Tibet
tdir=/home/maison2/lid/pyz/w2020/project/olr2020_pretrain_model/exp/local/data/Tibet/dev
cat $tdir/text.origin | perl -ane 'use utf8; use open qw(:std :utf8); chomp; m/(\S+)\s+(.*)/g or next; my ($utt, $words) = ($1, $2); $words =~ s/[\?\.\!\/_,\$%^*()+\"。？！、￥·《》（）]/ /g; $words =~ s/་/ /g; $words =~ s/།//g; print "$utt\t$words\n"; ' > $tdir/text.origin.1
# cat dev_text | perl -ane 'use utf8; use open qw(:std :utf8); chomp; m/(\S+)\s+(.*)/g or next; my ($utt, $words) = ($1, $2); $words =~ s/[\?\.\!\/_,\$%^*()+\"。？！、￥·《》（）]/ /g; $words =~ s/་/ /g; $words =~ s/།//g; print "$utt\t$words\n"; ' > dev_text_new

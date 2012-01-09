#!/bin/sh

soft_dir=/proj/hoodlab/share/vcassen/trends/data/GEO/
cd $soft_dir

for f in ${soft_dir}/*.soft; do
    bn=`basename $f .soft`
    hn="${bn}.header"
    rm -f ${hn}
    egrep '^[\!\#\^]' $f > $hn
done

#!/bin/bash
#arguments: psfile1 psfile2 ... 
#for streamflow
if [ $# -lt 1 ]; then
    echo "$0 need at least 1 parameter"
    exit
fi
paras=" -trim -density 300% "
while [ $# -ge 1 ]; do
    psfile=$1
    if [ -e "$psfile" ]; then
        echo "convert for $psfile"
        psf=$(basename $psfile)
        pngf="$(basename $psf .ps).png"
        repo=/data02/home/fddanew/sishen/temp/forConvertNode30/
        test -d $repo || mkdir -p $repo
        cp $psfile $repo/
        echo ssh node30 "convert $paras $repo/$psf $repo/$pngf"
        ssh node30 "convert $paras $repo/$psf $repo/$pngf"
        cp $repo/$pngf $(dirname $psfile)
    else
        echo "$psfile not exist"
    fi
    shift 1
done
    


#!/bin/bash
# gifdir,  cycledir, cycle, hrbef
if [ $# -lt 3 ]; then
    echo "3 parameter needed: webdir, cycle, hrbef"
    exit
fi
srcdir=$1/gifs
destdir=$1/cycles
cycle=$2
hrbef=$3

function mydir(){
    local is_begin_slash mydir
    is_begin_slash=$(echo $2 | grep "^/")
    if [ -n "$is_begin_slash" ]; then
        mydir=$(dirname $2)
    else
        mydir="$1"/$(dirname $2)
    fi
    echo $mydir
}
this_dir=$(mydir $(pwd) $0)
source $this_dir/datelib.sh

for ((h=$hrbef; h<=-1; h++)); do
    dat=$(date_add $cycle $h "hour")
    echo "dat: $dat"
    if [ -d $srcdir/$dat ]; then
        test -d $destdir/$cycle/$dat || mkdir -p $destdir/$cycle/$dat   
        cd $destdir/$cycle/$dat 
        ln -sf $srcdir/$dat/* .
    fi
done

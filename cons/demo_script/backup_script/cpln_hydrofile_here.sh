#!/bin/bash
if [ $# -lt 6 ]; then
    print "argument: dir,  postfix,  cp_or_ln(cp, ln),  cyc, starth, endh"
    exit
fi

#$1: pwd, $2: $0 of this script
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

dir=$1
postfix=$2
cp_or_ln=$3
cyc=$4
starth=$5
endh=$6
thisdir=$(mydir $(pwd) $0)
source $thisdir/datelib.sh

echo $starth $endh
for ((h=$starth; h<=$endh; h++)); do
    dat=$(date_add $cyc $h "hour")
    file=$(ls $dir/${dat}*${postfix})
    if [ -n "$file" ]; then
        if [ "$cp_or_ln" == "cp" ]; then
            cp -f $file .
        else
            ln -sf $file .
        fi
    fi
done
        




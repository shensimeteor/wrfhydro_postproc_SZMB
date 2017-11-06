#!/bin/bash
#arguments: hydro_root_dir/{ncl,data,cons}; cycle_dir(put all data there); work_dir; web_dir/{cycles,gifs}; cycle
if [ $# -lt 5 ]; then
    echo "arguments: hydro_root_dir/{ncl,data,cons}; cycle_dir; work_dir; web_dir/{cycles,gifs}; cycle"
    exit
fi

scriptdir=$1/ncl
cycledir=$2
workdir=$3
datadir="$1/data/"
consdir="$1/cons/"
webdir=$4
cycle=$5

date
echo "scriptdir: $scriptdir"
echo "cycledir:  $cycledir"
echo "workdir:   $workdir"
echo "webdir:    $webdir"
echo "cycle:     $cycle"
echo ""
#normal
test -d $workdir || mkdir -p -p $workdir
cd ${workdir}

#cycle=$1
#cycdir=$2

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

#cp gifs/<cycle_date>/<TS>.png gifs/<1-24hour forecast_date>/<TS>.png
function cp_gifs(){
    gifdir=$1
    cycle=$2
    fcstlen=$3
    for((i=1; i<=$fcstlen; i++)); do
        datex=$(date_add $cycle $i "hour")
        if [ -d $gifdir/$datex ]; then
            cp *png $gifdir/$datex
        fi
    done
}
    

this_dir=$(mydir $(pwd) $0)
source $this_dir/datelib.sh
ln -sf $cycledir/*.CHRTOUT_DOMAIN1 .
ln -sf $scriptdir/*ncl .
date_start=$(date_add $cycle -6 "hour")
date_end=$(date_add $cycle 24 "hour")
# nodes accu streamflow 
#TG
cmd="ncl plot_nodes_accu_streamflow_ts.ncl 'nodes_idx_list=\"17751,18024,18286,16975,15568,14986\"'  'accu_hour_list=\"1,3,6,12,24\"'  'color_list=\"blue,cyan,green,orange,red\"' 'file_pattern=\"*.CHRTOUT_DOMAIN1\"' 'nodes_name_list=\"A,B,C,D,E,F\"' 'start_date10=\"$date_start\"' 'end_date10=\"$date_end\"' 'copydir_list=\"$webdir/cycles/$cycle,$webdir/gifs\"' 'ymax=1000' 'cycle_date10=\"$cycle\"' "
bash -c "$cmd"
#GL
cmd="ncl plot_nodes_accu_streamflow_ts.ncl 'nodes_idx_list=\"22204,20318,19500,17186\"'  'accu_hour_list=\"1,3,6,12,24\"'  'color_list=\"blue,cyan,green,orange,red\"' 'file_pattern=\"*.CHRTOUT_DOMAIN1\"' 'nodes_name_list=\"GuanLan,DaLang,LongHua,MinZhi\"' 'start_date10=\"$date_start\"' 'end_date10=\"$date_end\"' 'ymax=3500' 'copydir_list=\"$webdir/cycles/$cycle,$webdir/gifs\"' 'cycle_date10=\"$cycle\"' "
bash -c "$cmd"
#TG in,out 3hr accu streamflow
cmd="ncl plot_TGfixed_streamflow_accu.ncl 'file_pattern=\"*.CHRTOUT_DOMAIN1\"' 'start_date10=\"$date_start\"' 'end_date10=\"$date_end\"' 'ymax=250' 'cycle_date10=\"$cycle\"' 'copydir_list=\"$webdir/cycles/$cycle,$webdir/gifs\"' "
echo "$cmd"
bash -c "$cmd"
#TG in,out cont-accu streamflow
cmd="ncl plot_TGfixed_streamflow_contaccu.ncl 'file_pattern=\"*.CHRTOUT_DOMAIN1\"' 'start_date10=\"$date_start\"' 'end_date10=\"$date_end\"' 'ymax=1000' 'cycle_date10=\"$cycle\"' 'copydir_list=\"$webdir/cycles/$cycle,$webdir/gifs\"' "
echo "$cmd"
bash -c "$cmd"

cp_gifs $webdir/gifs $cycle 24

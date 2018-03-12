#!/bin/bash
#update for new domain (GERUFFS)
#contains:
## TGSK, 6 points (in/out flow): A B C D E F (named as TGSK-x, x=A,B,C,D,E,F)
## GLHU, 4 points: Mingzhi, Longhua, DaLang, GuanLanHe (named as GLHU-xx, x=MZ, LH, DL, GL)
## single ShuiKu points: named as SK-xx
##     Gaofeng (SK-GF),  Meilin (SK-ML), ZhenKeng (SK-ZK), GuanJing (SK-GJ)
##     ChiYou (SK-CY), FengTian (SK-FT), DaJian (SK-DJ), Yantian (SK-YT)
##     ShenZhen xiayou (SK-SZd), ShenZhen shangyou (SK-SZu)
## single HeDao points: named as HD-xxx/xxxx
##     MaoZhouHe (HD-MZH), GuanLanHe (HD-GLH), PingShanHe (HD-PSH), 
##     LongGangHe (HD-LGH), 
## single JieDao points: named as JD-xxx
##     MeiLinLu (JD-MLL), JinHuaLu (JD-JHL), HuangTian PaiChuSuo(JD-PCS)
##     ShuangLongQiao (JD-SLQ)

#arguments: hydro_root_dir/{ncl,data,cons}; cycle_dir(put all data there); work_dir; web_dir/{cycles,gifs}; cycle; begin hour plot (e.g. -6); plot_end_hour (e.g. 24)
if [ $# -lt 7 ]; then
    echo "arguments: hydro_root_dir/{ncl,data,cons}; cycle_dir; work_dir; web_dir/{cycles,gifs}; cycle; plot_begin_hour; plot_end_hour"
    exit
fi

scriptdir=$1/ncl
cycledir=$2
workdir=$3
datadir="$1/data/"
consdir="$1/cons/"
webdir=$4
cycle=$5
plot_begin_hour=$6
plot_end_hour=$7

date
echo "scriptdir: $scriptdir"
echo "cycledir:  $cycledir"
echo "workdir:   $workdir"
echo "webdir:    $webdir"
echo "cycle:     $cycle"
echo "plot_begin_hour:  $plot_begin_hour"
if [ $plot_begin_hour -gt 0 ]; then
    echo "- Warning: usually plot_begin_hour should be <= 0 !!"
fi
echo "plot_end_hour: $plot_end_hour"
if [ $plot_end_hour -lt 0 ]; then
    echo "- Warning: usually plot_end_hour should be >=0 !!"
fi
#normal
test -d $workdir || mkdir -p $workdir
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
date_start=$(date_add $cycle $plot_begin_hour "hour")
date_end=$(date_add $cycle $plot_end_hour "hour")
# nodes accu streamflow 
#TGSK
tsdir="$webdir/tsdata/$cycle"
test -d $tsdir  || mkdir -p $tsdir
tspara=" 'data_outfile_prefix=\"$tsdir/TGSK_Accu_Streamflow_${cycle}\"' " ##for output ts txt file
cmd="ncl plot_nodes_accu_streamflow_ts.ncl 'nodes_idx_list=\"5831\"'  'accu_hour_list=\"1,3,6,12,24\"'  'color_list=\"blue,cyan,green,orange,red\"' 'file_pattern=\"*.CHRTOUT_DOMAIN1\"' 'nodes_name_list=\"TGSK-F\"' 'start_date10=\"$date_start\"' 'end_date10=\"$date_end\"' 'copydir_list=\"$webdir/cycles/$cycle,$webdir/gifs\"' 'ymax=1000' 'cycle_date10=\"$cycle\"' $tspara "
echo "$cmd"
bash -c "$cmd"
#GLHU
tspara=" 'data_outfile_prefix=\"$tsdir/GLHU_Accu_Streamflow_${cycle}\"' "
cmd="ncl plot_nodes_accu_streamflow_ts.ncl 'nodes_idx_list=\"8601,8105,7214,7221\"'  'accu_hour_list=\"1,3,6,12,24\"'  'color_list=\"blue,cyan,green,orange,red\"' 'file_pattern=\"*.CHRTOUT_DOMAIN1\"' 'nodes_name_list=\"GLHU-GL,GLHU-DL,GLHU-LH,GLHU-MZ\"' 'start_date10=\"$date_start\"' 'end_date10=\"$date_end\"' 'ymax=3500' 'copydir_list=\"$webdir/cycles/$cycle,$webdir/gifs\"' 'cycle_date10=\"$cycle\"' $tspara "
echo "$cmd"
bash -c "$cmd"
# #TG in,out 3hr accu streamflow
#cmd="ncl plot_TGfixed_streamflow_accu.ncl 'file_pattern=\"*.CHRTOUT_DOMAIN1\"' 'start_date10=\"$date_start\"' 'end_date10=\"$date_end\"' 'ymax=250' 'cycle_date10=\"$cycle\"' 'copydir_list=\"$webdir/cycles/$cycle,$webdir/gifs\"' "
#echo "$cmd"
#bash -c "$cmd"
#TG in,out cont-accu streamflow
#tspara=" 'data_outfile=\"$tsdir/TGSK_ContAccu_Streamflow_${cycle}.csv\"' "
#cmd="ncl plot_TGfixed_streamflow_contaccu.ncl 'file_pattern=\"*.CHRTOUT_DOMAIN1\"' 'start_date10=\"$date_start\"' 'end_date10=\"$date_end\"' 'ymax=1000' 'cycle_date10=\"$cycle\"' 'copydir_list=\"$webdir/cycles/$cycle,$webdir/gifs\"' $tspara "
#echo "$cmd"
#bash -c "$cmd"

#Other Reservoir, HeDao, Jiedao (10 + 4 + 4)
tspara=" 'data_outfile_prefix=\"$tsdir/Other_Accu_Streamflow_${cycle}\"' "
#yliu 20180305
#list_nodename="SK-GF,SK-ML,SK-ZK,SK-GJ,SK-CY,SK-FT,SK-DJ,SK-SZd,SK-YT,HD-MZH,HD-GLH,HD-PSH,HD-LGH,JD-MLL,JD-JHL,JD-HTP,JD-SLQ"
#list_nodeidx="5831,8601,7221,7214,8105,6848,5246,5020,9450,7234,10845,11704,5167,8625,11881,8601,8071,10007,5128,5510,6429,9578"
list_nodename="SK-GF,SK-ML,SK-ZK,SK-GJ,SK-CY,SK-FT,SK-DJ,SK-DSP,SK-LX,HD-MZH,HD-GLH,HD-PSH,HD-LGH,JD-MLL,JD-JHL,JD-HTP,JD-SLQ,SK-CLP"
#list_nodeidx= "6849,  5232, 4958, 9406, 7234,10725,11651,  7644, 7930, 11882,  8481,  8072, 10008,  5129,  5431,  6395,  9577,  5703, 8071,10007,5128,5510,6429,9578"
list_nodeidx="6848,  5231, 4957, 9405, 7233,10724,11650,  7643, 7929, 11881,  8480,  8073, 10007,  5128,  5430,  6394,  9576,  5702, 8071,10007,5128,5510,6429,9578"
#yliu 20180305
cmd="ncl plot_nodes_accu_streamflow_ts.ncl 'nodes_idx_list=\"$list_nodeidx\"'  'accu_hour_list=\"1,3,6,12,24\"'  'color_list=\"blue,cyan,green,orange,red\"' 'file_pattern=\"*.CHRTOUT_DOMAIN1\"' 'nodes_name_list=\"$list_nodename\"' 'start_date10=\"$date_start\"' 'end_date10=\"$date_end\"' 'ymax=3500' 'copydir_list=\"$webdir/cycles/$cycle,$webdir/gifs\"' 'cycle_date10=\"$cycle\"' $tspara "
echo "$cmd"
bash -c "$cmd"

cp_gifs $webdir/gifs $cycle 24

touch $workdir/finished.timeseries

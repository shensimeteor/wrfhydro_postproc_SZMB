#!/bin/bash

declare -a event_start
declare -a event_end
event_start=(2017061112 2017061512 2017061518)
event_end=(2017061412 2017061812 2017061900)
hour_before_tolink=24 #ln the file before event_start 24hour
n_event=3
workdir="/data1/fdda-ops/sishen/SZMB_Hydro/ts_plot/qpe1/TieGang"
datadir="/data1/fdda-ops/hydro_case_study/case201705/exp_with_qpe1"
srcdir=$(pwd)
condir="$srcdir/../cons/"
source datelib.sh

test -d $workdir/ || mkdir -p $workdir
for ((i=0; i<$n_event; i++)); do
    cd $workdir
    date_start=${event_start[$i]}
    file_date_start=$(date_add ${event_start[$i]} -$hour_before_tolink "hour")
    date_end=${event_end[$i]}
    dirx="${date_start}-${date_end}"
    test -d $dirx || mkdir $dirx
    cd $dirx
    #link file for accu (including hour_before_tolink)
    dir_accu="hydro_files_accu"
    test -d $dir_accu || mkdir -p $dir_accu
    cd $dir_accu
    dat=$file_date_start
    while [ $dat -le $date_end ]; do
        filex="$datadir/${dat}00.CHRTOUT_DOMAIN1"
        if [ -e $filex ]; then
            ln -sf $filex .
        else
            echo "Warn: $filex NOT exist!"
        fi
        dat=$(date_add $dat 1 "hour")
    done
    cd ..
    #link file for instant. 
    dir_inst="hydro_files_inst"
    test -d $dir_inst || mkdir -p $dir_inst
    cd $dir_inst
    dat=$date_start
    while [ $dat -le $date_end ]; do
        filex="$datadir/${dat}00.CHRTOUT_DOMAIN1"
        if [ -e $filex ]; then
            ln -sf $filex .
        else
            echo "Warn: $filex NOT exist!"
        fi
        dat=$(date_add $dat 1 "hour")
    done
    cd ..
    #link forcing file
    dir_forcing="hydro_files_forcing"
    test -d $dir_forcing || mkdir -p $dir_forcing
    cd $dir_forcing
    dat=$date_start
    while [ $dat -le $date_end ]; do
        filex="$datadir/forcing/${dat}00.LDASIN_DOMAIN1"
        if [ -e $filex ]; then
            ln -sf $filex .
        else
            echo "Warn: $filex NOT exist!"
        fi
        dat=$(date_add $dat 1 "hour")
    done
    cd ..
    #run ncl
    ln -sf $srcdir/plot_nodes_streamflow_ts.ncl .
    ln -sf $srcdir/plot_nodes_accu_streamflow_ts.ncl .
    ln -sf $srcdir/plot_budget_streamflow_ts.ncl . 
    ln -sf $srcdir/plot_budget_accu_streamflow_ts.ncl .
    ln -sf $srcdir/plot_nodes_contaccu_streamflow_ts.ncl .
    ln -sf $srcdir/plot_budget_contaccu_streamflow_ts.ncl .
    ln -sf $srcdir/plot_totalprecp_chaninout_ts.ncl .
    ln -sf $srcdir/plot_contaccu_totalprecp_chaninout_ts.ncl .
    ln -sf $condir/idx_* .
    #plot totalprecp & channel in/out 
    cmd="ncl plot_totalprecp_chaninout_ts.ncl 'in_nodes_idx_list=\"17751,18024,18286,16975,15568\"' 'out_nodes_idx_list=\"14986\"' 'colors_inout_list=\"red,blue\"' 'streamfile_pattern=\"$dir_inst/*CHRTOUT_DOMAIN1\"' 'area_sum_precp_filelist=\"idx_inside_TG_lakearea.txt,idx_inside_TG_watershed.txt\"' 'area_sum_precp_namelist=\"TGlake,TGarea\"' 'colors_area_list=\"green,black\"' 'precpfile_pattern=\"$dir_forcing/*LDASIN_DOMAIN1\"' "
    bash -c "$cmd"
    mv chaninout_totalprecp.png chaninout_bothprecp.png
    cmd="ncl plot_totalprecp_chaninout_ts.ncl 'in_nodes_idx_list=\"17751,18024,18286,16975,15568\"' 'out_nodes_idx_list=\"14986\"' 'colors_inout_list=\"red,blue\"' 'streamfile_pattern=\"$dir_inst/*CHRTOUT_DOMAIN1\"' 'area_sum_precp_filelist=\"idx_inside_TG_lakearea.txt\"' 'area_sum_precp_namelist=\"TGlake\"' 'colors_area_list=\"green\"' 'precpfile_pattern=\"$dir_forcing/*LDASIN_DOMAIN1\"' "
    bash -c "$cmd"
    mv chaninout_totalprecp.png chaninput_lakeprecp.png
    #plot totalprecp & channel in/out continuly accumulated
    cmd="ncl plot_contaccu_totalprecp_chaninout_ts.ncl 'in_nodes_idx_list=\"17751,18024,18286,16975,15568\"' 'out_nodes_idx_list=\"14986\"' 'colors_inout_list=\"red,blue\"' 'streamfile_pattern=\"$dir_inst/*CHRTOUT_DOMAIN1\"' 'area_sum_precp_filelist=\"idx_inside_TG_lakearea.txt,idx_inside_TG_watershed.txt\"' 'area_sum_precp_namelist=\"TGlake,TGarea\"' 'colors_area_list=\"green,black\"' 'precpfile_pattern=\"$dir_forcing/*LDASIN_DOMAIN1\"' "
    bash -c "$cmd"
    mv chaninout_totalprecp_contaccu.png contaccu_chaninout_bothprecp.png
    cmd="ncl plot_contaccu_totalprecp_chaninout_ts.ncl 'in_nodes_idx_list=\"17751,18024,18286,16975,15568\"' 'out_nodes_idx_list=\"14986\"' 'colors_inout_list=\"red,blue\"' 'streamfile_pattern=\"$dir_inst/*CHRTOUT_DOMAIN1\"' 'area_sum_precp_filelist=\"idx_inside_TG_lakearea.txt\"' 'area_sum_precp_namelist=\"TGlake\"' 'colors_area_list=\"green\"' 'precpfile_pattern=\"$dir_forcing/*LDASIN_DOMAIN1\"' "
    bash -c "$cmd"
    mv chaninout_totalprecp_contaccu.png contaccu_chaninout_lakeprecp.png

    cmd="ncl plot_nodes_streamflow_ts.ncl 'nodes_idx_list=\"17751,18024,18286,16975,15568,14986\"' 'nodes_name_list=\"NorWst,North,NorEst,East,SouEst,South\"' 'color_list=\"blue,green,red,cyan,orange,black\"' 'file_pattern=\"$dir_inst/*.CHRTOUT_DOMAIN1\"'"
    bash -c "$cmd"
    cmd="ncl plot_nodes_accu_streamflow_ts.ncl 'nodes_idx_list=\"17751,18024,18286,16975,15568,14986\"'  'accu_hour_list=\"1,2,3,6\"'  'color_list=\"blue,green,red,orange\"' 'file_pattern=\"$dir_accu/*.CHRTOUT_DOMAIN1\"' 'nodes_name_list=\"NorWst,North,NorEst,East,SouEst,South\"' 'start_date10=\"$date_start\"' 'end_date10=\"$date_end\"'"
    bash -c "$cmd"
    cmd="ncl plot_budget_streamflow_ts.ncl 'in_nodes_idx_list=\"17751,18024,18286,16975,15568\"' 'out_nodes_idx_list=\"14986\"' 'file_pattern=\"$dir_inst/*.CHRTOUT_DOMAIN1\"'"
    bash -c "$cmd"
    cmd="ncl plot_budget_accu_streamflow_ts.ncl 'in_nodes_idx_list=\"17751,18024,18286,16975,15568\"' 'out_nodes_idx_list=\"14986\"' 'accu_hour_list=\"1,2,3,6,12,24\"' 'file_pattern=\"$dir_accu/*.CHRTOUT_DOMAIN1\"'  'start_date10=\"$date_start\"' 'end_date10=\"$date_end\"'"
    bash -c "$cmd"
    cmd="ncl plot_nodes_contaccu_streamflow_ts.ncl  'nodes_idx_list=\"17751,18024,18286,16975,15568,14986\"' 'nodes_name_list=\"NorWst,North,NorEst,East,SouEst,South\"' 'color_list=\"blue,green,red,cyan,orange,black\"' 'file_pattern=\"$dir_inst/*.CHRTOUT_DOMAIN1\"'"
    bash -c "$cmd"
    cmd="ncl plot_budget_contaccu_streamflow_ts.ncl  'in_nodes_idx_list=\"17751,18024,18286,16975,15568\"' 'out_nodes_idx_list=\"14986\"' 'file_pattern=\"$dir_inst/*.CHRTOUT_DOMAIN1\"'"
    bash -c "$cmd"
done
    

#/usr/bin/perl
if (! $ARGV[0] || $ARGV[0] eq "--" || $ARGV[0] eq "-h") {
   print "rtfdda_hydro_postproc.pl  <-id GMID>  <-m MEMBER>  <-c cycle | -o offset_hr> \n";
   exit(-1);
}else{
    $length = @ARGV;
    $i = 0;
    for($i = 0; $i < $length; $i++){
        if ($ARGV[$i] eq "--"){
            last;
        }elsif ($ARGV[$i] eq "-c"){
            $THIS_CYCLE = $ARGV[$i+1];
        }elsif ($ARGV[$i] eq "-o"){
            $OFFSET = $ARGV[$i+1];
            $ttime = time - $OFFSET *3600;
            ($sec,$mm,$hh,$dd,$mo,$yy,@_) = gmtime($ttime);
            if ($yy<50){ $yy+=2000; } else { $yy+=1900; }
            $THIS_CYCLE = sprintf("%04d%02d%02d%02d",$yy,$mo+1,$dd,$hh);
        }elsif ($ARGV[$i] eq "-m"){
            $MEM_NAME = $ARGV[$i+1];
        }elsif ($ARGV[$i] eq "-id"){
            $JOB_ID = $ARGV[$i+1];
        }else{
            next;
        }
    }
}
if (!"$THIS_CYCLE" || !"$MEM_NAME" || !"$JOB_ID") { 
     print "rtfdda_hydro_postproc.pl  <-id GMID>  <-m MEMBER>  <-c cycle | -o offset_hr> \n";
     exit(-1);
}

$GMODIR="$ENV{HOME}/data/GMODJOBS/$JOB_ID/";
$HYDRO_ROOT="$GMODDIR/hydro_postproc/";
$CYCLE_DIR="$ENV{HOME}/data/cycles/$JOB_ID/hydro/cycles/$MEM_NAME/$THIS_CYCLE";
$WEB_DIR="$ENV{HOME}/data/cycles/$JOB_ID/$MEM_NAME/postprocs/web";
$CSH_DIR="$ENV{HOME}/fddahome/cycle_code/CSH_ARCHIVE/ncl";
$workdir="/dev/shm/hydro_postproc/$JOB_ID/$MEM_NAME/$THIS_CYCLE";
$LOG_DIR="$ENV{HOME}/data/cycles/$JOB_ID/zout/hydro_postproc/cyc$THIS_CYCLE";
require "$CSH_DIR/common_tools.pl";

system("test -d $LOG_DIR || mkdir -p $LOG_DIR");
system("date");
print("cycle: $THIS_CYCLE\n");
print("workdir: $workdir\n");

#wait for hydro files
#1). wait for hydro cycle dir
$flag=&tool_file_wait(60,60,($CYCLE_DIR));
if ($flag =~ /Fail/){
    print("Error, $CYCLE_DIR not exist, fail to postproc \n");
    exit;
}
#2). wait for 20* file finished
$finaldate=&tool_date12_add("${THIS_CYCLE}00", 24, "hour");
&wait_hydro_run($CYCLE_DIR, $finaldate, 12, 30);

#cp to workdir
system("test -d $workdir/cycledata || mkdir -p $workdir/cycledata");
if ( -e "$workdir/cycledata/flag.copy") {
    print("hydro data already copied, skip \n");
}else{
    print("to copy CYCLE_DATA to workdir");
    chdir("$workdir/cycledata");
    system("ln -sf $CYCLE_DIR/forcing .");
    system("cp -r $CYCLE_DIR/20* $workdir/cycledata/ && touch $workdir/cycledata/flag.copy");
}

#plot
#@plots=("precp", "tiles", "evapor", "streamflow_TG", "streamflow_SZ", "streamflow_GL", "streamflow_D4", "timeseries");
@plots=("precp", "tiles", "evapor", "streamflow_TG", "streamflow_GL", "timeseries");
for $plot (@plots) {
    print((/"plot: $plot"/))
    if($plot eq "precp") {
        $cmd="bash $HYDRO_ROOT/script/run_plot_precp_SZMB_alldom.sh $HYDRO_ROOT $workdir/cycledata $workdir/precp $$WEB_DIR $THIS_CYCLE >& $LOG_DIR/log.precp";
        print($cmd."\n");
        system($cmd);
    }
    if($plot eq "tiles") {
        $cmd="bash $HYDRO_ROOT/script/run_plot_tiles_SZMB_alldom.sh $HYDRO_ROOT $workdir/cycledata $workdir/tiles $$WEB_DIR $THIS_CYCLE >& $LOG_DIR/log.tiles";
        print($cmd."\n");
        system($cmd);
    }
    if($plot eq "evapor") {
        $cmd="bash $HYDRO_ROOT/script/run_plot_evap_SZMB_alldom.sh $HYDRO_ROOT $workdir/cycledata $workdir/evapor $$WEB_DIR $THIS_CYCLE >& $LOG_DIR/log.evapor";
        print($cmd."\n");
        system($cmd);
    }
    if($plot =~ /streamflow/){
        ($temp, $dom)=split(/_/, $plot);
        $cmd="bash $HYDRO_ROOT/script/run_plot_streamflow_SZMB_$dom.sh $HYDRO_ROOT $workdir/cycledata $workdir/streamflow $$WEB_DIR $THIS_CYCLE >& $LOG_DIR/log.streamflow_$dom";
        print($cmd."\n");
        system($cmd);
    }
    if($plot eq "timeseries"){
        $cmd="bash $HYDRO_ROOT/script/run_plot_TimeSeries_SZMB.sh $HYDRO_ROOT $workdir/cycledata $workdir/timeseries $$WEB_DIR $THIS_CYCLE >& $LOG_DIR/log.timeseries";
        print($cmd."\n");
        system($cmd);
    }
    print("===================================\n");
}




sub wait_hydro_run(){
    my ($dir_hydro_run, $expected_date, $max_wait, $wait_sec)=@_;
    $iwait=0;
    $waitfile="$dir_hydro_run/$expected_date.RTOUT_DOMAIN1";
    $lastfile="";
    while ($iwait <= $max_wait) { 
        if ( -e $waitfile) {
            sleep(5);
            print("$waitfile is finished, jump out of waiting --\n");
            return;
        }
        $iwait++;
        print("iwait=$iwait, sleep $wait_sec..\n");
        sleep($wait_sec);
        @files=`ls $dir_hydro_run/*.RTOUT_DOMAIN1`;
        if ( scalar(@files) > 0){
            sort @files;
            $last=scalar(@files);
            $lastfilex=$files[$last-1];
            chomp $lastfilex;
            if($lastfilex ne $lastfile){
                $iwait=0;
                $lastfile=$lastfilex;
            }
        }
    }
}
        

        






load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "HYDRO_LIB.ncl"
load "ncl_future_func.ncl"
load "convert_and_copyout_forTS.ncl"
; to plot averaged sfchead on each of lonlats with a half_buffer local area
; one node one plot; 
; input: pt_lonlats_list (format: lon1,lat1;lon2,lat2;...), specify location of points
;        pt_names_list (format: name_pt1,name_pt2,..), specify short names (in png file name) of points
;        pt_titles_list (format: title_pt1,title_pt2,..), specify titles (appear in png figure) of points
;        half_buffer (e.g. 2, means 5*5=25), for averaging
;        file_pattern: to ls
; optional: *start_date10, *end_date10 (the plotting xcoord min/max)
;           *lonlats_name_list (used to name png/title/etc., instead of nodeidx)
;           *ymax (default 1000 mm) 
;           *copydir_list (for realtime)
;           *cycle_date10 (YYYYMMDDHH cycle)
;           *data_outfile_prefix (to save time-series data in ${data_outfile_prefix}_nodeXX.csv)
; sishen, 201803017

begin
    all_input_vars=(/"pt_lonlats_list", "pt_names_list", "pt_titles_list", "half_buffer", "file_pattern"/)
    if(.not. all(isvar(all_input_vars))) then
        print((/"Error: need 5 input_var from cmd line arguments: "/))
        print((/"-- pt_lonlats_list: separated by comma and semicolon, e.g. lon1,lat1;lon2,lat2"/))
        print((/"-- pt_names_list: separated by comma, e.g., SZSK,XLSK"/))
        print((/"-- pt_titles_list: separated by comma, e.g., ShenZhen SK,XiLi SK"/))
        print((/"-- half_buffer: a integer (>=0), to specify the area to average for each point, e.g. 2 means 5x5 averaging"/))
        print((/"-- file_pattern: input_file_pattern_to_ls"/))
        exit
    end if
    pt_lonlats=str_split(pt_lonlats_list, ";")
    npt=dimsizes(pt_lonlats)
    pt_lonlats_2d=new((/npt, 2/), "float")
    do i=0, npt-1
        pt_lonlats_2d(i,:) = tofloat(str_split(pt_lonlats(i), ","))
    end do
    pt_names=str_split(pt_names_list, ",")
    pt_titles=str_split(pt_titles_list, ",")
    if(half_buffer .lt. 0) then
        print((/"Error, half_buffer should be integer and >= 0"/))
        exit
    else
        box_size=2*half_buffer+1
        print((/"You select half_buffer = "+half_buffer+", that is "+box_size+"*"+box_size+" box averging"/))
    end if
    files=systemfunc("ls -1 "+file_pattern)
    nfile=dimsizes(files)
    if(nfile .le. 1) then
        print((/"nfile should at least 2"/))
        exit
    end if
    if(.not. isvar("start_date10")) then
        start_date10=str_substr(basename(files(0)), 0, 9)
    end if
    if(.not. isvar("end_date10")) then
        end_date10=str_substr(basename(files(nfile-1)), 0, 9)
    end if
    if(.not. isvar("ymax")) then
        ymax=1000
    end if
   if(.not. isvar("copydir_list")) then
       copydirs=(/""/)
   else
       copydirs=str_split(copydir_list, ",")
    end if
    if(isvar("copydir_list") .and. .not. isvar("cycle_date10")) then
        print((/"Error, since you pass copydir_list, you should pass cycle_date10 as well"/))
        exit
    end if
    if(isvar("data_outfile_prefix")) then
        print((/"Log: you will write data to "+data_outfile_prefix +"*.csv"/))
    end if
    ;read 2d
    data2d=read_point_sfchead(files, pt_lonlats_2d(:,0), pt_lonlats_2d(:,1), half_buffer)
    if(max(data2d) .gt. ymax) then
        print((/"Warning: max(data2d)="+sprintf("%f", max(data2d))+", exceed ymax"/))
    else
        print((/"max(data2d)="+sprintf("%f", max(data2d))/))
    end if
    ;plot TS
    do ipt=0, npt-1
        fig_name= "sfchead_ts_pt"+pt_names(ipt)
        wks=gsn_open_wks("png",fig_name)
        res=True
        res@xyLineColor= "blue"
        res@xyLineThicknessF = 5.0
        res@xyDashPattern = 0
        res@tiMainString = "Surface Head TimeSeries  (mm)"
        res@gsnLeftString= pt_titles(ipt) + sprintf("(%6.2f,",pt_lonlats_2d(ipt,0))+sprintf("%5.2f)",pt_lonlats_2d(ipt,1))
        res@gsnFrame=False
        res@gsnDraw=False
        res@vpXF=0.15
        res@trYMaxF = ymax
        res@trYMinF = 0
    ;    res@vpYF=0.1
        res@vpWidthF = 0.7
        res@vpHeightF = 0.5
        ; 
        hour_start=date14_scalar_cd_inv_calendar(start_date10+"0000", "hours since 1970-01-01 00:00:00", 0)
        hour_end=date14_scalar_cd_inv_calendar(end_date10+"0000", "hours since 1970-01-01 00:00:00", 0)
        all_hours=date14_1darr_cd_inv_calendar(data2d@str_dt+"0000", "hours since 1970-01-01 00:00:00", 0)
        idx=ind(all_hours .le. hour_end .and. all_hours .ge. hour_start)
        data2dx=new((/nfile, 1/), "float")
        data2dx(:,0)=data2d(:,ipt)
        copy_VarMeta(data2d, data2dx)
        if(isvar("cycle_date10")) then ; to add a red point marker in X axis
            mkres=True
            mkres@gsMarkerColor = "thistle3"
            mkres@gsMarkerIndex = 16
            mkres@gsMarkerSizeF = 0.02
            plot=plot_ts_lines_withDateMarker(wks, data2dx@str_dt(idx), data2dx(idx,:), res, cycle_date10, mkres)
        else
            plot=plot_ts_lines(wks, data2dx@str_dt(idx), data2dx(idx,:), res)
        end if
        draw(plot)
        frame(wks)
        delete(wks)
        convert_and_copyout_forTS(fig_name+".png", copydirs, cycle_date10)
        ;; write out data to csv file
        if(isvar("data_outfile_prefix")) then
            outfile=data_outfile_prefix+"_pt"+pt_names(ipt)+".csv"
            boxsize=2*half_buffer+1
            var_titles=(/"surface head; "+pt_titles(ipt)+"; "+pt_lonlats(ipt)+"; average boxsize:"+boxsize /)
            writeout_data(data2dx@str_dt(idx), data2dx(idx,:), var_titles, outfile)
        end if
        delete(data2dx)
    end do
end

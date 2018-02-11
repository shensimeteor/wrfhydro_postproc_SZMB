load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
; plot: area_sum_sfchead_in m3, accumulated
; input: 
; sishen, 20170823

undef("basename"); remove dir parts of a path
function basename(fileordir)
local base
begin
    base=systemfunc("basename "+fileordir)
    return(base)
end


undef("read_stats_file")
;ncol is number of line to draw (actual n_col = ncol+1)
function read_stats_file(filename:string, ncol:integer)
local data2d, data2dx
begin
    data2dx=readAsciiTable(filename, ncol+1, "double", 1)
    data2d=tofloat(data2dx(:,1:))
    data2d@str_dt=tostring(tointeger(data2dx(:,0)))
    data2d@missing_value=-999.0
    data2d@_FillValue=-999.0
    return(data2d)
end


undef("read_nodes_streamflow")
;return data2d, data2d@str_dt (in format of date10)
function read_nodes_streamflow(files: string, nodes: numeric)
local data2d,nfile,nnode,ifile,str_dt10,chartemp,fbasename,f
begin   
    nfile=dimsizes(files)
    nnode=dimsizes(nodes)
    data2d=new((/nfile, nnode/), "float")
    str_dt10=new((/nfile/), "string")
    do ifile=0,nfile-1
        f=addfile(files(ifile)+".nc", "r")
        data2d(ifile,:)=f->streamflow(nodes)
        fbasename=basename(files(ifile))
        chartemp=stringtochar(fbasename)
        str_dt10(ifile)=chartostring(chartemp(0:9))
    end do
    data2d@str_dt=str_dt10
    return(data2d)
end

undef("read_area_sum_precp")
;return data2d(nfile, n_area), in unit: m^3/s, data2d@str_dt
; dx,dy: distance of grid (in km)
function read_area_sum_precp(files: string, area_idx_files: string, dx:numeric, dy:numeric)
local data2d
begin
    nfile=dimsizes(files)
    narea=dimsizes(area_idx_files)
    data2d=new((/nfile, narea/), "float")
    data2d=0
    str_dt10=new((/nfile/), "string")
    do ifile=0, nfile-1
        f=addfile(files(ifile)+".nc", "r")
        rainrate=f->RAINRATE(0,:,:)
        fbasename=basename(files(ifile))
        chartemp=stringtochar(fbasename)
        str_dt10(ifile)=chartostring(chartemp(0:9))
        do iarea=0, narea-1
            idx1d=asciiread(area_idx_files(iarea), -1, "integer")
            npt=dimsizes(idx1d)/2
            ptidx=onedtond(idx1d, (/npt,2/))
            do ipt=0, npt-1
                data2d(ifile, iarea) = tofloat(rainrate(ptidx(ipt,1), ptidx(ipt,0))) + data2d(ifile, iarea)
            end do
            delete(idx1d)
            delete(ptidx)
        end do
    end do
    data2d = data2d * 1000 * dx * dy
    data2d@str_dt=str_dt10
    return(data2d)
end

undef("read_area_sum_sfchead")
;return data2d(nfile, n_area), in unit: m^3, data2d@str_dt, dx, dy: unit: m
; dx,dy: distance of grid (in km)
function read_area_sum_sfchead(files: string, area_idx_files: string, dx:numeric, dy:numeric)
local data2d
begin
    nfile=dimsizes(files)
    narea=dimsizes(area_idx_files)
    data2d=new((/nfile, narea/), "float")
    data2d=0
    str_dt10=new((/nfile/), "string")
    do ifile=0, nfile-1
        f=addfile(files(ifile)+".nc", "r")
        sfchead=f->SFCHEADSUBRT(0,:,:)
        fbasename=basename(files(ifile))
        chartemp=stringtochar(fbasename)
        str_dt10(ifile)=chartostring(chartemp(0:9))
        do iarea=0, narea-1
            idx1d=asciiread(area_idx_files(iarea), -1, "integer")
            npt=dimsizes(idx1d)/2
            ptidx=onedtond(idx1d, (/npt,2/))
            do ipt=0, npt-1
                data2d(ifile, iarea) = tofloat(sfchead(ptidx(ipt,1), ptidx(ipt,0))) + data2d(ifile, iarea)
            end do
            delete(idx1d)
            delete(ptidx)
        end do
    end do
    data2d = data2d /1000 * dx * dy
    data2d@str_dt=str_dt10
    return(data2d)
end

undef("date14_1darr_cd_inv_calendar")
;a variant of cd_inv_calendar
function date14_1darr_cd_inv_calendar(date14: string, units: string, opt:integer)
local char_dt, x_year, x_month, x_day, x_hour, x_minute, x_second, time
begin
    char_dt=stringtochar(date14)
    x_year=tointeger(chartostring(char_dt(:,0:3)))
    x_month=tointeger(chartostring(char_dt(:,4:5)))
    x_day=tointeger(chartostring(char_dt(:,6:7)))
    x_hour=tointeger(chartostring(char_dt(:,8:9)))
    x_minute=tointeger(chartostring(char_dt(:,10:11)))
    x_second=tointeger(chartostring(char_dt(:,12:13)))
    time=cd_inv_calendar(x_year, x_month, x_day, x_hour, x_minute, x_second, units, opt)
    return(time)    
end

undef("date14_scalar_cd_inv_calendar")
;a variant of cd_inv_calendar
function date14_scalar_cd_inv_calendar(date14: string, units: string, opt:integer)
local char_dt, x_year, x_month, x_day, x_hour, x_minute, x_second, time
begin
    char_dt=stringtochar(date14)
    x_year=tointeger(chartostring(char_dt(0:3)))
    x_month=tointeger(chartostring(char_dt(4:5)))
    x_day=tointeger(chartostring(char_dt(6:7)))
    x_hour=tointeger(chartostring(char_dt(8:9)))
    x_minute=tointeger(chartostring(char_dt(10:11)))
    x_second=tointeger(chartostring(char_dt(12:13)))
    time=cd_inv_calendar(x_year, x_month, x_day, x_hour, x_minute, x_second, units, opt)
    return(time)    
end
    

undef("plot_ts_lines")
function plot_ts_lines(wks:graphic, str_dt:string, stats2d:numeric, res:logical)
local char_dt, x_year, x_month, x_day, x_hour, minute, second, dt_unit, time_to_plot, day_to_plot, \
    labels_to_plot, idx_label
begin
    char_dt=stringtochar(str_dt)
    ;define input x's datetime
    x_year=chartostring(char_dt(:,0:3))
    x_month=chartostring(char_dt(:,4:5))
    x_day=chartostring(char_dt(:,6:7))
    x_hour=chartostring(char_dt(:,8:9))
    minute=x_hour
    minute=0
    second=minute
    dt_unit="hours since "+x_year(0)+"-"+x_month(0)+"-"+x_day(0)+" "+x_hour(0)+":00:00"
    xtime=cd_inv_calendar(tointeger(x_year), tointeger(x_month), tointeger(x_day), tointeger(x_hour), tointeger(minute), tointeger(second), dt_unit, 0); 
    ;define xcoord's datetime
    all_dt_start=tointeger(min(xtime))
    all_dt_end=tointeger(max(xtime))
    all_date_coord = ispan(all_dt_start, all_dt_end, 1)
    all_date_coord@units = dt_unit
    all_date_string      = ut_calendar(all_date_coord,-3)
    all_dates_char  =  stringtochar(sprinti("%0.10i", all_date_string))
    all_year        =  chartostring(all_dates_char(:,0:3))
    all_month       =  chartostring(all_dates_char(:,4:5))
    all_day         =  chartostring(all_dates_char(:,6:7))
    all_hour        =  chartostring(all_dates_char(:,8:9))
    day_to_plot= where(all_hour .eq. "00" .OR. all_hour .eq. "12", all_month+"/"+all_day,"")
    labels_to_plot = all_hour+":00~C~"+day_to_plot
    idx_label=ind(all_hour .eq. "00" .or. all_hour .eq. "06" .or. all_hour .eq. "12" .or. all_hour .eq. "18")

    res@trXMinF=min(xtime)
    res@trXMaxF=max(xtime)
    res@tmLabelAutoStride           = True
    res@tmXMajorGrid                = True
    res@tmXMajorGridThicknessF      = 0.9
    res@tmXMajorGridLineDashPattern = 2
    res@tmXMajorGridLineColor       = "gray80"
    res@tmXBMode                    = "Explicit"
    res@tmXBValues                  = all_date_coord(idx_label)
    res@tmXBLabels                  = labels_to_plot(idx_label)
    res@tmXBMinorValues             = all_date_coord
    res@tmXBLabelFontHeightF   =    0.015
    res@tmYLLabelFontHeightF   =    0.015
    res@tmYROn                      = True
    res@tmYMajorGrid                = True    
    res@tmYMajorGridThicknessF      = 0.9    
    res@tmYMajorGridLineDashPattern = 2    
    res@tmYMajorGridLineColor = "gray80"
    plot = gsn_csm_xy (wks,xtime,transpose(stats2d),res)
    return(plot)
end

begin
   
    all_input_vars=(/"area_sum_sfchd_file", "accu_hour_list", "colors_list","sfchdfile_pattern"/)
    if(.not. all(isvar(all_input_vars))) then
        print((/"Error: need 4 input_var from cmd line arguments: "/))
        print((/"-- area_sum_sfchd_file: yxidx_inside_hires_area_file"/))
        print((/"-- accu_hour_list"/))
        print((/"-- colors_list .."/))
        print((/"-- sfchdfile_pattern .."/))
        print((/"-- optional: start_date10, end_date10 "/))
    end if
;    in_nodes_idx=tointeger(str_split(in_nodes_idx_list,","))
;    out_nodes_idx=tointeger(str_split(out_nodes_idx_list, ","))
;    n_in=dimsizes(in_nodes_idx)
;    n_out=dimsizes(out_nodes_idx)
    accu_hours=tointeger(str_split(accu_hour_list, ","))
    colors=str_split(colors_list, ",")

    sfchdfiles=systemfunc("ls -1 "+sfchdfile_pattern)
    nfile=dimsizes(sfchdfiles)
    if(.not. isvar("start_date10")) then
        start_date10=str_substr(basename(sfchdfiles(0)), 0, 9)
    end if
    if(.not. isvar("end_date10")) then
        end_date10=str_substr(basename(sfchdfiles(nfile-1)), 0, 9)
    end if
    nline=dimsizes(colors)
    ;read 2d area sfchd (nfile,1)
    sfchd_data2d=read_area_sum_sfchead(sfchdfiles, (/area_sum_sfchd_file/), 100, 100)
    ;calc accu_hour accumulated sfchd water by sfchd_data2d
    sfchd_data2dx=new((/nfile, nline/), "float")
    sfchd_data2dx@_FillValue=-999.
    miss=-999.
    do j=0, nline-1
        hour=accu_hours(j)
        do i=0,nfile-1
            if(i-hour .lt. 0) then
                sfchd_data2dx(i,j) = miss
            else
                sfchd_data2dx(i,j) = sfchd_data2d(i,0) - sfchd_data2d(i-hour,0)
            end if
        end do
    end do
    sfchd_data2dx = sfchd_data2dx /3600 ; m3/s

    ;combine them
    str_dt=sfchd_data2d@str_dt
    ;plot 
    wks=gsn_open_wks("png", "SfcHead_Accu")
    ;plot in/out two lines
    res=True
    res@xyLineColors= colors
    res@xyLineThicknessF = 5.0
    res@xyDashPattern = 0
    res@tiMainString = "Accumulated SfcHead Water(m~S~3~N~)"
    res@gsnFrame=False
    res@gsnDraw=False
    res@vpXF=0.15
;    res@vpYF=0.1
;    res@vpWidthF = 0.7
;    res@vpHeightF = 0.35
    
    hour_start=date14_scalar_cd_inv_calendar(start_date10+"0000", "hours since 1970-01-01 00:00:00", 0)
    hour_end=date14_scalar_cd_inv_calendar(end_date10+"0000", "hours since 1970-01-01 00:00:00", 0)
    all_hours=date14_1darr_cd_inv_calendar(str_dt+"0000", "hours since 1970-01-01 00:00:00", 0)
    idx=ind(all_hours .le. hour_end .and. all_hours .ge. hour_start)
    plot=plot_ts_lines(wks, str_dt(idx), sfchd_data2dx(idx,:), res)
;    ;plot_budget
;    res2=True
;    res2@xyLineColors = (/"black"/)
;    res2@xyLineThicknessF = 5.0
;    res2@tiMainString = "Budget (In - Out) Streamflow (m~S~3~N~ s~S~-1~N~) "
;    res2@gsnRightString = "sum budget"+sprintf("(%6.2f)", total_in-total_out)
;    res2@gsnRightStringFontHeightF = 0.02
;    res2@gsnFrame=False
;    res2@gsnDraw=False
;    res2@vpXF=0.15
;    res2@vpWidthF = 0.7
;    res2@vpHeightF = 0.35
;    plot2=plot_ts_lines(wks, str_dt, plot_budget, res2)
    ;add legend
    lgres                    = True
    lgres@lgLineColors       = colors
    lgres@lgLineThicknessF   = 3.
    lgres@lgLabelFontHeightF = 0.15
    lgres@vpWidthF           = 0.12              
    lgres@vpHeightF          = 0.04 * nline
    lgres@lgPerimOn          = True               
    zeros=new((/nline/), "float")
    zeros=0
    lgres@lgDashIndexes        = zeros
    lgres@lgPerimFillColor   = 0
    lgres@lgPerimFill        = 0
    legend_lab=new((/nline/), "string")
    legend_lab = tostring(accu_hours)+" hr"
    print(legend_lab)
    gsn_legend_ndc(wks,nline,legend_lab,0.87,0.75,lgres)
    draw(plot)
    frame(wks)
    ;panel
;    resP=True
;    resP@gsnMaximize=True
;    resP@gsnPanelDebug  = True
;    gsn_panel(wks, (/plot, plot2/), (/2,1/), resP)
    delete(wks)
end

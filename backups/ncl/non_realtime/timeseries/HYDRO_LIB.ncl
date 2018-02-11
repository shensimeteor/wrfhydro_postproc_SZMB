;; ncl library for WRF-Hydro ploting

; ---------------------------------------------
; common utilities
; ---------------------------------------------
undef("basename"); remove dir parts of a path
function basename(fileordir) ;{{{
local base
begin
    base=systemfunc("basename "+fileordir)
    return(base)
end ;}}}

undef("str_substr")
;ibeg/iend can be negative, e.g. -1 means last char
function str_substr(str:string, ibeg:integer, iend:integer) ; {{{
local chars, len, idx_beg, idx_end, substr
begin
    chars=stringtochar(str)
    len=strlen(str)
    if(ibeg .ge. 0) then
        idx_beg=ibeg
    else
        idx_beg=len+ibeg
    end if
    if(iend .ge. 0) then
        idx_end=iend
    else
        idx_end=len+iend
    end if
    if(idx_end .lt. idx_beg) then
        substr=""
    else
        substr=chartostring(chars(idx_beg:idx_end))
    end if
    return(substr)
end ;}}}

undef("date14_1darr_cd_inv_calendar") ;date14 format to inv_calendar, for 1d array
;a variant of cd_inv_calendar
function date14_1darr_cd_inv_calendar(date14: string, units: string, opt:integer) ;{{{
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
end ;}}}

undef("date14_scalar_cd_inv_calendar") ;date14 format to inv_calendar, for scalar
;a variant of cd_inv_calendar
function date14_scalar_cd_inv_calendar(date14: string, units: string, opt:integer) ;{{{
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
end ;}}}


; ---------------------------------------------
; read
; ---------------------------------------------
undef("read_stats_file") ; for txt column-format
;ncol is number of line to draw (actual n_col = ncol+1)
function read_stats_file(filename:string, ncol:integer) ;{{{
local data2d, data2dx
begin
    data2dx=readAsciiTable(filename, ncol+1, "double", 1)
    data2d=tofloat(data2dx(:,1:))
    data2d@str_dt=tostring(tointeger(data2dx(:,0)))
    data2d@missing_value=-999.0
    data2d@_FillValue=-999.0
    return(data2d)
end ;}}}

undef("read_nodes_streamflow")
;return data2d, data2d@str_dt (in format of date10)
function read_nodes_streamflow(files: string, nodes: numeric) ;{{{
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
end ;}}}

undef("read_accu_streamflow") ; read last nhours accu. water (10^3 m3)
;return data3d(nfile,nnode,nhour), data3d@str_dt, data3d@missing_value, units: 10^3 m3
function read_accu_streamflow(files: string, nodes: numeric, accu_hours) ;{{{
local nfile, nnode, nhour, data3d, str_dt10, data2d_streamflow, missing, \
      f, fbasename, chartemp, ifile, ihour, hour
begin
    nfile=dimsizes(files)
    nnode=dimsizes(nodes)
    nhour=dimsizes(accu_hours)
    data3d=new((/nfile, nnode, nhour/), "float")
    str_dt10=new((/nfile/), "string")
    data2d_streamflow=new((/nfile, nnode/), "float")
    missing= -999.
    ;read data2d_streamflow (every file/ every node's streamflow)
    do ifile=0,nfile-1
        f=addfile(files(ifile)+".nc", "r")
        data2d_streamflow(ifile,:)=f->streamflow(nodes)
        fbasename=basename(files(ifile))
        chartemp=stringtochar(fbasename)
        str_dt10(ifile)=chartostring(chartemp(0:9))
    end do
    ;accumulate
    do ifile=0,nfile-1
        do ihour=0,nhour-1
            hour=accu_hours(ihour)
            if( ifile - hour + 1 .lt. 0) then
                data3d(ifile, :, ihour) = missing
            else
                data3d(ifile, :, ihour) = dim_sum_n(data2d_streamflow(ifile-hour+1:ifile,:), 0) * 3600 / 1000
                data3d(ifile, :, ihour) = where(data3d(ifile, :, ihour) .lt. 0, 0, data3d(ifile,:,ihour))
            end if
        end do
    end do
    data3d@missing_value=missing
    data3d@_FillValue=missing
    data3d@str_dt=str_dt10
    return(data3d)
end ;}}}

undef("read_area_sum_precp") ; sum of precp (m3/s), using area_idx_files
;return data2d(nfile, n_area), in unit: m^3/s, data2d@str_dt
; dx,dy: distance of grid (in km)
function read_area_sum_precp(files: string, area_idx_files: string, dx:numeric, dy:numeric) ;{{{
local data2d, nfile, narea, str_dt10, ifile, f, rainrate, fbasename, chartemp, iarea, idx1d, npt, ptidx, ipt
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
end ;}}}

undef("read_area_sum_precp_accu") ; accu. sum of precp water (10^3 m3), using area_idx_files
;return data3d(nfile, n_area, nhour), in unit: 10^3 m3, data3d@str_dt
; dx,dy: distance of grid (in km)
function read_area_sum_precp_accu(files: string, area_idx_files: string, accu_hours:numeric, dx:numeric, dy:numeric) ;{{{
local data2d, missing, nhour, narea, nfile, data3d, ifile, ihour, hour
begin
    data2d=read_area_sum_precp(files, area_idx_files, dx, dy)
    missing= -999.
    nhour=dimsizes(accu_hours)
    narea=dimsizes(area_idx_files)
    nfile=dimsizes(files)
    data3d=new((/nfile, narea, nhour/), "float")
    do ifile=0,nfile-1
        do ihour=0, nhour-1
            hour=accu_hours(ihour)
            if(ifile - hour + 1 .lt. 0) then
                data3d(ifile, :, ihour) = missing
            else
                data3d(ifile, :, ihour) = dim_sum_n(data2d(ifile-hour+1:ifile,:), 0) * 3600 / 1000
                data3d(ifile, :, ihour) = where(data3d(ifile, :, ihour) .lt. 0, 0, data3d(ifile,:,ihour))
            end if
        end do
    end do
    data3d@missing_value=missing
    data3d@_FillValue=missing
    data3d@str_dt=data2d@str_dt
    return(data3d)
end ;}}}

undef("read_area_sum_sfchead"); sum of 
;return data2d(nfile, n_area), in unit: m^3, data2d@str_dt, dx, dy: unit: m
; dx,dy: distance of grid (in km)
function read_area_sum_sfchead(files: string, area_idx_files: string, dx:numeric, dy:numeric) ;{{{
local data2d, nfile, narea, ifile, str_dt10, sfchead, f, fbasename, chartemp, idx1d, npt, ptidx
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
end ;}}}

undef("read_area_sum_sfchead_accu"); from sfchead, get accumulation, i.e. x(t,hour)= sfchead(t) - sfchead(t-hour)
;return data3d(nfile, n_area, nhour), in unit: 10^3 m3, data3d@str_dt, dx, dy, unit:m
function read_area_sum_sfchead_accu(files: string, area_idx_files: string, accu_hours:numeric, dx:numeric, dy:numeric) ;{{{
local data2d,missing,narea,nfile,data3d,ifile,ihour,hour
begin
    data2d=read_area_sum_sfchead(files, area_idx_files, dx, dy)
    missing= -999.
    nhour=dimsizes(accu_hours)
    narea=dimsizes(area_idx_files)
    nfile=dimsizes(files)
    data3d=new((/nfile, narea, nhour/), "float")
    do ifile=0,nfile-1
        do ihour=0, nhour-1
            hour=accu_hours(ihour)
            if(ifile - hour  .lt. 0) then
                data3d(ifile, :, ihour) = missing
            else
                data3d(ifile, :, ihour) = (data2d(ifile,:) - data2d(ifile-hour,:)) / 1000
            end if
        end do
    end do
    data3d@missing_value=missing
    data3d@_FillValue=missing
    data3d@str_dt=data2d@str_dt
    return(data3d)
end ;}}}

undef("read_area_sum_soilm_conc") ; read average soilm concentration (m3/m3) for 4 layers
;return data3d(nfile, narea, nlayer+1: 1 for total), unit:  m3/m3
function read_area_sum_soilm_conc(files: string, area_idx_files: string) ;{{{
local data3d, nfile, narea, ifile, str_dt10, soilm, f, fbasename, chartemp, idx1d, npt, ptidx
begin 
    nfile=dimsizes(files)
    narea=dimsizes(area_idx_files)
    data3d=new((/nfile, narea, 4/), "float")
    data3d=0
    str_dt10=new((/nfile/), "string")
    do ifile=0, nfile-1
        f=addfile(files(ifile)+".nc", "r")
        sfchead=f->SFCHEADSUBRT(0,:,:)
        soilm1 = f->$"SOIL_M 1"$
        soilm2 = f->$"SOIL_M 2"$
        soilm3 = f->$"SOIL_M 3"$
        soilm4 = f->$"SOIL_M 4"$
        fbasename=basename(files(ifile))
        chartemp=stringtochar(fbasename)
        str_dt10(ifile)=chartostring(chartemp(0:9))
        do iarea=0, narea-1
            idx1d=asciiread(area_idx_files(iarea), -1, "integer")
            npt=dimsizes(idx1d)/2
            ptidx=onedtond(idx1d, (/npt,2/))
            do ipt=0, npt-1
                data3d(ifile, iarea, 0) =  tofloat(soilm1(0, ptidx(ipt,1), ptidx(ipt,0))) + data3d(ifile, iarea, 0)
                data3d(ifile, iarea, 1) =  tofloat(soilm2(0, ptidx(ipt,1), ptidx(ipt,0))) + data3d(ifile, iarea, 1)
                data3d(ifile, iarea, 2) =  tofloat(soilm3(0, ptidx(ipt,1), ptidx(ipt,0))) + data3d(ifile, iarea, 2)
                data3d(ifile, iarea, 3) =  tofloat(soilm4(0, ptidx(ipt,1), ptidx(ipt,0))) + data3d(ifile, iarea, 3)
            end do
            data3d(ifile, iarea, :) = data3d(ifile, iarea, :) / npt
            delete(idx1d)
            delete(ptidx)
        end do
    end do
    data3d = data3d
    data3d@str_dt=str_dt10
    return(data3d)
end ;}}}


undef("read_area_sum_soilm")
;return data3d(nfile, narea, nlayer+1: 1 for total), unit:  m3, dx,dy: m
function read_area_sum_soilm(files: string, area_idx_files: string, dx:numeric, dy:numeric) ;{{{
local data3d, nfile, narea, ifile, str_dt10, soilm, f, fbasename, chartemp, idx1d, npt, ptidx
begin 
    nfile=dimsizes(files)
    narea=dimsizes(area_idx_files)
    data3d=new((/nfile, narea, 5/), "float")
    data3d=0
    str_dt10=new((/nfile/), "string")
    layer_depth=(/0.1, 0.4, 1, 2/)
    layer_thick=(/0.2, 0.4, 0.8, 0.6/)
    do ifile=0, nfile-1
        f=addfile(files(ifile)+".nc", "r")
        sfchead=f->SFCHEADSUBRT(0,:,:)
        soilm1 = f->$"SOIL_M 1"$
        soilm2 = f->$"SOIL_M 2"$
        soilm3 = f->$"SOIL_M 3"$
        soilm4 = f->$"SOIL_M 4"$
        fbasename=basename(files(ifile))
        chartemp=stringtochar(fbasename)
        str_dt10(ifile)=chartostring(chartemp(0:9))
        do iarea=0, narea-1
            idx1d=asciiread(area_idx_files(iarea), -1, "integer")
            npt=dimsizes(idx1d)/2
            ptidx=onedtond(idx1d, (/npt,2/))
            do ipt=0, npt-1
                data3d(ifile, iarea, 0) =  tofloat(soilm1(0, ptidx(ipt,1), ptidx(ipt,0))) * layer_thick(0) + data3d(ifile, iarea, 0)
                data3d(ifile, iarea, 1) =  tofloat(soilm2(0, ptidx(ipt,1), ptidx(ipt,0))) * layer_thick(1) + data3d(ifile, iarea, 1)
                data3d(ifile, iarea, 2) =  tofloat(soilm3(0, ptidx(ipt,1), ptidx(ipt,0))) * layer_thick(2) + data3d(ifile, iarea, 2)
                data3d(ifile, iarea, 3) =  tofloat(soilm4(0, ptidx(ipt,1), ptidx(ipt,0))) * layer_thick(3) + data3d(ifile, iarea, 3)
            end do
            delete(idx1d)
            delete(ptidx)
        end do
    end do
    data3d(:, :, 4) = dim_sum_n(data3d(:, :, 0:3), 2)
    data3d = data3d * dx * dy
    data3d@str_dt=str_dt10
    return(data3d)
end ;}}}

undef("read_area_sum_soilm_accu"); unit: 10^3 m3
;return data3d(nfile, n_area, nhour), in unit: 10^3 m3, data3d@str_dt, dx, dy, unit:m
function read_area_sum_soilm_accu(files: string, area_idx_files: string, accu_hours:numeric, dx:numeric, dy:numeric) ;{{{
local data2d,missing,narea,nfile,data3d,ifile,ihour,hour
begin
    data2d=read_area_sum_soilm(files, area_idx_files, dx, dy)
    missing= -999.
    nhour=dimsizes(accu_hours)
    narea=dimsizes(area_idx_files)
    nfile=dimsizes(files)
    data3d=new((/nfile, narea, nhour/), "float")
    do ifile=0,nfile-1
        do ihour=0, nhour-1
            hour=accu_hours(ihour)
            if(ifile - hour  .lt. 0) then
                data3d(ifile, :, ihour) = missing
            else
                data3d(ifile, :, ihour) = (data2d(ifile,:,4) - data2d(ifile-hour,:,4)) / 1000
            end if
        end do
    end do
    data3d@missing_value=missing
    data3d@_FillValue=missing
    data3d@str_dt=data2d@str_dt
    return(data3d)
end ;}}}


undef("read_area_sum_evap") ; sum of evap (m3/s), using area_idx_files
;return data3d(nfile, n_area, 4: ecan, edir, etran, total), in unit: m^3/s, data3d@str_dt
; dx,dy: distance of grid (in km)
function read_area_sum_evap(files: string, area_idx_files: string, dx:numeric, dy:numeric) ;{{{
local data3d, nfile, narea, str_dt10, ifile, f, ecan, edir, etran, fbasename, chartemp, iarea, idx1d, npt, ptidx, ipt
begin
    nfile=dimsizes(files)
    narea=dimsizes(area_idx_files)
    data3d=new((/nfile, narea, 4/), "float")
    data3d=0
    str_dt10=new((/nfile/), "string")
    do ifile=0, nfile-1
        f=addfile(files(ifile)+".nc", "r")
        ecan=f->ECAN(0,:,:) ; kg /m2 /s
        edir=f->EDIR(0,:,:)
        etran=f->ETRAN(0,:,:)
        fbasename=basename(files(ifile))
        chartemp=stringtochar(fbasename)
        str_dt10(ifile)=chartostring(chartemp(0:9))
        do iarea=0, narea-1
            idx1d=asciiread(area_idx_files(iarea), -1, "integer")
            npt=dimsizes(idx1d)/2
            ptidx=onedtond(idx1d, (/npt,2/))
            do ipt=0, npt-1
                data3d(ifile, iarea, 0) = tofloat(ecan(ptidx(ipt,1), ptidx(ipt,0))) + data3d(ifile, iarea, 0)
                data3d(ifile, iarea, 1) = tofloat(edir(ptidx(ipt,1), ptidx(ipt,0))) + data3d(ifile, iarea, 1)
                data3d(ifile, iarea, 2) = tofloat(etran(ptidx(ipt,1), ptidx(ipt,0))) + data3d(ifile, iarea, 2)
            end do
            delete(idx1d)
            delete(ptidx)
        end do
    end do
    data3d(:,:,3) = dim_sum_n(data3d(:,:,0:2), 2)
    data3d = data3d * 1000 * dx * dy ; m3/s
    data3d@str_dt=str_dt10
    return(data3d)
end ;}}}

; ---------------------------------------------
; on ploting
; ---------------------------------------------
undef("plot_ts_lines")
function plot_ts_lines(wks:graphic, str_dt:string, stats2d:numeric, res:logical) ;{{{
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
end ;}}}


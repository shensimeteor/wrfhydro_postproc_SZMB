load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
; to plot streamflow on nodes as TimeSeries, multiple lines represent multiple nodes
; input: nodes_idx_list (=1,2,5,7,); nodes_name_list (=North,East,..): used to label legends
;        color_list (=red,green,..), file_pattern (to ls)
; sishen, 20170822

undef("basename"); remove dir parts of a path
function basename(fileordir)
local base
begin
    base=systemfunc("basename "+fileordir)
    return(base)
end

undef("dirname")
function dirname(fileordir)
local dirnam
begin
    dirnam=systemfunc("dirname "+fileordir)
    return(dirnam)
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
   
    all_input_vars=(/"nodes_idx_list", "nodes_name_list", "color_list", "file_pattern"/)
    if(.not. all(isvar(all_input_vars))) then
        print((/"Error: need 4 input_var from cmd line arguments: "/))
        print((/"-- nodes_idx_list: index_list_separated_by_comma, begin with 0"/))
        print((/"-- nodes_name_list: name_list_separated_by_comma"/))
        print((/"-- color_list: ncl_named_color_list_separated_by_comma"/))
        print((/"-- file_pattern: input_file_pattern_to_ls"/))
        exit
    end if
    nodes_idx=tointeger(str_split(nodes_idx_list,","))
    nodes_names=str_split(nodes_name_list, ",")
    colors=str_split(color_list, ",")
    files=systemfunc("ls -1 "+file_pattern)
    nline=dimsizes(nodes_idx)
    if(.not. all(nline .eq.  (/dimsizes(colors), dimsizes(nodes_names)/)) ) then
        print((/"Error: colors & nodes_idx * nodes_names should be same size"/))
        exit
    end if
    ;read 2d
    data2d=read_nodes_streamflow(files, nodes_idx)
    ;plot TS
    wks=gsn_open_wks("png", "streamflow_ts")
    res=True
    res@xyLineColors= colors
    res@xyLineThicknessF = 5.0
    res@xyDashPattern = 0
    res@tiMainString = "Nodes StreamFlow TimeSeries  (m~S~3~N~ s~S~-1~N~) "
    res@gsnFrame=False
    res@gsnDraw=False
    res@vpXF=0.15
;    res@vpYF=0.1
    res@vpWidthF = 0.7
    res@vpHeightF = 0.5
    plot=plot_ts_lines(wks, data2d@str_dt, data2d, res)
    ;add legend
    lgres                    = True
    lgres@lgLineColors       = colors
    lgres@lgLineThicknessF   = 3.
    lgres@lgLabelFontHeightF = 0.15
    lgres@vpWidthF           = 0.12              
    lgres@vpHeightF          = 0.03*nline
    lgres@lgPerimOn          = True               
    zeros=new((/nline/), "float")
    zeros=0
    lgres@lgDashIndexes        = zeros
    lgres@lgPerimFillColor   = 0
    lgres@lgPerimFill        = 0
    gsn_legend_ndc(wks,nline,nodes_names,0.87,0.75,lgres) 
    draw(plot)
    frame(wks)
    delete(wks)
end

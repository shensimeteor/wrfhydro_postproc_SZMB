load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "HYDRO_LIB.ncl"

begin
   
    all_input_vars=(/"in_nodes_idx_list", "out_nodes_idx_list", "colors_inout_list", \
                     "area_sum_precp_filelist", "area_sum_precp_namelist", "colors_area_list", \
                     "precpfile_pattern", "streamfile_pattern"/)
    if(.not. all(isvar(all_input_vars))) then
        print((/"Error: need 8 input_var from cmd line arguments: "/))
        print((/"-- in_nodes_idx_list: inflow_nodes_index_list_separated_by_comma, begin with 0"/))
        print((/"-- out_nodes_idx_list: outflow_nodes_index_list_separated_by_comma .."/))
        print((/"-- colors_inout_list: colors for inflow/outflow"/))
        print((/"-- streamfile_pattern: stream_input_file_pattern_to_ls"/))
        print((/"-- area_sum_precp_filelist: xyidx_inside_area_file_list_sperated_by_comma"/))
        print((/"-- area_sum_precp_namelist: area_name_list"/))
        print((/"-- colors_area_list: colors for areas"/))
        print((/"-- precpfile_pattern: precp_input_file_pattern_to_ls"/))
        exit
    end if
    in_nodes_idx=tointeger(str_split(in_nodes_idx_list,","))
    out_nodes_idx=tointeger(str_split(out_nodes_idx_list, ","))
    n_in=dimsizes(in_nodes_idx)
    n_out=dimsizes(out_nodes_idx)
    area_idx_files=str_split(area_sum_precp_filelist, ",")
    area_names=str_split(area_sum_precp_namelist,",")
    n_area=dimsizes(area_names)
    if(n_area .ne. dimsizes(area_idx_files)) then
        print((/"Error: area_sum_precp_namelist & area_sum_precp_filelist should be same size"/))
        exit
    end if
    all_colors_list=colors_inout_list+","+colors_area_list
    all_colors=str_split(all_colors_list, ",")

    streamfiles=systemfunc("ls -1 "+streamfile_pattern)
    precpfiles=systemfunc("ls -1 "+precpfile_pattern)
    nfile=dimsizes(precpfiles)
    if(dimsizes(streamfiles) .ne. dimsizes(precpfiles)) then
        print((/"Error: streamfiles & precpfiles should have same size"/))
        exit
    end if
    nline=2+n_area
    ;read 2d streamflow
    n_all=n_in+n_out
    all_nodes_idx=new((/n_all/), "integer")
    all_nodes_idx(0:n_in-1) = in_nodes_idx
    all_nodes_idx(n_in:n_all-1)= out_nodes_idx
    all_data2d=read_nodes_streamflow(streamfiles, all_nodes_idx)
    in_sum=dim_sum_n_Wrap(all_data2d(:, 0:n_in-1), 1)
    out_sum=dim_sum_n_Wrap(all_data2d(:, n_in:n_all-1), 1)
    ;read 2d area precp
    precp_data2d=read_area_sum_precp(precpfiles, area_idx_files, 1, 1)
    ;combine them
    plot_data2d=new((/nfile, nline/), "float")
    plot_data2d(:,0)=in_sum
    plot_data2d(:,1)=out_sum
    plot_data2d(:,2:nline-1)=precp_data2d
    ;calc stats
    total_in=sum(in_sum)
    total_out=sum(out_sum)
    print((/"total_flow_in = "+total_in/))
    print((/"total_flow_out = "+total_out/))
    total_precp=dim_sum_n(precp_data2d,0)
    print((/"total_area_precp =" + str_join(tostring(total_precp), ",")/))
    str_dt=all_data2d@str_dt
    ;plot 
    wks=gsn_open_wks("png", "chaninout_totalprecp")
    ;plot in/out two lines
    res=True
    res@xyLineColors= all_colors
    res@xyLineThicknessF = 5.0
    res@xyDashPattern = 0
    res@tiMainString = "ChannelFlow/Precp Budget  (m~S~3~N~ s~S~-1~N~) "
    strx=str_join(area_names+":"+tostring(total_precp),";")
    res@gsnLeftString = "flowin"+sprintf("(%5.1f)", total_in)+"; flowout"+sprintf("(%5.1f)", total_out)
    res@gsnRightString=strx
    res@gsnRightStringFontHeightF=0.012
    res@gsnLeftStringFontHeightF=0.012
    res@gsnFrame=False
    res@gsnDraw=False
    res@vpXF=0.15
;    res@vpYF=0.1
;    res@vpWidthF = 0.7
;    res@vpHeightF = 0.35
    plot=plot_ts_lines(wks, str_dt, plot_data2d, res)
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
    lgres@lgLineColors       = all_colors
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
    legend_lab(0)="inflow"
    legend_lab(1)="outflow"
    legend_lab(2:nline-1) = area_names
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

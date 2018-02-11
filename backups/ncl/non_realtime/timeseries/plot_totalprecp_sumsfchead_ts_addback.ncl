load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "HYDRO_LIB.ncl"
; plot: area_sum_precp_in_m3/s, area_sum_sfchead_in m3
; input: in_nodes_idx_list (=1,2,5,7,); out_nodes_idx_list; colors_inout_list
;        area_sum_precp_filelist; area_sum_precp_namelist; colors_area_list
;        streamfile_pattern, precpfile_pattern
; sishen, 20170823

begin
   
    all_input_vars=(/"area_sum_precp_filelist", "area_sum_precp_namelist", "colors_precp_list","precpfile_pattern",  \
                     "area_sum_sfchd_filelist", "area_sum_sfchd_namelist", "colors_sfchd_list","sfchdfile_pattern"/)
    if(.not. all(isvar(all_input_vars))) then
        print((/"Error: need 8 input_var from cmd line arguments: "/))
;        print((/"-- in_nodes_idx_list: inflow_nodes_index_list_separated_by_comma, begin with 0"/))
;        print((/"-- out_nodes_idx_list: outflow_nodes_index_list_separated_by_comma .."/))
;        print((/"-- colors_inout_list: colors for inflow/outflow"/))
;        print((/"-- streamfile_pattern: stream_input_file_pattern_to_ls"/))
        print((/"-- area_sum_precp_filelist: xyidx_inside_area_file_list_sperated_by_comma"/))
        print((/"-- area_sum_precp_namelist: area_name_list"/))
        print((/"-- colors_precp_list: colors for areas"/))
        print((/"-- precpfile_pattern: precp_input_file_pattern_to_ls"/))
        print((/"-- area_sum_sfchd_filelist: yxidx_inside_hires_area_file_list_sperated_by_comma"/))
        print((/"-- area_sum_sfchd_namelist .."/))
        print((/"-- colors_sfchd_list .."/))
        print((/"-- sfchdfile_pattern .."/))
    end if
;    in_nodes_idx=tointeger(str_split(in_nodes_idx_list,","))
;    out_nodes_idx=tointeger(str_split(out_nodes_idx_list, ","))
;    n_in=dimsizes(in_nodes_idx)
;    n_out=dimsizes(out_nodes_idx)
    precp_area_idx_files=str_split(area_sum_precp_filelist, ",")
    precp_area_names=str_split(area_sum_precp_namelist,",")
    sfchd_area_idx_files=str_split(area_sum_sfchd_filelist, ",")
    sfchd_area_names=str_split(area_sum_sfchd_namelist,",")
    all_colors_list=colors_precp_list+","+colors_sfchd_list
    all_colors=str_split(all_colors_list, ",")

;    streamfiles=systemfunc("ls -1 "+streamfile_pattern)
    precpfiles=systemfunc("ls -1 "+precpfile_pattern)
    sfchdfiles=systemfunc("ls -1 "+sfchdfile_pattern)
    nfile=dimsizes(precpfiles)
    if(dimsizes(sfchdfiles) .ne. dimsizes(precpfiles)) then
        print((/"Error: sfchdfiles & precpfiles should have same size"/))
        exit
    end if
    nline=dimsizes(all_colors)
    nline_precp=dimsizes(precp_area_names)
    nline_sfchd=dimsizes(sfchd_area_names)
    ;read 2d streamflow
;    n_all=n_in+n_out
;    all_nodes_idx=new((/n_all/), "integer")
;    all_nodes_idx(0:n_in-1) = in_nodes_idx
;    all_nodes_idx(n_in:n_all-1)= out_nodes_idx
;    all_data2d=read_nodes_streamflow(streamfiles, all_nodes_idx)
;    in_sum=dim_sum_n_Wrap(all_data2d(:, 0:n_in-1), 1)
;    out_sum=dim_sum_n_Wrap(all_data2d(:, n_in:n_all-1), 1)
    ;read 2d area precp
    precp_data2d=read_area_sum_precp(precpfiles, precp_area_idx_files, 1, 1)
    ;read 2d area sfchd
    sfchd_data2d=read_area_sum_sfchead(sfchdfiles, sfchd_area_idx_files, 100, 100)
    do i=1,nfile-1
        j=nfile-i
        sfchd_data2d(j,:) = sfchd_data2d(j,:) - sfchd_data2d(j-1,:)
    end do
    sfchd_data2d(0,:)=0
    sfchd_data2d = sfchd_data2d/3600

    ;combine them
    plot_data2d=new((/nfile, nline/), "float")
    plot_data2d(:,0:nline_precp-1) = precp_data2d
    plot_data2d(:,nline_precp:nline-1)=sfchd_data2d
    ;calc stats
    total_precp=dim_sum_n(precp_data2d,0)
    str_dt=precp_data2d@str_dt
    ;plot 
    wks=gsn_open_wks("png", "Precp_and_SfcHead")
    ;plot in/out two lines
    res=True
    res@xyLineColors= all_colors
    res@xyLineThicknessF = 5.0
    res@xyDashPattern = 0
    res@tiMainString = "Precp & SfcHead-Incr. Rate (m~S~3~N~ s~S~-1~N~)"
    strx=str_join(precp_area_names+":"+tostring(total_precp),";")
;    res@gsnRightString=strx
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
    legend_lab(0: nline_precp-1) = "precp:"+precp_area_names
    legend_lab(nline_precp:nline-1) = "sfchd:"+sfchd_area_names
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

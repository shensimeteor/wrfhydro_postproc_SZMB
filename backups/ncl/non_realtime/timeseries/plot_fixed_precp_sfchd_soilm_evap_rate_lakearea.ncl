load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "HYDRO_LIB.ncl"
;; plot rate of sum_precipiation (lake), sum_sfchd_accumulation (lake), sum_soilm_accumlation (lake)
begin
;    precpfile_pattern="*.LDASIN_DOMAIN1"
;    sfchdfile_pattern="*.RTOUT_DOMAIN1"
;    evapfile_pattern="*.LDASOUT_DOMAIN1"
    if(.not. all(isvar((/"precpfile_pattern", "sfchdfile_pattern", "evapfile_pattern"/)))) then
        print((/"Error, you need to prepare precpfile_pattern, sfchdfile_pattern, evapfile_pattern"/))
        exit
    end if
    precpfiles=systemfunc("ls "+precpfile_pattern)
    sfchdfiles=systemfunc("ls "+sfchdfile_pattern)
    evapfiles=systemfunc("ls "+evapfile_pattern)
    nfile=dimsizes(precpfiles)
    if(.not. all(nfile .eq. (/dimsizes(sfchdfiles), dimsizes(evapfiles)/))) 
        print((/"Error, precp/sfchd/evap files number should be same"/))
        exit
    end if
    precp_area_idx_files=(/"idx_inside_TG_lakearea.txt"/)
    sfchd_area_idx_files=(/"hires_idx_inside_TG_lakearea.txt"/)
    evap_area_idx_files=(/"idx_inside_TG_lakearea.txt"/)
    ;read
    precp_data2d=read_area_sum_precp(precpfiles, precp_area_idx_files, 1, 1) ; m3/s
    sfchd_data2d=read_area_sum_sfchead(sfchdfiles, sfchd_area_idx_files, 100, 100) ;  m3
    soilm_data3d=read_area_sum_soilm(sfchdfiles, sfchd_area_idx_files, 100, 100); m3
    do i=1,nfile-1
        j=nfile-i
        sfchd_data2d(j,:) = sfchd_data2d(j,:) - sfchd_data2d(j-1,:)
        soilm_data3d(j,:,:) = soilm_data3d(j,:,:) - soilm_data3d(j-1,:,:)
    end do
    sfchd_data2d(0,:)=sfchd_data2d@_FillValue
    sfchd_data2d = sfchd_data2d/3600
    soilm_data3d(0,:,:) = soilm_data3d@_FillValue
    soilm_data3d = soilm_data3d/3600
    evap_data3d=read_area_sum_evap(evapfiles, evap_area_idx_files, 1, 1); m3/s
    print(dim_max_n(evap_data3d, 0))
    ;plot
    nlines= 4 ; 1 precp, 1 sfchd, 1 all soilm, 1 evap
    plot_data2d=new((/nfile, nlines/), "float")
    plot_data2d(:,0) = precp_data2d(:,0)
    plot_data2d(:,1) = sfchd_data2d(:,0)
    printVarSummary(soilm_data3d)
    plot_data2d(:,2) = soilm_data3d(:,0,4)
    plot_data2d(:,3) = evap_data3d(:,0,3)
    labels=(/"Lake_Precp","Lake_SfcHd", "Lake_SoilM", "Lake_Evapor"/)
    colors=(/"green", "red", "blue",  "orange"/)
 ;   colors=(/"green", "red", "cyan", "deepskyblue", "royalblue", "blue", "blueviolet"/)
    ; 
    wks=gsn_open_wks("png", "precp_sfchd_soilm_evap_rate_lakearea")
    res=True
    res@xyLineColors= colors
    res@xyLineThicknessF = 5.0
    res@xyDashPattern = 0
    res@tiMainString = "Precp & SfcHead & SoilM & Evap Rate (m~S~3~N~ s~S~-1~N~)"
    res@gsnFrame=False
    res@gsnDraw=False
    res@vpXF=0.15
    plot=plot_ts_lines(wks, sfchd_data2d@str_dt, plot_data2d, res)
    lgres                    = True
    lgres@lgLineColors       = colors
    lgres@lgLineThicknessF   = 3.
    lgres@lgLabelFontHeightF = 0.15
    lgres@vpWidthF           = 0.12              
    lgres@vpHeightF          = 0.04 * nlines
    lgres@lgPerimOn          = True               
    zeros=new((/nlines/), "float")
    zeros=0
    lgres@lgDashIndexes        = zeros
    lgres@lgPerimFillColor   = 0
    lgres@lgPerimFill        = 0
    gsn_legend_ndc(wks,nlines,labels,0.8,0.75,lgres)
    draw(plot)
    frame(wks)
    delete(wks)
end

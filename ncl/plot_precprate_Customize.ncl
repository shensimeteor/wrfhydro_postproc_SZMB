load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "gsn_add_shapefile_polylines_for_v600.ncl"
load "ncl_future_func.ncl"
load "convert_and_copyout.ncl"
; for SZMB machine realtime 

undef("read_ascii_lonlat")
;return lonlat(:,2), first column is lon, last column is lat
function read_ascii_lonlat(asciifile)
local data1d, nrow, lonlatx
begin   
    data1d=asciiread(asciifile, -1, "float")
    nrow=dimsizes(data1d)/2
    lonlatx=onedtond(data1d, (/nrow,2/))
    return(lonlatx)
end


undef("add_border_marker_line_TG")
function add_border_marker_line_TG(wks, plot)
local file_channel, file_basin_border, file_lake_border, plots, lonlat_channode, lonlat_basinborder, lonlat_lakeborder, res1, res2
begin
    file_channel="TG_channode_lonlat.txt"
    file_basin_border="TG_basinborder_lonlat.txt"
    file_lake_border="TG_lakeborder_lonlat.txt"
    plots=new((/3/), "graphic")
    ;channel
    lonlat_channode=read_ascii_lonlat(file_channel)
    res1=True
    res1@gsMarkerIndex=16
    res1@gsMarkerColor="black"
    res1@gsMarkerSizeF=0.002
    plots(0)=gsn_add_polymarker(wks, plot, lonlat_channode(:,0), lonlat_channode(:,1), res1)
    ;border
    lonlat_basinborder=read_ascii_lonlat(file_basin_border)
    lonlat_lakeborder=read_ascii_lonlat(file_lake_border)
    res2=True
    res2@gsLineColor="black"
    res2@gsLineDashPattern = 1
    res2@gsLineThicknessF = 1.0
    plots(1)=gsn_add_polyline(wks, plot, lonlat_basinborder(:,0), lonlat_basinborder(:,1), res2)
    res2@gsLineDashPattern = 2
    plots(2)=gsn_add_polyline(wks, plot, lonlat_lakeborder(:,0), lonlat_lakeborder(:,1), res2)
    return(plots)
end

undef("add_node_marker_GL")
function add_node_marker_GL(wks, plot)
local file_channel, lonlat_channode, res1, plotx
begin

    file_channel="GL_channode_lonlat.txt"
    lonlat_channode=read_ascii_lonlat(file_channel)
    res1=True
    res1@gsMarkerIndex=16
    res1@gsMarkerColor="black"
    res1@gsMarkerSizeF=0.002
    plotx=gsn_add_polymarker(wks, plot, lonlat_channode(:,0), lonlat_channode(:,1), res1)
    return(plotx)

end

undef("add_node_marker_TG")
function add_node_marker_TG(wks, plot)
local file_channel, lonlat_channode, res1, plotx
begin
    file_channel="TG_channode_lonlat.txt"
    lonlat_channode=read_ascii_lonlat(file_channel)
    res1=True
    res1@gsMarkerIndex=16
    res1@gsMarkerColor="black"
    res1@gsMarkerSizeF=0.002
    plotx=gsn_add_polymarker(wks, plot, lonlat_channode(:,0), lonlat_channode(:,1), res1)
    return(plotx)
end


begin
; argumetn: srcfilename: should be YYYYMMDDHHmm.LDASIN_DOMAIN1 (input file)
; optional:
;    lonlat_list=lon1,lon2,lat1,lat2 (define the subdomain to plot, default is whole domain)
;    dom_name (default is D4, other case: SZ--with predefined lonlat_list; TG; GL)
;    add_chan_border (default is "", other case: TG, GL, TGchan)
;       TG: need TG_channode_lonlat.txt, TG_lakeborder_lonlat.txt TG_basinborder_lonlat.txt. plot channel-ndoes +  border makers
;       GL: need GL_channode_lonlat.txt. plot channel nodes markers
;       TGchan: only the TG_channode_lonlat.txt (only plot channel node markers)
;       copydir_list: for realtime run, a list separated by ',' containing dest-dir to cp pngs


 if( .not. isvar("srcfilename")) then
     print((/"must provide: srcfilename .."/))
     print((/"opional: lonlat_list = lon1,lon2,lat1,lat2 .."/))
     print((/"    dom_name ( predefined: SZ, D4)"/))
     print((/"    add_chan_border (predefined: TG, TGchan, GL)"/))
     print((/"    copydir_list=png_copy_dir1,png_copy_dir2..."/))
     exit
 end if
 if( .not. isvar("dom_name")) then
     dom_name="D4"
 end if
 if(.not. isvar("copydir_list")) then
     copydirs=(/""/)
 else
     copydirs=str_split(copydir_list, ",")
 end if
    
; ===== terrain stuff =====
 terrain_file = "geo_em.nc"
 fall   =addfile(terrain_file,"r")
 tlat1  = fall@TRUELAT1
 tlat2  = fall@TRUELAT2
 clat   = fall@MOAD_CEN_LAT
 clon   = fall@STAND_LON
 xlat   = fall->XLAT_M(0,:,:)
 xlon   = fall->XLONG_M(0,:,:)

 hgt_plot = fall->HGT_M(0,:,:)
 hgt_plot@lat2d = xlat
 hgt_plot@lon2d = xlon

 dsizes_hgt = dimsizes(hgt_plot)
 n_y = dsizes_hgt(0)
 n_x = dsizes_hgt(1)

; ===== specify the corner points to plot =====
 fsz = addfile("SZDistrictSurface.nc","r")
 szlat = tofloat(fsz->y)
 szlon = tofloat(fsz->x)
 xlat1  = min(szlat)
 xlat2  = max(szlat)

 xlon1  = min(szlon)
 xlon2  = max(szlon)


; ===== streamflow file =====
; ===== one at a time =====
 fs = systemfunc("ls -1 "+srcfilename)
;print(fs)
 num_fs = dimsizes(fs)
 got_ij=0
 do ifile = 0, num_fs-1, 1
     print("Now for "+fs(ifile))
     ff = addfile(fs(ifile)+".nc","r")
     var2d=ff->RAINRATE
     var2d=var2d * 3600 ; convert to mm/h
     var2d@lon2d=xlon
     var2d@lat2d=xlat

     strs = str_split(fs(ifile),".")
     date_str = strs(0)
     dtime_map = (/4,2,2,2,2/)
     date_vec = str_split_by_length(date_str,dtime_map)
     ymdh = date_vec(0)+date_vec(1)+date_vec(2)+date_vec(3)
     print("For file "+fs(ifile)+" ymdh is "+ymdh)

;    ===== plot map background =====
     fig_name="RainRate_"+dom_name+"_valid_at_"+ymdh
     wks = gsn_open_wks("png",fig_name)
     gsn_define_colormap(wks, "prcp_1")
     
     res	= True
     if(got_ij .eq. 0) then
        opt	= True

        opt@MAP_PROJ  = fall@MAP_PROJ
        opt@TRUELAT1  = fall@TRUELAT1
        opt@TRUELAT2  = fall@TRUELAT2
        opt@STAND_LON = fall@STAND_LON
        opt@DX        = fall@DX
        opt@DY        = fall@DY

        opt@REF_LAT = xlat(0,0)
        opt@REF_LON = xlon(0,0)
        opt@KNOWNI  = 1.0
        opt@KNOWNJ  = 1.0
        if( .not. isvar("lonlat_list")) then
           if( dom_name .eq. "SZ") then
             j1 = 56
             i1 = 37
             j2 = 114
             i2 = 134
           else
               if( dom_name .eq. "D4") then
                  i1 = 0
                  i2 = n_x-1
                  j1 = 0 
                  j2 = n_y-1
               else
                  print("only D4/SZ dom_name have predefined lonlat_list, please define lonlat_list in cmd-arg \n")
                  exit
               end if
           end if
           lonlats=(/xlon(floattointeger(j1),floattointeger(i1)), xlon(floattointeger(j2),floattointeger(i2)), \
                     xlat(floattointeger(j1),floattointeger(i1)), xlat(floattointeger(j2),floattointeger(i2)) /)
        else
           lonlats=tofloat(str_split(lonlat_list, ","))
           loc1=floor(wrf_ll_to_ij(lonlats(0), lonlats(2), opt))
           i1 = where(loc1(0) .ge. 1, loc1(0)-1, 0)
           j1 = where(loc1(1) .ge. 1, loc1(1)-1, 0)
           loc2=ceil(wrf_ll_to_ij(lonlats(1), lonlats(3), opt))
           i2 = where(loc2(0) .le. n_x, loc2(0)-1, n_x-1)
           j2 = where(loc2(1) .le. n_y, loc2(1)-1, n_y-1)
        end if
        print((/"domain: i1="+i1+", i2="+i2+", j1="+j1+", j2="+j2/))
        got_ij=1
     end if


;    ==================================
     res@gsnDraw                     = False
     res@gsnFrame                    = False
;    res@gsnMaximize                 = True

;    res@gsnSpreadColors             = True
;    res@gsnSpreadColorStart         = 32
;    res@gsnSpreadColorEnd           = 62
     res@pmTickMarkDisplayMode       = "Always"

;    res@cnLevelSelectionMode        = "ManualLevels"
;    res@cnMinLevelValF              = 0
;    res@cnMaxLevelValF              = 800
;    res@cnLevelSpacingF             = 100
     res@cnLevelSelectionMode        = "ExplicitLevels"
     res@cnLevels  =  (/0.1,1,2.,5,7.5,10,15,20,25,30,40,50,60,75,100/)
     nbval = dimsizes (res@cnLevels)
     res@cnFillColors     = floattoint(fspan(2,17,nbval+1)) 

     res@gsnLeftString               = ""
     res@gsnRightString              = ""

     res@cnFillOn                    = True
     res@cnLinesOn                   = False
     res@cnLineLabelsOn              = False

     res@lbLabelStride               = 20
     res@lbBoxLinesOn                = False
     res@lbLabelStride               = 3

     res@mpProjection                = "LambertConformal"
     res@mpLambertParallel1F         = tlat1
     res@mpLambertParallel2F         = tlat2
     res@mpLambertMeridianF          = clon

     res@mpLimitMode                 = "Corners"

;     res@mpLeftCornerLatF            = xlat(floattointeger(j1),floattointeger(i1))
;     res@mpLeftCornerLonF            = xlon(floattointeger(j1),floattointeger(i1))
;     res@mpRightCornerLatF           = xlat(floattointeger(j2),floattointeger(i2))
;     res@mpRightCornerLonF           = xlon(floattointeger(j2),floattointeger(i2))
     res@mpLeftCornerLatF = lonlats(2)
     res@mpLeftCornerLonF = lonlats(0)
     res@mpRightCornerLonF = lonlats(1)
     res@mpRightCornerLatF = lonlats(3)


     res@mpFillOn                    = False
;    res@mpOutlineDrawOrder          = "PostDraw"
     res@mpOceanFillColor            = 5
     res@mpLandFillColor             = "transparent"
     res@mpFillDrawOrder             = "PreDraw"
     res@mpOutlineBoundarySets       = "National"
     res@mpOutlineDrawOrder  = "PostDraw"
;    res@mpOutlineSpecifiers = (/"China:states"/)
;    res@mpDataBaseVersion     = "MediumRes"          ; Default is LowRes
     res@mpDataBaseVersion     = "HighRes"          ; Default is LowRes
     res@mpGeophysicalLineThicknessF	= 1.5
     res@mpGeophysicalLineColor = "black"

     res@mpGridLineDashPattern  = 2
     res@pmTickMarkDisplayMode  = "Always"
     res@tmYROn                 = False
     res@tmXTOn                 = False

;    res@tiMainString           = "streamflow 10**2 m**3/s"
     res@tiMainString           = "RainRate (mm/h) valid at "+ymdh+"Z"
     res@tiMainFontHeightF      = 0.020              ; smaller title

     res@gsnAddCyclic           = False

     res@tfDoNDCOverlay = True
     res@lbLabelBarOn   = True
     res@lbTitlePosition = "Bottom"
     res@lbPerimOn               = False
     res@lbOrientation           = "Horizontal"
     res@lbBoxLinesOn            = True
     res@lbBoxLineThicknessF     = 0.6
     res@lbTitleFontHeightF      = 0.016
     res@pmLabelBarWidthF        = 0.70
     res@pmLabelBarHeightF       = 0.1
;     res@lbLabelAutoStride    = True
     res@lbLabelStride = 1
     res@lbLabelFontHeightF      = 0.012
;    drawNDCGrid(wks)

;    map = gsn_csm_contour_map(wks,hgt_plot,res)
     map = gsn_csm_contour_map(wks,var2d(0,floattointeger(j1):floattointeger(j2),floattointeger(i1):floattointeger(i2)),res)
     lnres             = True   
     lnres@gsLineColor     = "gray20" 
     lnres@gsLineThicknessF    = 1.5
     if(dom_name .ne. "D4") then
         map_SZD = gsn_add_shapefile_polylines(wks,map,"./SZDistrictSurface.nc",lnres)
     end if

     if(isvar("add_chan_border")) then
        if(add_chan_border .eq. "TG") then
           plots=add_border_marker_line_TG(wks, map)
        else
           if(add_chan_border .eq. "GL") then
               plots=add_node_marker_GL(wks,map)
           else
               if(add_chan_border .eq. "TGchan") then
                   plots=add_node_marker_TG(wks,map)
               else
                   print("Warning: add_chan_border NOT recogized!")
               end if
           end if
        end if
     end if

     draw(map)
     frame(wks)
     delete(wks)
;     system("convert -alpha off -trim +repage -density 150% "+fig_name+".png "+fig_name+".png")
    ; system("rm -rf "+fig_name+".ps")
     ;system("rm -f RainRate_SZ_valid_at_"+ymdh+".ps")

    convert_and_copyout(fig_name+".png", copydirs) 
  end do

end


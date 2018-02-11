load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "gsn_add_shapefile_polylines_for_v600.ncl"
load "ncl_future_func.ncl"
load "convert_and_copyout_forStreamflow.ncl"

; plot with cusomized nodeidx and area lon/lat 
; input: srcfilename (pattern to ls); 
; optional: lonlat_list="lon1,lon2,lat1,lat2", nodeidx_file, dom_name(e.g. TG, SZ)
;    colorbar_maxvalue: 50(default, for TG/SZ small domains), 100(for D4/SZ big domains)
;    copydir_list: for realtime run, a list separated by ',' containing dest-dir to cp pngs
begin
 if( .not. isvar("srcfilename")) then
     print((/"must provide: srcfilename .."/))
     print((/"opional: lonlat_list = lon1,lon2,lat1,lat2 .."/))
     print((/"nodeidx_file = file_path_of_node_idx_begin_with_0 .."/))
     print((/"dom_name ( predefined: SZ, D4)"/))
     print((/"colorbar_maxvalue (50/100)" /))
     exit
 end if
 if( .not. isvar("dom_name")) then
     dom_name="D4"
 end if
 if( isvar("nodeidx_file")) then
     nodeidx=asciiread(nodeidx_file, -1, "integer")
 end if
 if( .not. isvar("colorbar_maxvalue")) then
     colorbar_maxvalue=50
 end if
 if( (colorbar_maxvalue .ne. 50) .and. (colorbar_maxvalue .ne. 100)) then
     print("colorbar_maxvalue should be either 50 or 100")
     exit
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
; for the SZ district


; ===== streamflow file =====
; ===== one at a time =====
 fs = systemfunc("ls -1 "+srcfilename)
 num_fs = dimsizes(fs)

 got_ij=0
 do ifile = 0, num_fs-1, 1
  ff = addfile(fs(ifile)+".nc","r")
  if(isvar("nodeidx")) then
      lat    = ff->latitude(nodeidx)
      lon    = ff->longitude(nodeidx)
      stream = ff->streamflow(nodeidx)
  else
      lat    = ff->latitude
      lon    = ff->longitude
      stream = ff->streamflow
  end if
  pwv    = stream

  strs = str_split(fs(ifile),".")
  date_str = strs(0)
  dtime_map = (/4,2,2,2,2/)
  date_vec = str_split_by_length(date_str,dtime_map)
  ymdh = date_vec(0)+date_vec(1)+date_vec(2)+date_vec(3)

; ===== plot map background =====
 fig_name="Streamflow_"+dom_name+"_valid_at_"+ymdh
 wks_type="ps"
; wks_type@wkWidth=2250
; wks_type@wkHeight=2250
 wks = gsn_open_wks(wks_type,fig_name)

  gsn_define_colormap(wks,"gsltod")
  setvalues wks
    "wkColorMap"        : "gsltod"
    "wkForegroundColor" : (/0.,0.,0./)
    "wkBackgroundColor" : (/1.,1.,1./)
  end setvalues

  cmap = RGBtoCmap("grads_rainbow2.txt")
  gsn_define_colormap(wks,cmap)
  gsn_merge_colormaps(wks,cmap,"gsltod")

; gsn_define_colormap(wks,"BlAqGrYeOrReVi200")
; =================================

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
    ; ================================
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
          loc1=wrf_ll_to_ij(lonlats(0), lonlats(2), opt)
          i1 = where(loc1(0) .ge. 1, loc1(0)-1, 0)
          j1 = where(loc1(1) .ge. 1, loc1(1)-1, 0)
          loc2=wrf_ll_to_ij(lonlats(1), lonlats(3), opt)
          i2 = where(loc2(0) .le. n_x, loc2(0)-1, n_x-1)
          j2 = where(loc2(1) .le. n_y, loc2(1)-1, n_y-1)
      end if
      print((/"domain: i1="+i1+", i2="+i2+", j1="+j1+", j2="+j2/))
      got_ij=1
  end if



; ==================================
  res@gsnDraw                     = False
  res@gsnFrame                    = False
; res@gsnMaximize                 = True

; res@gsnSpreadColors             = True
; res@gsnSpreadColorStart         = 32
; res@gsnSpreadColorEnd           = 62
; res@gsnSpreadColorStart         = 6
; res@gsnSpreadColorEnd           = 46
  res@pmTickMarkDisplayMode       = "Always"

  res@cnLevelSelectionMode        = "ExplicitLevels"
  res@cnLevels  =(/100,200,300,400,500,600,700,800/)
  res@cnFillColors     = (/32,33,34,35,36,37,38,39,40,41,42,43,44,45,46/)

  res@gsnLeftString               = ""
  res@gsnRightString              = ""

  res@cnFillOn                    = True
  res@cnLinesOn                   = False
  res@cnLineLabelsOn              = False

  res@lbLabelStride               = 20
  res@lbBoxLinesOn                = False
  res@lbLabelStride               = 3

;  res@mpProjection                = "LambertConformal"
  res@mpProjection = "mercator"
  res@mpLimitMode                 = "Corners"

  res@mpLeftCornerLonF   =  lonlats(0)
  res@mpLeftCornerLatF   =  lonlats(2)
  res@mpRightCornerLonF  =  lonlats(1)
  res@mpRightCornerLatF  =  lonlats(3)

; res@mpFillOn                    = False
  res@mpFillOn                    = False
  res@mpOutlineOn                 = False
  res@mpOceanFillColor            = 5
  res@mpLandFillColor             = "transparent"
; res@mpInlandWaterFillColor      = "grey"
; res@mpOutlineDrawOrder          = "PostDraw"
; res@mpFillDrawOrder             = "PreDraw"
  res@mpFillDrawOrder             = "PostDraw"
  res@mpOutlineBoundarySets       = "National"
; res@mpOutlineBoundarySets       = "NoBoundaries"
; res@mpOutlineSpecifiers = (/"China:states"/)
; res@mpDataBaseVersion     = "MediumRes"          ; Default is LowRes
  res@mpDataBaseVersion     = "HighRes"          ; Default is LowRes
; res@mpGeophysicalLineThicknessF	= 3.0
; res@mpGeophysicalLineThicknessF	= 0.0
  res@mpGeophysicalLineThicknessF	= 1.0

  res@mpGridLineDashPattern  = 2
  res@pmTickMarkDisplayMode  = "Always"
  res@tmYROn                 = False
  res@tmXTOn                 = False

; res@tiMainString           = "streamflow 10**2 m**3/s"
  res@tiMainString           = "Streamflow (m~S~3~N~ s~S~-1~N~)  "+ymdh+"Z"
  res@tiMainFontHeightF      = 0.020              ; smaller title

  res@gsnAddCyclic           = False

  res@tfDoNDCOverlay = True
  res@lbLabelBarOn   = False

; drawNDCGrid(wks)
 map = gsn_csm_map(wks,res)
 print("end_map")
; map = gsn_csm_contour_map(wks,hgt_plot,res)
  
  ;map = gsn_csm_contour_map(wks,hgt_plot(tointeger(j1):tointeger(j2),tointeger(i1):tointeger(i2)),res)

  lnres				= True 
  lnres@gsLineColor		= "black"
  lnres@gsLineThicknessF	= 0.5
  
  if(dom_name .eq. "SZ") then
     map_SZD = gsn_add_shapefile_polylines(wks,map,"./SZDistrictSurface.nc",lnres)
  end if

; ===== now do the plot =====
  gsn_define_colormap(wks,"gsltod")
  setvalues wks
    "wkColorMap"        : "gsltod"
    "wkForegroundColor" : (/0.,0.,0./)
    "wkBackgroundColor" : (/1.,1.,1./)
  end setvalues

  cmap = RGBtoCmap("grads_rainbow2.txt")
  gsn_define_colormap(wks,cmap)
  gsn_merge_colormaps(wks,cmap,"gsltod")

 if(colorbar_maxvalue .eq. 100) then
     arr    = (/0.5,2.0,4.0,8.0,12.0,20.0,50.0,100.0/)
 else
     arr   =(/0.2, 1.0, 2.0, 4.0, 6.0, 10.0, 25.0, 50.0/)
 end if
 colors = (/4,5,7,9,10,11,12,13,14/)
 labels = new(dimsizes(arr)+1,string)

 npts   = dimsizes(pwv)
 
 num_distinct_markers = dimsizes(arr)+1        ; number of distinct markers
 lat_new = new((/num_distinct_markers,dimsizes(pwv)/),float,-999)
 lon_new = new((/num_distinct_markers,dimsizes(pwv)/),float,-999)

  do i = 0, num_distinct_markers-1
    if (i.eq.0) then
      indexes = ind(pwv.lt.arr(0))
      labels(i) = "x < " + arr(0)
    end if
    if (i.eq.num_distinct_markers-1) then
      indexes = ind(pwv.ge.max(arr))
      labels(i) = "x >= " + max(arr)
    end if
    if (i.gt.0.and.i.lt.num_distinct_markers-1) then
      indexes = ind(pwv.ge.arr(i-1).and.pwv.lt.arr(i))
      labels(i) = arr(i-1) + " <= x < " + arr(i)
    end if

    if (.not.any(ismissing(indexes))) then
      npts_range = dimsizes(indexes)   ; # of points in this range.
      lat_new(i,0:npts_range-1) = lat(indexes)
      lon_new(i,0:npts_range-1) = lon(indexes)
    end if
    delete(indexes)            ; Necessary b/c "indexes" may be a different
                               ; size next time.
  end do

  gsres               = True
  gsres@gsMarkerIndex = 16          ; Use filled dots for markers.
  ;gsres@gsMarkerIndex =  4           ; hole in the middle
  gsres@gsMarkerSizeF = 0.001

  txres               = True
; txres@txFontHeightF = 0.015
  txres@txFontHeightF = 0.010

; xleg = (/-0.05,0.00,0.00,0.09,0.09,0.28,0.28,0.48,0.48,0.68,0.68,0.88,0.88/)
; xtxt = (/-0.14,0.09,0.09,0.18,0.18,0.37,0.37,0.57,0.57,0.78,0.78,0.98,0.98/)
; yleg = (/-0.05,0.05,0.01,0.05,0.01,0.05,0.01,0.05,0.01,0.05,0.01,0.05,0.01/)
; ytxt = (/-0.05,0.05,0.01,0.05,0.01,0.05,0.01,0.05,0.01,0.05,0.01,0.05,0.01/)
; xleg = (/0.00,0.07,0.07,0.20,0.20,0.40,0.40,0.60,0.60,0.80,0.80/)
; xtxt = (/0.03,0.16,0.16,0.30,0.30,0.50,0.50,0.70,0.70,0.90,0.90/)
; xleg = (/0.00,0.09,0.09,0.25,0.25,0.45,0.45,0.65,0.65,0.85,0.85/)
; xtxt = (/0.09,0.16,0.16,0.36,0.36,0.56,0.56,0.76,0.76,0.96,0.96/)
; xtxt = (/0.02,0.12,0.12,0.32,0.32,0.52,0.52,0.72,0.72,0.92,0.92/)
; yleg = (/0.01,0.05,0.01,0.05,0.01,0.05,0.01,0.05,0.01,0.05,0.01/)
; ytxt = (/0.01,0.05,0.01,0.05,0.01,0.05,0.01,0.05,0.01,0.05,0.01/)
; xleg = (/0.00,0.09,0.09,0.25,0.25,0.45,0.45,0.65,0.65,0.85,0.85/)
; xtxt = (/0.09,0.16,0.16,0.36,0.36,0.56,0.56,0.76,0.76,0.96,0.96/)
; xtxt = (/0.02,0.12,0.12,0.32,0.32,0.52,0.52,0.72,0.72,0.92,0.92/)
; yleg = (/0.01,0.05,0.01,0.05,0.01,0.05,0.01,0.05,0.01,0.05,0.01/)
; ytxt = (/0.01,0.05,0.01,0.05,0.01,0.05,0.01,0.05,0.01,0.05,0.01/)

 ; xleg = (/0.12,0.12,0.12,0.32,0.32,0.32,0.52,0.52,0.52,0.72,0.72,0.72/)
 ; xtxt = (/0.20,0.20,0.20,0.40,0.40,0.40,0.60,0.60,0.60,0.80,0.80,0.80/)
 ; yleg = (/0.15,0.1,0.05,0.15,0.1,0.05,0.15,0.1,0.05,0.15,0.1,0.05/)
 ; ytxt = (/0.15,0.1,0.05,0.15,0.1,0.05,0.15,0.1,0.05,0.15,0.1,0.05/)
; xleg = (/0.6,0.6,0.6,0.6,0.6, 0.7,0.7,0.7,0.7,0.7/)
xleg = (/0.55,0.55,0.55,0.55,0.55, 0.65,0.65,0.65,0.65,0.65/)
 yleg = (/ 0.35, 0.33, 0.31, 0.29, 0.27, 0.35, 0.33, 0.31, 0.29, 0.27/)
 xtxt = xleg+0.05
 ytxt = yleg

 point = new(num_distinct_markers,graphic)


  do i = 0, num_distinct_markers-1
    if (.not.ismissing(lat_new(i,0)))
      gsres@gsMarkerColor      = colors(i)
      ;gsres@gsMarkerColor      = 1
      ;gsres@gsMarkerThicknessF = 0.7*(i+1)
;     gsres@gsMarkerThicknessF = 2
;     gsres@MarkerSizeF  = 0.4
      if(dom_name .eq. "D4" .or. dom_name .eq. "SZ") then
          gsres@gsMarkerThicknessF = 0.2
          gsres@gsMarkerSizeF  = 0.001
      else
          gsres@gsMarkerThicknessF = 2
          gsres@gsMarkerSizeF  = 0.005
      end if
      point(i) =  gsn_add_polymarker(wks,map,lon_new(i,:),lat_new(i,:),gsres) 
;     point(i) =  gsn_add_polymarker(wks,map_SZD,lon_new(i,:),lat_new(i,:),gsres)

; Add marker and text for the legend.

      ggsres = gsres
      ggsres@gsMarkerSizeF = 0.010
;      gsn_polymarker_ndc(wks,          xleg(i),yleg(i),ggsres)
;    gsn_text_ndc      (wks,labels(i),xtxt(i),ytxt(i),txres)
    end if
   end do

  print("before draw")
  draw(map)
  print("to frame")
  frame(wks)
  print("end frame")
  delete(wks)
  
;  convert_and_copyout_forStreamflow(fig_name+".png", copydirs) 

  end do

end


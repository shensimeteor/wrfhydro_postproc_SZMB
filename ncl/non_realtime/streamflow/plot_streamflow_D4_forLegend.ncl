;
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"

begin

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
 xlat1  = min(xlat)
 xlat2  = max(xlat)

 xlon1  = min(xlon)
 xlon2  = max(xlon)

; ===== streamflow file =====
; ===== one at a time =====
 fs = systemfunc("ls -1 "+srcfilename)
;print(fs)
 num_fs = dimsizes(fs)

 do ifile = 0, num_fs-1, 1
  print("Now for "+fs(ifile))
  ff = addfile(fs(ifile)+".nc","r")
  lat    = ff->latitude
  lon    = ff->longitude
  stream = ff->streamflow
; pwv    = stream/1.0e2
  pwv    = stream

  strs = str_split(fs(ifile),".")
  date_str = strs(0)
  dtime_map = (/4,2,2,2,2/)
  date_vec = str_split_by_length(date_str,dtime_map)
  ymdh = date_vec(0)+date_vec(1)+date_vec(2)+date_vec(3)
  print("For file "+fs(ifile)+" ymdh is "+ymdh)

; ===== plot map background =====
 wks = gsn_open_wks("ps","Hourly_streamflow_D4_valid_at_"+ymdh)
;wks_type = "png"
;wks_type@wkWidth  = 2500
;wks_type@wkHeight = 2500
;wks = gsn_open_wks(wks_type,"Hourly_streamflow_D4_valid_at_"+ymdh)

  gsn_define_colormap(wks,"gsltod")
  setvalues wks
    "wkColorMap"        : "gsltod"
    "wkForegroundColor" : (/0.,0.,0./)
    "wkBackgroundColor" : (/1.,1.,1./)
  end setvalues

  cmap = RGBtoCmap("grads_rainbow.txt")
  gsn_define_colormap(wks,cmap)
  gsn_merge_colormaps(wks,cmap,"gsltod")

; =================================

  res	= True
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

; =================================
  loc1 = wrf_ll_to_ij ( xlon1, xlat1, opt )
  i1 = loc1(0)-1
  j1 = loc1(1)-1

  if (i1.lt.0) then
   i1 = 0
  end if

  if (j1.lt.0) then
   j1 = 0
  end if

; =================================
  loc2 = wrf_ll_to_ij ( xlon2, xlat2, opt )
  i2 = loc2(0)-1
  j2 = loc2(1)-1

  if (i2.gt.n_x-1) then
   i2 = n_x - 1
  end if

  if (j2.gt.n_y-1) then
   j2 = n_y - 1
  end if

; ==================================
  res@gsnDraw                     = False
  res@gsnFrame                    = False
; res@gsnMaximize                 = True

; res@gsnSpreadColors             = True
; res@gsnSpreadColorStart         = 32
; res@gsnSpreadColorEnd           = 62
  res@pmTickMarkDisplayMode       = "Always"

; res@cnLevelSelectionMode        = "ManualLevels"
; res@cnMinLevelValF              = 0
; res@cnMaxLevelValF              = 800
; res@cnLevelSpacingF             = 100
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

  res@mpProjection                = "LambertConformal"
  res@mpLambertParallel1F         = tlat1
  res@mpLambertParallel2F         = tlat2
  res@mpLambertMeridianF          = clon

  res@mpLimitMode                 = "Corners"

  res@mpLeftCornerLatF            = xlat(floattointeger(j1),floattointeger(i1))
  res@mpLeftCornerLonF            = xlon(floattointeger(j1),floattointeger(i1))
  res@mpRightCornerLatF           = xlat(floattointeger(j2),floattointeger(i2))
  res@mpRightCornerLonF           = xlon(floattointeger(j2),floattointeger(i2))

  res@mpFillOn                    = True
; res@mpOutlineDrawOrder          = "PostDraw"
  res@mpOceanFillColor            = 5
  res@mpLandFillColor             = "transparent"
  res@mpFillDrawOrder             = "PostDraw"
  res@mpOutlineBoundarySets       = "National"
; res@mpOutlineSpecifiers = (/"China:states"/)
; res@mpDataBaseVersion     = "MediumRes"          ; Default is LowRes
  res@mpDataBaseVersion     = "HighRes"          ; Default is LowRes
  res@mpGeophysicalLineThicknessF	= 1.0

  res@mpGridLineDashPattern  = 2
  res@pmTickMarkDisplayMode  = "Always"
  res@tmYROn                 = False
  res@tmXTOn                 = False

; res@tiMainString           = "streamflow 10**2 m**3/s"
  res@tiMainString           = "Hourly streamflow (m~S~3~N~ s~S~-1~N~) valid at "+ymdh+"Z"
  res@tiMainFontHeightF      = 0.020              ; smaller title

  res@gsnAddCyclic           = False

  res@tfDoNDCOverlay = True
  res@lbLabelBarOn   = False

; drawNDCGrid(wks)

; map = gsn_csm_contour_map(wks,hgt_plot,res)
;# sishen
;   map=gsn_csm_map(wks,res)
  map = gsn_csm_contour_map(wks,hgt_plot(floattointeger(j1):floattointeger(j2),floattointeger(i1):floattointeger(i2)),res)

; ===== now do the plot =====

; arr    = (/0.1,0.5,1.0,2.0,4.0,8.0,10.0,12.0,20.0,50.0,100.0/)
; colors = (/0,0,2,3,5,9,10,11,12,13,14,15/)
; arr    = (/0.5,2.0,4.0,8.0,12.0,20.0,50.0,100.0/)
 arr = (/0.2, 1.0, 2.0, 4.0, 6.0, 10.0, 25.0, 50.0/)
 colors = (/4,5,7,9,10,11,12,13,14/)
 labels = new(dimsizes(arr)+1,string)

 npts   = 62043
 
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

;  xleg = (/0.12,0.12,0.12,0.32,0.32,0.32,0.52,0.52,0.52,0.72,0.72,0.72/)
;  xtxt = (/0.20,0.20,0.20,0.40,0.40,0.40,0.60,0.60,0.60,0.80,0.80,0.80/)
;  yleg = (/0.15,0.1,0.05,0.15,0.1,0.05,0.15,0.1,0.05,0.15,0.1,0.05/)
;  ytxt = (/0.15,0.1,0.05,0.15,0.1,0.05,0.15,0.1,0.05,0.15,0.1,0.05/)
  xleg = (/0.15,0.15,0.15,0.30,0.30,0.30,0.45,0.45,0.45/)
  xtxt=xleg + 0.05
  yleg = (/0.15, 0.12, 0.09, 0.15, 0.12, 0.09, 0.15, 0.12, 0.09/)
  ytxt= yleg

 point = new(num_distinct_markers,graphic)

  do i = 0, num_distinct_markers-1
    if (.not.ismissing(lat_new(i,0)))
      gsres@gsMarkerColor      = colors(i)
      ;gsres@gsMarkerColor      = 1
      ;gsres@gsMarkerThicknessF = 0.7*(i+1)
      ;thin1
      gsres@gsMarkerThicknessF = 0.2
      gsres@MarkerSizeF  = 0.02
      ;thin2
;      gsres@gsMarkerThicknessF = 0.1
;      gsres@MarkerSizeF  = 0.01
      ;thin3
;      gsres@gsMarkerThicknessF = 0.05
;      gsres@MarkerSizeF = 0.005

      point(i) =  gsn_add_polymarker(wks,map,lon_new(i,:),lat_new(i,:),gsres)

; Add marker and text for the legend.

      ggsres = gsres
      ggsres@gsMarkerSizeF = 0.010
;     gsn_polymarker_ndc(wks,          xleg(i),yleg(i),gsres)
      gsn_polymarker_ndc(wks,          xleg(i),yleg(i),ggsres)
      gsn_text_ndc      (wks,labels(i),xtxt(i),ytxt(i),txres)
    end if
   end do

  draw(map)
  frame(wks)

  system("convert -trim -density 150% Hourly_streamflow_D4_valid_at_"+ymdh+".ps Hourly_streamflow_D4_valid_at_"+ymdh+".png")
  system("rm -f Hourly_streamflow_D4_valid_at_"+ymdh+".ps")

  
  end do

end


; ==============================================================
; Concepts illustrated:
;   - Calculating EOFs
;   - Drawing a time series plot
; =============================================================
; This script uses functions eofunc_n_Wrap and eofunc_ts_n_Wrap
;  which were added in NCL V6.4.0.
; =============================================================
; These files are loaded by default in NCL V6.2.0 and newer
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

begin
; ==============================================================
; User defined parameters that specify region of globe and
; ==============================================================
  latS   = -30.
  latN   = 30. 
  lonL   = 70
  lonR   = 290.

  yrStrt = 1
  yrLast = 35

  ;season = "DJF"    ; choose Dec-Jan-Feb seasonal mean

  neof   = 4        ; number of EOFs
  optEOF = True       
  ;optEOF@jopt = 0   ; This is the default; most commonly used; no need to specify.
  ;optEOF@jopt = 1   ; **only** if the correlation EOF is desired
  optEOF@jopt = 1   ; This is the default; most commonly used; no need to specify.
  ;optEOF@pcrit = 85
  optETS = False
;*******************************************
;  Read data
;*******************************************
  diri = "/glade/work/xinyang/experiment/program/Amazon/fixed-SM-Amazon/post-process/ocn/"
  fili = "TEMP.fixed-SM-Amazon.pop.h.01-35.1x1d.nc" ; Hadley center

  f    = addfile (diri+fili, "r")
  X    = f->TEMP(:,0,:,:)   ; 1st layer temp can be used as SST, unit: C
  ;X    = lonFlip(X)
  xt   = cd_calendar(X&time, -1)/100
  ts   = ind(xt.ge.yrStrt .and. xt.le.yrLast)
  x    = X(ts,{latS:latN},{lonL:lonR})            ; (time,lat,lon) ==> (29,60,180)
  ;printVarSummary(x) 
  delete(X)

;*******************************************
;  climatology and anomaly 
;*******************************************  
  xa = rmMonAnnCycTLL(x)

;*******************************************
; create weights:  sqrt(cos(lat))   [or sqrt(gw) ]
;*******************************************
  rad    = get_d2r("float")
  clat   = xa&lat         
  clat   = sqrt( cos(rad*clat) )                 ; gw for gaussian grid
  clat_f = doubletofloat(clat)

;*******************************************
; weight all observations 
;*******************************************
  wxa   = xa                                   ; copy meta data
  wxa   = xa*conform(xa, clat_f, 1)
  wxa@long_name = "Wgt: "+wxa@long_name

;*******************************************
;  EOF 
;*******************************************
  eof    = eofunc_n_Wrap( wxa, neof, optEOF, 0)
  eof_ts = eofunc_ts_n_Wrap( wxa, eof, optETS, 0)

;*******************************************
; Normalize time series: Sum spatial weights over the area of used
;*******************************************
  dimxw  = dimsizes( wxa )
  mln    = dimxw(1)
  sumWgt = mln*sum( clat_f )
  aeof_ts = eof_ts/sumWgt
  
  ; normalization
    sd_eof_ts        = eof_ts(:,1)
    feof             = eof
    feof_ts          = eof_ts
    do n=0,neof-1
        sd_eof_ts(n) = stddev(eof_ts(n,:))
        ; leading mode multiplied by respective standard deviations of the principal coomponents
        ; units in C
        feof(n,:,:)  = eof(n,:,:)*sd_eof_ts(n)
        feof_ts(n,:) = feof_ts(n,:)/sd_eof_ts(n) 
    end do


  ;printVarSummary(feof)
  ;printVarSummary(eof_ts)

     ;----------------------------------------------------------
     ;---- write to a new output file containing the experiment name
     ;----------------------------------------------------------
     diro        = "/glade/work/xinyang/program/Amazon/cases/fixed-SM-Amazon/"
     d_name      = "eof"
     outfile     =  diro+"data/"+d_name+".nc"
     if( isfilepresent(outfile) ) then
         system("rm -rf "+outfile)
     end if
     ncout  =  addfile( outfile, "c" )
     ncout->feof                  =   feof  
     ncout->feof_ts               =   feof_ts
     print(" Well done!")

 
;*******************************************
;  plots
;*******************************************
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  n  = 0                                ; 0 => EOF1, 1=> EOF2

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  pics_file   = "pics/sst_eof" +n
  full_name   = diro+pics_file+".eps"
  system("rm -rf "+full_name)
  wks = gsn_open_wks("eps",diro+pics_file)         ; send graphics to PNG file

  plot = new(2,graphic)                ; create graphic array
                                         ; only needed if paneling
  res                      = True         
  res@cnFillOn                     = True               ; turn on color for contours
  res@cnLinesOn                    = False              ; turn off contour lines
  res@cnLineLabelsOn               = False              ; turn off contour line labels
  res@cnInfoLabelOn                = False          

  res@gsnDraw              = False        ; don't draw yet
  res@gsnFrame             = False        ; don't advance frame yet
  res@gsnAddCyclic         = False        ; data not cyclic

  res@tmXBLabelFontHeightF    = 0.012     ;set the size of x-Axis words
  res@tmYLLabelFontHeightF    = 0.012    ;set the size of y-Axis words

  ;res@cnFillPalette        = "temp_19lev"   ; choose colormap temp_19lev
  res@cnFillPalette        =  "BlueWhiteOrangeRed" 
  res@lbLabelStride        = 2
  res@mpLandFillColor      = "white"            ; set land to be gray

  res@mpCenterLonF         = 180.         ; default is 0 [GM]
  res@mpMinLatF            = min(xa&lat)
  res@mpMaxLatF            = max(xa&lat)
  res@mpMinLonF            = min(xa&lon)
  res@mpMaxLonF            = max(xa&lon)
  res@mpFillDrawOrder      = "PostDraw"
  res@tmXBMinorOn          = True

  ;res@lbLabelBarOn                 = False        ; turn off individual lb's
  res@lbLabelBarOn                 = True        ; turn off individual lb's  
  res@lbOrientation                = "Horizontal"       ; vertical label bar
  res@pmLabelBarKeepAspect         = True         
  res@pmLabelBarOrthogonalPosF     = 0.08               ; move label bar closer
                                          ; set symmetric plot min/max
  ;symMinMaxPlt(eof, 32, False, res); contributed.ncl
  res@cnLevelSelectionMode = "ManualLevels"     ; set manual contour levels
  res@cnMinLevelValF       = -0.7                ; set min contour level
  res@cnMaxLevelValF       = 0.7                 ; set max contour level
  res@cnLevelSpacingF      = 0.1               ; set contour spacing     

  res@tmBorderThicknessF    = 3
  
  res@mpShapeMode = "FreeAspect"
  res@vpHeightF= 0.3                    ; change aspect ratio of plot 
  res@vpWidthF = 0.8   
  ; since we stretch the plot, we need to slide it over a bit so it does not run off the page. we do this by:
  res@vpXF      = 0.1        ; change start locations
  ;rts@vpYF      = 0.45        ; the plot

     res@gsnLeftString  = " (a) EOF "+(n+1)
     res@gsnStringFontHeightF = 0.013
     res@gsnRightString = sprintf("%5.1f", eof@pcvar(n)) +"%"
     plot(0) = gsn_csm_contour_map(wks,feof(n,:,:),res)

;*******************************************
; time series (principal component) plot
;*******************************************
  delete(feof_ts@long_name)

  rts           = True
  rts@gsnDraw   = False       ; don't draw yet
  rts@gsnFrame  = False       ; don't advance frame yet
 ;rts@gsnScale  = True        ; force text scaling   

  rts@tmXBLabelFontHeightF    = 0.012     ;set the size of x-Axis words
  rts@tmYLLabelFontHeightF    = 0.012    ;set the size of y-Axis words

; these four resources allow the user to stretch the plot size, and
; decide exactly where on the page to draw it.
  
  ; create new date array for use on the plot 
  dimts  = dimsizes( feof_ts(0,:) )      
  timespan   = ispan(0, (dimts-1), 1)
  xspace   = ispan(0, (dimts-1), 48)
  XBValues = xspace
  xyear    = ispan(1,35,4)
  XBLabels = xyear

  rts@tmXBMode            = "Explicit"
  rts@tmXBValues          = XBValues
  rts@tmXBLabels          = XBLabels 
  rts@tmXBMinorOn         = True
  ;rts@tmXBMinorPerMajor   = 4
  ;rts@tmYLMinorOn         = "False"
  rts@tmXBTickSpacingF= 1
  rts@tmYLTickSpacingF= 0.5

  
  rts@vpHeightF = 0.3        ; Changes the aspect ratio
  rts@vpWidthF  = 0.8
  ; since we stretch the plot, we need to slide it over a bit so it does not run off the page. we do this by:
  ;rts@vpXF      = 0.1        ; change start locations
  rts@vpYF      = 0.48        ; the plot

  ;rts@gsnYRefLine           = 0.              ; reference line   
  ;rts@gsnAboveYRefLineColor = "red"           ; above ref line fill red
  ;rts@gsnBelowYRefLineColor = "blue"          ; below ref line fill blue


; rts@gsnYRefLineColor      = (/"black","transparent","black"/)
  rts@gsnBelowYRefLineColor   = (/ "blue", "transparent", "transparent"/)
  rts@gsnAboveYRefLineColor   = (/  "transparent","transparent", "red"/)
  rts@gsnYRefLine             = (/ -1, 0, 1 /)
  rts@gsnYRefLineDashPatterns = (/2,1,2/)
  rts@gsnYRefLineColor        = (/  "grey66","grey66", "grey66"/)
  rts@gsnYRefLineThicknesses  = (/3,3,3/)
  ;rts@gsnMaximize             = True             ; large format
  
  rts@xyLineThicknesses     = 3
  rts@tmBorderThicknessF    = 3

; panel plot only resources
  rtsP                     = True             ; modify the panel plot
  ;rtsP@gsnMaximize         = True             ; large format
  ;rtsP@gsnPanelMainString  = "normalized PCs"
   
  rts@gsnLeftString  = " (b) PC "+(n+1)
  rts@gsnStringFontHeightF = 0.013
  rts@gsnRightString = sprintf("%5.1f", eof@pcvar(n)) +"%"
  plot(1) = gsn_csm_xy (wks,timespan,feof_ts(n,:),rts)
  ;rtsP@gsnPanelFigureStrings = (/"(a)","(b)"/)           ; add strings to panel
  rtsP@gsnPanelFigureStringsJust="TopLeft"
  ;drawNDCGrid(wks)
  gsn_panel(wks,plot,(/2,1/),rtsP)        ; draw all 'neof' as one plot

end
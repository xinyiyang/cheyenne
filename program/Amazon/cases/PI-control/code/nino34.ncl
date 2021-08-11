load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

begin

    ; ------------------- parameter -----------------
        slat1  =  5
        slat2  = -5
        
        slon1  = -170 + 360
        slon2  = -120 + 360

    ; -------------------- read file -----------------
        diri    = "/glade/work/xinyang/experiment/program/Amazon/PI-control/post-process/ocn/"
        fili    = "TEMP.PI-control.pop.h.01-35.1x1d.nc" ; Hadley center

        ; data
        diro    = "/glade/work/xinyang/program/Amazon/cases/PI-control/"
        filo    = "data/nino34.PI-control.01-35.nc" 
        outfile = diro+filo

        file1  = addfile(diri+fili,"r")
        sst1   =file1->TEMP(:,0,:,:)
        time1  =file1->time
        lon1   =file1->lon
        lat1   =file1->lat


    ; -------------------- convert time --------------
        time2=cd_calendar(time1, -1)
        time_bn=ind(time2.eq.101)
        time_ed=ind(time2.eq.3512)


    ; -------------------- process data -------------- 
        sst_use=sst1(time_bn:time_ed,{slat1:slat2},{slon1:slon2})
        sst_anom=rmMonAnnCycTLL(sst_use)
        nino34_anom=wgt_areaave_Wrap(sst_anom, 1, 1, 1)

        ;standard deviation 
        n34_std  = stddev(nino34_anom)
        ; standardlize
        n34_mean=dim_avg(nino34_anom)
        n34_norm = nino34_anom/n34_std

   ; enso 
       enso_t=ind(n34_norm.ge.1)
       print(time2(enso_t))
       print(n34_norm(enso_t))
       ; write to csv 
       filo_csv    = "data/PI-control.csv" 
       csv_out     = diro+filo_csv
       ;----------------------------------------------------------------------
       ; Another way to write the CSV file, using write_table.
      ;----------------------------------------------------------------------
        system("rm -rf " +csv_out)
        write_table(csv_out,"w",[/time2(enso_t),n34_norm(enso_t)/],"%7i,%7.2f")

        print("`==================== " + csv_out + " ====================")
        system("cat " + csv_out)


    ; ------------------- output data ----------------
        ;system("rm -rf "+outfile)
        ;fout =addfile(outfile,"c")
        ;fout@title ="Nino 3.4 index anomalies from POP TEMP"
        ;filedimdef(fout,"time",-1,True)
        ;fout->n34=nino34_anom

;*******************************************
;  plots
;*******************************************
  pics_file   = "pics/nino34_ts"
  full_name   = diro+pics_file+".eps"
  system("rm -rf "+full_name)
  wks = gsn_open_wks("eps",diro+pics_file)         ; send graphics to PNG file

  plot = new(1,graphic)                ; create graphic array

;*******************************************
; time series plot
;*******************************************
  rts           = True
  rts@gsnDraw   = False       ; don't draw yet
  rts@gsnFrame  = False       ; don't advance frame yet
 ;rts@gsnScale  = True        ; force text scaling   

  rts@tmXBLabelFontHeightF    = 0.012     ;set the size of x-Axis words
  rts@tmYLLabelFontHeightF    = 0.012    ;set the size of y-Axis words

; these four resources allow the user to stretch the plot size, and
; decide exactly where on the page to draw it.
  
  ; create new date array for use on the plot 
  dimts  = dimsizes(nino34_anom)      
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
   
  rts@gsnLeftString  = " Nino 3.4 index "
  rts@gsnStringFontHeightF = 0.013
  rts@gsnRightString = ""
  plot(0) = gsn_csm_xy (wks,timespan,n34_norm,rts)
  ;rtsP@gsnPanelFigureStrings = (/"(a)","(b)"/)           ; add strings to panel
  rtsP@gsnPanelFigureStringsJust="TopLeft"
  ;drawNDCGrid(wks)
  gsn_panel(wks,plot,(/1,1/),rtsP)        ; draw all 'neof' as one plot        

end

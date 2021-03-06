        ;*********************************************************
        load "/glade/u/apps/ch/opt/ncl/6.6.2/intel/19.0.5//lib/ncarg/nclscripts/csm/gsn_code.ncl"
        load "/glade/u/apps/ch/opt/ncl/6.6.2/intel/19.0.5//lib/ncarg/nclscripts/csm/gsn_csm.ncl"
        load "/glade/u/apps/ch/opt/ncl/6.6.2/intel/19.0.5//lib/ncarg/nclscripts/csm/contributed.ncl"
        load "/glade/u/apps/ch/opt/ncl/6.6.2/intel/19.0.5//lib/ncarg/nclscripts/csm/shea_util.ncl"
        ;*********************************************************
        begin
            ; parameters
                his_date_start = 185011
                his_date_end   = 201410
                ssp_date_start = 201511
                ssp_date_end   = 210010
                latN           = 55
                latS           = -55
                lonW           = 0
                lonE           = 360
                ; deg is used to tune the range of longitude    
                deg            = 0
                r_start        = 1
                r_end          = 14
                model_name     = (/"MME","ACCESS-CM2", "ACCESS-ESM1-5", "BCC-CSM2-MR", "CanESM5", "CESM2", "E3SM-1-0", "FGOALS-f3-L", "GFDL-ESM4", "IPSL-CM6A-LR", "MIROC6", "MRI-ESM2-0", "NESM3", "NorESM2-MM"/)
               
                 
                mpfilename="/glade/work/xinyang/program/Amazon/mapdata/amazon_sensulatissimo_gmm_v1.shp"  

                fili_precip_1 = "pr_Amon_"+model_name+"_historical_ensmean_1x1_185001-201412.nc"
                fili_precip_2 = "pr_Amon_"+model_name+"_ssp585_ensmean_1x1_201501-210012.nc"

                diri_1        = "/glade/work/xinyang/cmip6/historical/post-process/ensmean/pr/"+fili_precip_1
                diri_2        = "/glade/work/xinyang/cmip6/ssp585/post-process/ensmean/pr/"+fili_precip_2
                ;;;;;; references
                fref          = addfile(diri_1(0),"r")
                p             = fref->pr
                diff_p_mm     = new((/110,360,r_end/), typeof(p),p@_FillValue)
                diff_ttest    = diff_p_mm
                delete(p)

            do i = (r_start-1),(r_end-1)
                ;i=0
                file1      = addfile(diri_1(i),"r")
                file2      = addfile(diri_2(i),"r")
                p          = file1->pr     ;unit: kg m-2 s-1  == mm/s  
                pp         = file2->pr     ;unit: kg m-2 s-1  == mm/s  
                p_t        = p
                pp_t       = pp
                p_t        = p*24*60*60          ; unit mm/s to mm/day
                pp_t       = pp*24*60*60

                ptime      = p&time
                pptime      = pp&time

                plat       = p&lat
                plon       = p&lon
                
            print(i +"  " + model_name(i) + " Input done!")


            ; Post process (calculation)        
                ; Variables during the specified time span and location 
                    ; Finding the corresponing time position since diff var may have diff starting time
                        ; Prepcipitation
                            ptime_std  = cd_calendar(ptime, -1)
                            stbn1_p    = ind(ptime_std.eq.his_date_start) 
                            stbn2_p    = ind(ptime_std.eq.his_date_end)  

                            pptime_std = cd_calendar(pptime, -1)
                            stbn1_pp   = ind(pptime_std.eq.ssp_date_start) 
                            stbn2_pp   = ind(pptime_std.eq.ssp_date_end)  

                    ; Specified location and time span 
                        ; Prepcipitation
                            p_shift       = p_t(stbn1_p:stbn2_p,{latS:latN},{lonW:lonE})
                            pp_shift      = pp_t(stbn1_pp:stbn2_pp,{latS:latN},{lonW:lonE}) 

                    delete(p)

            ; time x lat x lon => time/12 x 12 x lat lon 
            ; translate monthly data to yearly data
                nttime1  = dimsizes(p_shift(:,0,0))
                nttime2  = dimsizes(pp_shift(:,0,0))
                nlat     = dimsizes(p_shift(0,:,0))
                nlon     = dimsizes(p_shift(0,0,:))

                p_shift_tran            = reshape(p_shift,(/nttime1/12,12,nlat,nlon/))
                p_shift_tran!0          = "time"
                p_shift_tran!1          = "mon"
                p_shift_tran!2          = "lat"
                p_shift_tran!3          = "lon"
                p_shift_tran&time       = p_shift&time(0:nttime1/12-1)
                p_shift_tran&lat        = p_shift&lat
                p_shift_tran&lon        = p_shift&lon
                p_shift_tran&mon        = (/1,2,3,4,5,6,7,8,9,10,11,12/)
                p_shift_tran@long_name= ""
                p_shift_tran@units= ""

                pp_shift_tran           = reshape(pp_shift,(/nttime2/12,12,nlat,nlon/))
                pp_shift_tran!0          = "time"
                pp_shift_tran!1          = "mon"
                pp_shift_tran!2          = "lat"
                pp_shift_tran!3          = "lon"
                pp_shift_tran&time       = pp_shift&time(0:nttime2/12-1)
                pp_shift_tran&lat        = pp_shift&lat
                pp_shift_tran&lon        = pp_shift&lon
                pp_shift_tran&mon        = (/1,2,3,4,5,6,7,8,9,10,11,12/)
                pp_shift_tran@long_name= ""
                pp_shift_tran@units= ""

                p_shift_NDJFM       = p_shift_tran(:,0:4,:,:)
                pp_shift_NDJFM      = pp_shift_tran(:,0:4,:,:)


                p_shift_NDJFM_ts    = dim_avg_n_Wrap(p_shift_NDJFM, 1)
                pp_shift_NDJFM_ts   = dim_avg_n_Wrap(pp_shift_NDJFM, 1)

                p_shift_NDJFM_mean  = dim_avg_n_Wrap(p_shift_NDJFM_ts, 0)
                pp_shift_NDJFM_mean = dim_avg_n_Wrap(pp_shift_NDJFM_ts, 0)

                p_shift_NDJFM_variance  = dim_variance_n(p_shift_NDJFM_ts, 0)
                pp_shift_NDJFM_variance = dim_variance_n(pp_shift_NDJFM_ts, 0)

            ; ssp - his
                diff_p    = p_shift_NDJFM_mean 
                diff_p    = pp_shift_NDJFM_mean - p_shift_NDJFM_mean 

                diff_p_mm(:,:,i) = diff_p

            ;********************************************************
            ; t test for two sample group (mean state check, p20)
            ;********************************************************
                tt                  = diff_p
                tt                  = 0.
                delete(tt@long_name)
                s_square           = (p_shift_NDJFM_variance*(nttime1/12-1) + pp_shift_NDJFM_variance*(nttime2/12-1))/(nttime1/12+nttime2/12-2)
                s                  =sqrt(s_square)
                tt                  = (p_shift_NDJFM_mean - pp_shift_NDJFM_mean)/(s*(12/nttime1+12/nttime2)^(1/2))

                diff_ttest(:,:,i) = tt
                diff_ttest@long_name= ""
                diff_ttest@units= ""

            end do
            print("Calculation done!")
            print(max(diff_ttest))
            print(min(diff_ttest))


            ; Plot
                wks     = gsn_open_wks("pdf","/glade/work/xinyang/program/Amazon/cmip6/pics/pr_NDJFM_diff")             ; open a ps plot
                nplots  = 14                   ; for numbers of plots
                plot    = new(nplots,graphic)
                poly    = new(nplots,graphic)
                splot    = new(nplots,graphic)

                ; 2nd
                    res2                              = True               ; plot mods desired
                    res2@gsnDraw                      = False
                    res2@gsnFrame                     = False              ; don't advance frame yet     

                    res2@cnFillOn                     = True               ; turn on color for contours
                    res2@cnLinesOn                    = False              ; turn off contour lines
                    res2@cnLineLabelsOn               = False              ; turn off contour line labels
                    res2@cnInfoLabelOn                = False 
                    
                    ;  Shaded
                    ;res2@gsn_Add_Cyclic               = False
                    ;res2@cnFillPalette                = "temp_19lev"       ; set the color map
                    res2@cnFillPalette                = "precip_diff_12lev"       ; set the color map
                    res2@lbLabelStride                = 2 
                    res2@mpFillOn                     = True
                    res2@mpLandFillColor              = "white"            ; set land to be gray

                    ;res2@mpMinLonF                    = lonW+deg                 ; select a subregion
                    ;res2@mpMaxLonF                    = lonE-deg
                    res2@mpMinLatF                    = latS 
                    res2@mpMaxLatF                    = latN
                    res2@tmXBMinorOn                  = True
                    res2@mpCenterLonF                 = 180

                    ;res2@lbLabelBarOn                 = True               ; turn off individual cb's
                    res2@lbLabelBarOn                 = False               ; turn off individual cb's
                    res2@lbOrientation                = "Horizontal"       ; vertical label bar
                    res2@pmLabelBarOrthogonalPosF     = 0.08               ; move label bar closer

                    res2@cnLevelSelectionMode         = "ManualLevels"     ; set manual contour levels
                    res2@cnMinLevelValF               = -2.1               ; set min contour level
                    res2@cnMaxLevelValF               = 2.1                ; set max contour level
                    res2@cnLevelSpacingF              = 0.3                ; set contour spacing        
     
                    ; Title
                    
                    ;res2@gsnLeftStringOrthogonalPosF = -0.001
                    res2@gsnStringFontHeightF         = 0.017
                    res2@gsnRightString               = ""

                    ; adding Amazon outline
                      pres                   = True
                      pres@gsLineColor       = "red"
                      pres@gsLineDashPattern = 0
                      pres@gsLineThicknessF  = 2

                ; ========================= stippling ==============================
                      sres0 = True                            ; res2 probability plots

                      sres0@gsnDraw             = False       ; Do not draw plot
                      sres0@gsnFrame            = False       ; Do not advance frome
                      sres0@cnFillOn            = False

                      
                      sres0@cnLevelSelectionMode =  "ExplicitLevels"       ; set explicit cnlev
                      ;sres0@cnLevels              = (/1.8, 1.9, 2.0/)
                      sres0@cnLevels              = (/-3,-1.645, 0, 1.645,3/)
                      ;sres0@cnLevelSelectionMode = "ManualLevels" ; set manual contour levels
                      ;sres0@cnMinLevelValF      = 1.5        ; set min contour level
                      ;sres0@cnMaxLevelValF      = 3.0        ; set max contour level
                      ;sres0@cnLevelSpacingF     = 0.1        ; set contour spacing

                      sres0@cnInfoLabelOn       = False       ; turn off info label

                      sres0@cnLinesOn           = False      ; do not draw contour lines
                      sres0@cnLineLabelsOn      = False       ; do not draw contour labels

                      sres0@cnFillScaleF        = 0.6         ; add extra density
                      ;sres0@gsnAddCyclic                = True            ; add cyclic point

                      

                      sopt     = True
                      sopt@gsnShadeFillType = "pattern"
                      sopt@gsnShadeLow = 17 
                      sopt@gsnShadeHigh = 17 
                      sopt@gsnShadeDotSizeF = 1                           ; make dots larger
                      

                do i = (r_start-1),(r_end-1)
                    res2@gsnLeftString                = model_name(i)
                    plot(i)     = gsn_csm_contour_map_ce(wks,diff_p_mm(:,:,i),res2)

                    poly(i)=gsn_add_shapefile_polylines(wks,plot(i),mpfilename,pres)

                    splot(i)   = gsn_csm_contour(wks,diff_ttest(:,:,i), sres0)
                    splot(i)   = gsn_contour_shade(splot(i), -1.645, 1.645, sopt)
                    overlay(plot(i), splot(i))
                end do

                ; create panel
                    resP                                = True                ; modify the panel plot
                    resP@gsnPanelFigureStrings          = (/"(a)","(b)","(c)","(d)","(e)","(f)","(g)","(h)","(i)","(j)","(k)","(l)","(m)","(n)"/)           ; add strings to panel
                    resP@gsnPanelFigureStringsJust      = "TopLeft"
                    resP@gsnPanelMainString             = "pr (unit: mm/d): NDJFM Mean (ssp585 - historical) "
                    resP@gsnPanelLabelBar               = True                ; add common colorbar
                    resP@gsnPanelRowSpec                = True                   ; tell panel what order to plot
                    resP@gsnPanelCenter                 = False
                    resP@lbLabelFontHeightF             = 0.007               ; make labels smaller

                    gsn_panel(wks,plot,(/3,3,3,3,2/),resP)               ; now draw as one plot

                    print("plot done!")
            end 


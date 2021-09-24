#!/bin/csh -f

    ## model: ACCESS-CM2   (1), ACCESS-ESM1-5 (2), BCC-CSM2-MR     (3), CAMS-CSM1-0   (4), 
    ##        CanESM5      (5), CESM2         (6), E3SM-1-0        (7), FGOALS-f3-L   (8),
    ##        GFDL-ESM4    (9), GISS-E2-1-G   (10), GISS-E2-1-H   (11), IPSL-CM6A-LR (12),
    ##        MIROC6      (13), MRI-ESM2-0    (14), NESM3         (15), NorESM2-MM    (16).  
    ##        MME : Multi‐model ensemble  

    #==============================================================================================
    set expname                = Amazon
    set scenario_1             = historical      # 185001-201412
    set scenario_2             = ssp585          # 201501-210012

    set r_start                = 1
    set r_end                  = 12

        # Variable
            set var            = mrsos                   # pr  , tos   
            set var_ID         = Lmon                 # Amon, Omon    

        # climatology
            set season         = Annual                  # MAM, SON, JJA, DJF, ANNUAL
            set season_n       = "0:11"                  # 0:2 or 0:11, depending on season or annual mean
            set his_date_start = 198101      # if "season" is DJF, the first month of beginning time should be 12(D) 
            set his_date_end   = 201412      # if "season" is DJF, the last month of ending time should be 11(N)
            set latN           = 55
            set latS           = -55 

        # Lat & Lon
            set lonW           = 0
            set lonE           = 360

        # deg is used to tune the range of longitude from (lonW + deg) to (lonW + deg) for plot     
            set deg            = 0


    # directory
    set mdir   = /glade/work/xinyang/program/${expname}/cmip6
    set dodir  = /glade/work/xinyang/program/${expname}/cmip6/data

        #mkdir ${mdir}/pics/${var}
        #mkdir ${mdir}/pics/${var}/${season}/
        rm -r ${mdir}/code/inside_code/${var}_${season}.ncl

cat > ${mdir}/code/inside_code/${var}_${season}.ncl << EOF
        ;*********************************************************
        load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
        load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
        load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
        load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
        ;*********************************************************
        begin
            ; parameters
                his_date_start = $his_date_start
                his_date_end   = $his_date_end
                latN           = $latN
                latS           = $latS
                lonW           = $lonW
                lonE           = $lonE
                ; deg is used to tune the range of longitude    
                deg            = $deg
                r_start        = ${r_start}
                r_end          = ${r_end}
                ;model_name     = (/"MME","ACCESS-CM2", "ACCESS-ESM1-5", "BCC-CSM2-MR", "CanESM5", "CESM2", "E3SM-1-0", "FGOALS-f3-L", "GFDL-ESM4", "IPSL-CM6A-LR", "MIROC6", "MRI-ESM2-0", "NorESM2-MM"/)
                model_name     = (/"MME","ACCESS-CM2", "ACCESS-ESM1-5", "BCC-CSM2-MR", "CanESM5", "CESM2", "E3SM-1-0", "GFDL-ESM4","IPSL-CM6A-LR","MIROC6", "MRI-ESM2-0", "NorESM2-MM"/)
               
                 
                mpfilename="/glade/work/xinyang/program/Amazon/mapdata/amazon_sensulatissimo_gmm_v1.shp"  

                fili_precip_1 = "${var}_${var_ID}_"+model_name+"_${scenario_1}_ensmean_1x1_185001-201412.nc"

                diri_1        = "/glade/work/xinyang/cmip6/${scenario_1}/post-process/ensmean/${var}/"+fili_precip_1
                
                ;;;;;; references
                fref          = addfile(diri_1(0),"r")
                p             = fref->${var}
                diff_p_mm     = new((/110,360,r_end/), typeof(p),p@_FillValue)
                delete(p)

                ; observation
                dir_mask    = "/glade/work/xinyang/datasets/mask/lsmask.nc"
                fm          = addfile(dir_mask,"r")
                t_mask      = short2flt(fm->mask(0,::1,:))    ; lat S to N
                dir_ob      = "/glade/work/xinyang/datasets/era5_land/volumetric_soil_water_layer_1.1981-2020.monthly.1x1.nc"
                fob         = addfile(dir_ob,"r")
                p_ob_t      = short2flt(fob->swvl1)    
                p_ob        = p_ob_t
                p_ob@long_name= ""
                p_ob@units  = ""
                p_ob        = p_ob_t*70   
                ;t_mask&lon  = p_ob_t&lon
                
                ptime_ob    = p_ob_t&time
                optime_std  = cd_calendar(ptime_ob, -1)
                stbn1_op    = ind(optime_std.eq.his_date_start) 
                stbn2_op    = ind(optime_std.eq.his_date_end) 
                p_shift_ob     = p_ob(stbn1_op:stbn2_op,{latS:latN},{lonW:lonE})
                tt_mask         = t_mask({latS:latN},{lonW:lonE})

                p_ob_shift_mean            = clmMonTLL(p_shift_ob)
                p_ob_shift_${season}       = p_ob_shift_mean(${season_n},:,:)
                p_ob_shift_${season}_mean  = dim_avg_n_Wrap(p_ob_shift_${season}, 0)
                ;p_ob_shift_${season}_mean  = where(tt_mask.eq.0,p_ob_shift_${season}_mean, p_ob_t@_FillValue) 

            do i = (r_start-1),(r_end-1)
                ;i=0
                file1      = addfile(diri_1(i),"r")
                p          = file1->${var}     ;unit: C  
                p_t        = p        ; unit kg/m^2 -> mm
                ;p_t        = where(t_mask.eq.0,p_t, p_t@_FillValue)
                ptime      = p&time


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


                    ; Specified location and time span 
                        ; Prepcipitation
                            p_shift       = p_t(stbn1_p:stbn2_p,{latS:latN},{lonW:lonE})


                    delete(p)

            ; Remove annual cycle
                ; Prepcipitation
                    p_shift_mean            = clmMonTLL(p_shift)
                    p_shift_${season}       = p_shift_mean(${season_n},:,:)
                    p_shift_${season}_mean  = dim_avg_n_Wrap(p_shift_${season}, 0)


            ; ssp - his
                diff_p    = p_shift_${season}_mean 
                diff_p    = where(tt_mask.eq.0,diff_p, p_t@_FillValue) 


                diff_p_mm(:,:,i) = diff_p
                diff_p_mm@long_name= ""
                diff_p_mm@units= ""

            end do
            ;diff_p = diff_p_mm(:,:,7)*100
            ;diff_p_mm(:,:,7) = diff_p
            print("Calculation done!")


            ; Plot
                wks     = gsn_open_wks("pdf","${mdir}/pics/${var}_${season}_${scenario_1}")             ; open a ps plot
                nplots  = ${r_end}+1                   ; for numbers of plots
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
                    ;res2@cnFillPalette                = "CBR_drywet"       ; set the color map
                    ;res2@cnFillPalette                = "CBR_wet"       ; set the color map
                    res2@cnFillPalette                = "CBR_drywet"       ; set the color map
                    res2@lbLabelStride                = 2 
                    res2@mpFillOn                     = True
                    res2@mpLandFillColor              = "white"            ; set land to be gray

                    ;res2@mpMinLatF                    = latS 
                    ;res2@mpMaxLatF                    = latN
                    ;res2@tmXBMinorOn                  = True
                    ;res2@mpCenterLonF                 = 180
                    ;==============Amazon========================
                    res2@mpMinLonF                    = -120                 ; select a subregion
                    res2@mpMaxLonF                    = 0
                    res2@mpMinLatF                    = latS 
                    res2@mpMaxLatF                    = 35
                    res2@tmXBMinorOn                  = True
                    res2@mpCenterLonF                 = -60
                    ;============================================


                    ;res2@lbLabelBarOn                 = True               ; turn off individual cb's
                    res2@lbLabelBarOn                 = False               ; turn off individual cb's
                    res2@lbOrientation                = "Horizontal"       ; vertical label bar
                    res2@pmLabelBarOrthogonalPosF     = 0.08               ; move label bar closer

                    res2@cnLevelSelectionMode         = "ManualLevels"     ; set manual contour levels
                    res2@cnMinLevelValF               = 10               ; set min contour level
                    res2@cnMaxLevelValF               = 32                ; set max contour level
                    res2@cnLevelSpacingF              = 2                ; set contour spacing        
     
                    ; Title
                    res2@gsnLeftString                = "${scenario_1}: ${his_date_start}-${his_date_end} "
                    ;res2@gsnLeftStringOrthogonalPosF = -0.001
                    res2@gsnStringFontHeightF         = 0.022
                    res2@gsnRightString               = ""

                    ; adding Amazon outline
                      pres                   = True
                      pres@gsLineColor       = "red"
                      pres@gsLineDashPattern = 0
                      pres@gsLineThicknessF  = 2
                      
                do i = (r_start-1),(r_end-1)
                    res2@gsnLeftString                = model_name(i)
                    plot(i+1) = gsn_csm_contour_map_ce(wks,diff_p_mm(:,:,i),res2)

                    poly(i+1) = gsn_add_shapefile_polylines(wks,plot(i+1),mpfilename,pres)
                end do

                res2@gsnLeftString                = "Reanalysis"
                plot(0) = gsn_csm_contour_map_ce(wks,p_ob_shift_${season}_mean,res2)
                poly(0) = gsn_add_shapefile_polylines(wks,plot(0),mpfilename,pres)

                ; create panel
                    resP                                = True                ; modify the panel plot
                    resP@gsnPanelFigureStrings          = (/"(a)","(b)","(c)","(d)","(e)","(f)","(g)","(h)","(i)","(j)","(k)","(l)","(m)","(n)"/)           ; add strings to panel
                    resP@gsnPanelFigureStringsFontHeightF = 0.01
                    resP@gsnPanelFigureStringsJust      = "TopLeft" 
                    resP@gsnPanelMainString             = "${var} (unit: mm): ${season} Mean (${his_date_start}-${his_date_end})"
                    resP@gsnPanelMainFontHeightF        = 0.01
                    resP@gsnPanelLabelBar               = True                ; add common colorbar
                    resP@gsnPanelRowSpec                = True                   ; tell panel what order to plot
                    resP@gsnPanelCenter                 = False
                    resP@lbLabelFontHeightF             = 0.007               ; make labels smaller

                    gsn_panel(wks,plot,(/4,4,4,4/),resP)               ; now draw as one plot

                    print("plot done!")
            end 

EOF

        ncl ${mdir}/code/inside_code/${var}_${season}.ncl


    echo "well done, Teresa, I deeply love you!"



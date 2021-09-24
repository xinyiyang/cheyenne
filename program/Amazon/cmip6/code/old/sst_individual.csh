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
    set model_name             = (ACCESS-CM2 ACCESS-ESM1-5 BCC-CSM2-MR CanESM5 CESM2 E3SM-1-0 FGOALS-f3-L GFDL-ESM4 IPSL-CM6A-LR MIROC6 MRI-ESM2-0 NESM3 NorESM2-MM MME)
    set r_start                = 1
    set r_end                  = 14

        # Variable
            set var            = tos                   # pr  , tos   
            set var_ID         = Omon                 # Amon, Omon    

        # climatology
            set season         = Annual                  # MAM, SON, JJA, DJF, ANNUAL
            set season_n       = "0:11"                  # 0:2 or 0:11, depending on season or annual mean
            set his_date_start = 185001      # if "season" is DJF, the first month of beginning time should be 12(D) 
            set his_date_end   = 201412      # if "season" is DJF, the last month of ending time should be 11(N)
            set ssp_date_start = 201501      
            set ssp_date_end   = 210012
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

    # loop
    foreach ii (`seq -f "%01g" $r_start  $r_end`)
        echo $ii
        set model             = ${model_name[$ii]}
        echo $model 

        mkdir ${mdir}/pics/${var}
        mkdir ${mdir}/pics/${var}/${season}/
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
                ssp_date_start = $ssp_date_start
                ssp_date_end   = $ssp_date_end
                latN       = $latN
                latS       = $latS
                lonW       = $lonW
                lonE       = $lonE
                ; deg is used to tune the range of longitude    
                deg        = $deg
               
               ; input   
                mpfilename="/glade/work/xinyang/program/Amazon/mapdata/amazon_sensulatissimo_gmm_v1.shp"   
                
                diri_1        = "/glade/work/xinyang/cmip6/${scenario_1}/post-process/ensmean/${var}/"
                diri_2        = "/glade/work/xinyang/cmip6/${scenario_2}/post-process/ensmean/${var}/"
                
                fili_precip_1 = "${var}_${var_ID}_${model}_${scenario_1}_ensmean_1x1_185001-201412.nc"
                fili_precip_2 = "${var}_${var_ID}_${model}_${scenario_2}_ensmean_1x1_201501-210012.nc"


                file1      = addfile(diri_1+fili_precip_1,"r")
                file2      = addfile(diri_2+fili_precip_2,"r")
                p          = file1->${var}     ;unit: Deg C  
                pp         = file2->${var}     ;unit: Deg C  
                p_t        = p
                pp_t       = pp
                p_t        = p*1         ; unit: Deg C
                pp_t       = pp*1

                ptime      = p&time
                pptime      = pp&time

                plat       = p&lat
                plon       = p&lon
                

            print("Input done!")


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

            ; Remove annual cycle
                ; Prepcipitation
                    p_shift_mean            = clmMonTLL(p_shift)
                    p_shift_${season}       = p_shift_mean(${season_n},:,:)
                    p_shift_${season}_mean  = dim_avg_n_Wrap(p_shift_${season}, 0)

                    pp_shift_mean           = clmMonTLL(pp_shift)
                    pp_shift_${season}      = pp_shift_mean(${season_n},:,:)
                    pp_shift_${season}_mean = dim_avg_n_Wrap(pp_shift_${season}, 0)

            ; ssp - his
                diff_p = p_shift_${season}_mean 
                diff_p = pp_shift_${season}_mean - p_shift_${season}_mean 

            print("Calculation done!")


            ; Plot
                wks     = gsn_open_wks("pdf","${mdir}/pics/${var}/${season}/${model}")             ; open a ps plot
                nplots  = 3                   ; for numbers of plots
                plot    = new(nplots,graphic)

                ; 1st
                    res1                              = True               ; plot mods desired
                    res1@gsnDraw                      = False
                    res1@gsnFrame                     = False              ; don't advance frame yet     

                    res1@cnFillOn                     = True               ; turn on color for contours
                    res1@cnLinesOn                    = False              ; turn off contour lines
                    res1@cnLineLabelsOn               = False              ; turn off contour line labels
                    res1@cnInfoLabelOn                = False 
                    
                    ;  Shaded
                    ;res1@gsn_Add_Cyclic              = False
                    res1@cnFillPalette                = "precip3_16lev"       ; set the color map
                    ;res1@cnFillPalette               = "gui_default"       ; set the color map
                    res1@lbLabelStride                = 2 
                    res1@mpFillOn                     = True
                    res1@mpLandFillColor              = "white"            ; set land to be gray

                    ;res1@mpMinLonF                    = lonW+deg                 ; select a subregion
                    ;res1@mpMaxLonF                    = lonE-deg
                    res1@mpMinLatF                    = latS 
                    res1@mpMaxLatF                    = latN
                    res1@tmXBMinorOn                  = True
                    res1@mpCenterLonF                 = 180

                    res1@lbLabelBarOn                 = True               ; turn off individual cb's
                    res1@lbOrientation                = "Horizontal"       ; vertical label bar
                    res1@pmLabelBarOrthogonalPosF     = 0.08               ; move label bar closer

                    res1@cnLevelSelectionMode         = "ManualLevels"     ; set manual contour levels
                    res1@cnMinLevelValF               = 20               ; set min contour level
                    res1@cnMaxLevelValF               = 30                ; set max contour level
                    res1@cnLevelSpacingF              = 0.5                ; set contour spacing        

                    ; Title
                    res1@gsnLeftString                = "${scenario_1}: ${his_date_start}-${his_date_end} "
                    ;res1@gsnLeftStringOrthogonalPosF = -0.001
                    res1@gsnStringFontHeightF         = 0.017
                    res1@gsnRightString               = ""

                    plot(1)     = gsn_csm_contour_map(wks,p_shift_${season}_mean(:,:),res1)

                    res1@gsnLeftString                = "${scenario_2}: ${ssp_date_start}-${ssp_date_end} "
                    plot(2)     = gsn_csm_contour_map(wks,pp_shift_${season}_mean(:,:),res1)



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
                    res2@cnFillPalette                = "GMT_no_green"       ; set the color map
                    res2@lbLabelStride                = 2 
                    res2@mpFillOn                     = True
                    res2@mpLandFillColor              = "white"            ; set land to be gray

                    ;res2@mpMinLonF                    = lonW+deg                 ; select a subregion
                    ;res2@mpMaxLonF                    = lonE-deg
                    res2@mpMinLatF                    = latS 
                    res2@mpMaxLatF                    = latN
                    res2@tmXBMinorOn                  = True
                    res2@mpCenterLonF                 = 180

                    res2@lbLabelBarOn                 = True               ; turn off individual cb's
                    res2@lbOrientation                = "Horizontal"       ; vertical label bar
                    res2@pmLabelBarOrthogonalPosF     = 0.08               ; move label bar closer

                    res2@cnLevelSelectionMode         = "ManualLevels"     ; set manual contour levels
                    res2@cnMinLevelValF               = 0               ; set min contour level
                    res2@cnMaxLevelValF               = 4                ; set max contour level
                    res2@cnLevelSpacingF              = 0.5                ; set contour spacing        
     
                    ; Title
                    res2@gsnLeftString                = "${scenario_2} - ${scenario_1} "
                    ;res2@gsnLeftStringOrthogonalPosF = -0.001
                    res2@gsnStringFontHeightF         = 0.017
                    res2@gsnRightString               = ""

                    plot(0)     = gsn_csm_contour_map_ce(wks,diff_p(:,:),res2)

                    ; adding Amazon outline
                      pres                   = True
                      pres@gsLineColor       = "black"
                      pres@gsLineDashPattern = 0
                      pres@gsLineThicknessF  = 2
                      poly1=gsn_add_shapefile_polylines(wks,plot(0),mpfilename,pres)
                      poly2=gsn_add_shapefile_polylines(wks,plot(1),mpfilename,pres)
                      poly3=gsn_add_shapefile_polylines(wks,plot(2),mpfilename,pres)
                    

                ; create panel
                    resP                     = True                ; modify the panel plot
                    ;resP@lbTitleString       = 
                    resP@gsnPanelMainString = "${model}: ${var} ${season} Mean (unit: Deg C)"
                    ;resP@gsnPanelLabelBar    = False                ; add common colorbar
                    resP@lbLabelFontHeightF  = 0.007               ; make labels smaller

                    gsn_panel(wks,plot,(/3,1/),resP)               ; now draw as one plot

                    print("plot done!")
            end 

EOF

        ncl ${mdir}/code/inside_code/${var}_${season}.ncl

        echo $model "finish" 

    end

    echo "well done, Teresa, I deeply love you!"



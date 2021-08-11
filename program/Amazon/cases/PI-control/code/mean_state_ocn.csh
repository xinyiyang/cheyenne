#!/bin/csh -f
 # seasonal composite pattern SSTA, UV, Precip over Amazonia region

    #==============================================================================================
    set expname         = Amazon
    set CASE            = PI-control

    # set type, time period, lat & lon, dataset, UV level
        # type 
            set type       = mean_pattern         # mean_pattern
            set variable   = ocn_var              
        # climatology
            set season     = ANNUAL                  # MAM, SON, JJA, DJF, ANNUAL
            set season_n   = "0:11"                # 0:2 or 0:11, depending on season or annual mean
            set date_start = 106      # if "season" is DJF, the first month of beginning time should be 12(D) 
            set date_end   = 3505     # if "season" is DJF, the last month of ending time should be 11(N)
            set timespan   = "01-35"              # 01-05 or 06-35
            # for plotting
            set lat_range  = "-2:2"
            set lon_range  = "130:280"
        # Lat & Lon
            set latN       = 55
            set latS       = -55
            set lonW       = 0
            set lonE       = 360
        # UV level
            set uvlev      = 850
        # deg is used to tune the range of longitude from (lonW + deg) to (lonW + deg) for plot     
            set deg        = 0

    # directory
        # main directory
            set mdir   = /glade/work/xinyang/program/$expname/cases/$CASE
            set dodir  = /glade/work/xinyang/program/$expname/cases/$CASE

    #==============================================================================================
    rm -r ${mdir}/code/inside_code/${type}_${variable}_${season}.ncl
    # composite of ssta, uv and precip for specific events and plot

    cat > ${mdir}/code/inside_code/${type}_${variable}_${season}.ncl << EOF
    ;*********************************************************
    load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
    load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
    load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
    load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
    ;*********************************************************
    begin

        ; parameters
            ;date_start = 603 ;$date_start
            ;date_end   = 3502;$date_end
            ;latN       = 55;$latN
            ;latS       = -55;$latS
            ;lonW       = 0;$lonW
            ;lonE       = 360;$lonE
            ;uvlev      = 850;$uvlev
            ; deg is used to tune the range of longitude    
            ;deg        = 0;$deg

            date_start = $date_start
            date_end   = $date_end
            latN       = $latN
            latS       = $latS
            lonW       = $lonW
            lonE       = $lonE
            uvlev      = $uvlev
            ; deg is used to tune the range of longitude    
            deg        = $deg
           
           ; input      
            diri        = "/glade/work/xinyang/experiment/program/$expname/$CASE/post-process/"
            
            fili_sst    = "ocn/TEMP.$CASE.pop.h.${timespan}.1x1d.nc"
            fili_precip = "ocn/TEMP.$CASE.pop.h.${timespan}.1x1d.nc"
            fili_u      = "ocn/UVEL.$CASE.pop.h.${timespan}.1x1d.nc"
            fili_v      = "ocn/WVEL.$CASE.pop.h.${timespan}.1x1d.nc"


            file1      = addfile(diri+fili_sst,"r")
            t          = file1->TEMP(:,0,:,:)
            stime      = t&time
            slon       = t&lon
            slat       = t&lat
            
            file2      = addfile(diri+fili_u,"r")
            u          = file2->UVEL(:,:,:,:)
            u          = u/100 ; cm/s to m/s
            wlat       = u&lat
            wlon       = u&lon
            wtime      = u&time

            file3      = addfile(diri+fili_v,"r")       
            v          = file3->WVEL(:,:,:,:)
            v          = v/100 ; cm/s to m/s

        ; Precipitation
            file5      = addfile(diri+fili_precip,"r")
            pc         = file5->TEMP(:,:,:,:)
            ; 
            pcl        = pc 
            p          = pc
            p          = pcl 
            plat       = p&lat
            plon       = p&lon
            ptime      = p&time

        print("Input done!")


        ; Post process (calculation)        
            ; Variables during the specified time span and location 
                ; Finding the corresponing time position since diff var may have diff starting time
                    ; sst
                        stime_std = cd_calendar(stime, -1)
                        stbn1_t   = ind(stime_std.eq.date_start) 
                        stbn2_t   = ind(stime_std.eq.date_end) 
                    ; U & V 
                        wtime_std = cd_calendar(wtime, -1)
                        stbn1_w   = ind(wtime_std.eq.date_start) 
                        stbn2_w   = ind(wtime_std.eq.date_end)
                    ; Prepcipitation
                        ptime_std = cd_calendar(ptime, -1)
                        stbn1_p   = ind(ptime_std.eq.date_start) 
                        stbn2_p   = ind(ptime_std.eq.date_end)   

                ; Specified location and time span 
                    ; SST
                        t_shift_tran  = t(stbn1_t:stbn2_t,{latS:latN},{lonW:lonE}) ; used to copy VarCoords 
                        t_shift       = t_shift_tran
                        t_shift       = t(stbn1_t:stbn2_t,{latS:latN},{lonW:lonE}) 
                    ; U & V 
                        u_shift       = u(stbn1_w:stbn2_w,:,{latS:latN},{lonW:lonE})
                        v_shift       = v(stbn1_w:stbn2_w,:,{latS:latN},{lonW:lonE})
                    ; Prepcipitation
                        p_shift       = p(stbn1_p:stbn2_p,:,{latS:latN},{lonW:lonE}) 
                delete(t)
                delete(u)
                delete(v)
                delete(p)

        ; Remove annual cycle
            ; SST
                t_shift_mean           = clmMonTLL(t_shift)
                t_shift_${season}      = t_shift_mean(${season_n},:,:)
                t_shift_${season}_mean = dim_avg_n_Wrap(t_shift_${season}, 0)
            ; U & V 
                u_shift_mean       = clmMonTLLL(u_shift)
                u_shift_${season}  = u_shift_mean(${season_n},:,:,:)
                u_shift_${season}_mean1 = dim_avg_n_Wrap(u_shift_${season}, 0)

                v_shift_mean       = clmMonTLLL(v_shift)
                v_shift_${season}  = v_shift_mean(${season_n},:,:,:)
                v_shift_${season}_mean1 = dim_avg_n_Wrap(v_shift_${season}, 0)

            ; Prepcipitation
                p_shift_mean       = clmMonTLLL(p_shift)
                p_shift_${season}  = p_shift_mean(${season_n},:,:,:)
                p_shift_${season}_mean1 = dim_avg_n_Wrap(p_shift_${season}, 0)

        ; size 
            ; SST size
                nttime  = dimsizes(t_shift(:,0,0))
                ntlat   = dimsizes(t_shift(0,:,0))
                ntlon   = dimsizes(t_shift(0,0,:))

            ; U & V size
                nwtime  = dimsizes(u_shift(:,0,0,0))
                nwlev   = dimsizes(u_shift(0,:,0,0))
                nwlat   = dimsizes(u_shift(0,0,:,0))
                nwlon   = dimsizes(u_shift(0,0,0,:))
            ; Prepcipitation
                nptime  = dimsizes(p_shift(:,0,0,0))
                nplev   = dimsizes(p_shift(0,:,0,0))
                nplat   = dimsizes(p_shift(0,0,:,0))
                nplon   = dimsizes(p_shift(0,0,0,:))

        ; Copy VarCoords nyear x 12 x lat x lon
                ; SST 
                    t_tran  = reshape(t_shift,(/nttime/12,12,ntlat,ntlon/)) ; Since we shifted the Dec to be the first month of year, we lost the original Jan(0)-Nov(0), and Dec(end), in total, we lost one year data. 
                ; U & V
                    u_tran  = reshape(u_shift,(/nwtime/12,12,nwlev,nwlat,nwlon/))
                    v_tran  = reshape(v_shift,(/nwtime/12,12,nwlev,nwlat,nwlon/))
                ; Prepcipitation
                    p_tran  = reshape(p_shift,(/nptime/12,12,nplev,nplat,nplon/))

        ;  specifc months and average 
                t_tran1     = t_tran(:,${season_n},:,:)
                u_tran1     = u_tran(:,${season_n},:,:,:)
                v_tran1     = v_tran(:,${season_n},:,:,:)
                p_tran1     = p_tran(:,${season_n},:,:,:)

                t_tran_use   = dim_avg_n_Wrap(t_tran1, 1)
                u_tran_use1  = dim_avg_n_Wrap(u_tran1, 1)
                v_tran_use1  = dim_avg_n_Wrap(v_tran1, 1)
                p_tran_use1  = dim_avg_n_Wrap(p_tran1, 1)

                nmyear = dimsizes(t_tran_use(:,0,0))
                copy_VarCoords(t_shift(0:nmyear-1,:,:),t_tran_use)
                copy_VarCoords(u_shift(0:nmyear-1,:,:,:),u_tran_use1)
                copy_VarCoords(v_shift(0:nmyear-1,:,:,:),v_tran_use1)
                copy_VarCoords(p_shift(0:nmyear-1,:,:,:),p_tran_use1)
        ; lev-lon plot 
            u_tran_use  = dim_avg_n_Wrap(u_tran_use1(:,:,{$lat_range},{$lon_range}), 2)
            v_tran_use  = dim_avg_n_Wrap(v_tran_use1(:,:,{$lat_range},{$lon_range}), 2)
            p_tran_use  = dim_avg_n_Wrap(p_tran_use1(:,:,{$lat_range},{$lon_range}), 2)

            u_shift_${season}_mean = dim_avg_n_Wrap(u_shift_${season}_mean1(:,{$lat_range},{$lon_range}),1)
            v_shift_${season}_mean = dim_avg_n_Wrap(v_shift_${season}_mean1(:,{$lat_range},{$lon_range}),1)
            p_shift_${season}_mean = dim_avg_n_Wrap(p_shift_${season}_mean1(:,{$lat_range},{$lon_range}),1)


        print("Calculation done!")

        ; ------------------- output data ----------------
        datafile1 = "${mdir}/data/${CASE}.ocn.${type}_${season}.nc"
        system("rm -rf "+datafile1)
        fout1 =addfile(datafile1,"c")
        fout1@title ="composite of sst uv precip"
        filedimdef(fout1,"time",-1,True)
        fout1->t_tran_use=t_tran_use
        fout1->t_shift_${season}_mean=t_shift_${season}_mean

        datafile2 = "${mdir}/data/${CASE}.ocn.2S2N_ave.${type}_${season}.nc"
        system("rm -rf "+datafile2)
        fout2 =addfile(datafile2,"c")
        fout2@title ="composite of sst uv precip"
        filedimdef(fout2,"time",-1,True)

        fout2->u_tran_use=u_tran_use
        fout2->v_tran_use=v_tran_use
        fout2->p_tran_use=p_tran_use

        fout2->u_shift_${season}_mean=u_shift_${season}_mean
        fout2->v_shift_${season}_mean=v_shift_${season}_mean
        fout2->p_shift_${season}_mean=p_shift_${season}_mean

        print("Output done!")


        ; Plot
            wks     = gsn_open_wks("eps","${mdir}/pics/${type}_${variable}_${season}")             ; open a ps plot
            nplots  = 3                   ; for numbers of plots
            plot    = new(nplots,graphic)
            nnplots = 2                   ; for numbers of vectors
            vectors = new(nnplots,graphic)

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
                res1@cnFillPalette                = "BlAqGrYeOrRe"       ; set the color map
                ;res1@cnFillPalette               = "BlAqGrYeOrRe"       ; set the color map
                res1@lbLabelStride                = 2 
                res1@mpFillOn                     = True
                res1@mpLandFillColor              = "white"            ; set land to be gray

                ;res1@mpMinLonF                    = lonW+deg                 ; select a subregion
                ;res1@mpMaxLonF                    = lonE-deg
                res1@mpMinLatF                    = latS 
                res1@mpMaxLatF                    = latN
                res1@tmXBMinorOn                  = True
                res1@mpCenterLonF                 = 180

                ;res1@vpHeightF   = 0.3
                ;res1@vpWidthF    = 0.7
                res1@vpXF        = 0.35
                res1@vpYF        = 0.9


                res1@lbLabelBarOn                 = True               ; turn off individual cb's
                res1@lbOrientation                = "Horizontal"       ; vertical label bar
                res1@pmLabelBarOrthogonalPosF     = 0.08               ; move label bar closer

                res1@cnLevelSelectionMode         = "ManualLevels"     ; set manual contour levels
                res1@cnMinLevelValF               = 16               ; set min contour level
                res1@cnMaxLevelValF               = 30                ; set max contour level
                res1@cnLevelSpacingF              = 1                ; set contour spacing        

                vcres1 = True
                vcres1@gsnDraw                    = False               ; don't draw yet
                vcres1@gsnFrame                   = False               ; don't ad vance frame yet
                vcres1@vcRefAnnoOn                = True                ; will draw the reference  vector annotation
                vcres1@vcRefAnnoString2On         = False               ; will not display a string below 
                vcres1@vcRefAnnoPerimOn           = False               ; no outline will be drawn
                vcres1@vcRefAnnoSide              = "top"
                vcres1@vcRefAnnoOrthogonalPosF    = -0.37
                vcres1@vcRefAnnoParallelPosF      = 0.98                ;set the X-axis position of annotation 
                vcres1@vcRefLengthF               = 0.02
                vcres1@vcRefMagnitudeF            = 8 
                vcres1@vcRefAnnoString1On         = True
                vcres1@vcRefAnnoString1           = "8 m/s"              ;"1.5m/s"
                vcres1@vcGlyphStyle               = "LineArrow"      ;"LineArrow","Curly Vector"
                vcres1@vcLineArrowThicknessF      = 0.9
                vcres1@vcMinDistanceF             = 0.014
                vcres1@vcLineArrowColor           = "grey39"
                vcres1@gsnRightString             = ""
                vcres1@gsnLeftString              = ""
                vcres1@vcVectorDrawOrder          = "PostDraw" 
                ; Title
                res1@gsnLeftString                = "mean SST (${season}) "
                ;res1@gsnLeftStringOrthogonalPosF = -0.001
                res1@gsnStringFontHeightF         = 0.014
                res1@gsnRightString               = ""
                res1@gsnMaximize          = False          ; maximize plot size
                ;res1@tiYAxisString        = "Depth(m)"  
                ;res1@tiYAxisFontColor     = 1


                plot(1)     = gsn_csm_contour_map_ce(wks,t_shift_${season}_mean(:,:),res1)
                ;vectors(0)  = gsn_csm_vector(wks,u_shift_${season}_mean(:,:),v_shift_${season}_mean(:,:),vcres1) 
                ;overlay(plot(0),vectors(0))                            ; result will be plotA
                ;plot(0) = plot(0)                                      ; now assign plotA to array


            ; 2nd

                res2                              = True               ; plot mods desired
                res2@gsnDraw                      = False
                res2@gsnFrame                     = False              ; don't advance frame yet     

                res2@cnFillOn                     = True               ; turn on color for contours
                res2@cnLinesOn                    = False              ; turn off contour lines
                res2@cnLineLabelsOn               = False              ; turn off contour line labels
                res2@cnInfoLabelOn                = False 

                res2@vpHeightF   = 0.28
                res2@vpWidthF    = 0.8
                res2@vpXF        = res1@vpXF
                ;res2@vpYF        = 0.9

                res2@cnLevelSelectionMode = "ManualLevels"       ; manually select levels
                res2@cnLevelSpacingF      = 2                  ; contour spacing
                res2@cnMinLevelValF       = 12                  ; min level
                res2@cnMaxLevelValF       =  28                 ; max level
                res2@cnLineLabelsOn       = True                 ; turn on line labels
                res2@cnFillOn             = True                 ; turn on color fill
                res2@cnFillPalette        = "GMT_panoply"      ; choose colormap
                res2@tmYRMode             = "Automatic"          ; turn off special labels on right axis
                res2@trYReverse = True      ; reverse the Y-axis
                             
                res2@lbOrientation                 = "Horizontal"     ; vertical label bar
                res2@pmLabelBarOrthogonalPosF      = 0.005          ; move label bar closer
                res2@lbTitleFontHeightF            =0.015
                res2@lbTitleFontThicknessF         =0.02
         
                ;res2@gsnMaximize         = False          ; maximize plot size

                ; Title
                res2@gsnLeftString                = "mean Temp (2S to 2N) (${season}) "
                ;res2@gsnLeftStringOrthogonalPosF = -0.001
                res2@tiXAxisFontHeightF = 0.01
                res2@gsnStringFontHeightF = 0.014
                res2@gsnRightString               = ""   
                res2@tmXBLabelFontHeightF         =0.007      
                res2@tiYAxisString        = "Depth (m)"     
                ;res2@tiYAxisFontHeightF   = 0.01 

                vcres2 = True
                vcres2@gsnDraw                    = False               ; don't draw yet
                vcres2@gsnFrame                   = False               ; don't ad vance frame yet
                vcres2@vcRefAnnoOn                = True                ; will draw the reference  vector annotation
                vcres2@vcRefAnnoString2On         = False               ; will not display a string below 
                vcres2@vcRefAnnoPerimOn           = False               ; no outline will be drawn
                vcres2@vcRefAnnoSide              = "top"
                vcres2@vcRefAnnoOrthogonalPosF    = -0.37
                vcres2@vcRefAnnoParallelPosF      = 0.98                ;set the X-axis position of annotation 
                vcres2@vcRefLengthF               = 0.02
                vcres2@vcRefMagnitudeF            = 0.2 
                vcres2@vcRefAnnoString1On         = True
                vcres2@vcRefAnnoString1           = "0.2 m/s"              ;"1.5m/s"
                vcres2@vcGlyphStyle               = "LineArrow"      ;"LineArrow","Curly Vector"
                vcres2@vcLineArrowThicknessF      = 0.9
                vcres2@vcMinDistanceF             = 0.014
                vcres2@vcLineArrowColor           = "grey39"
                vcres2@gsnRightString             = ""
                vcres2@gsnLeftString              = ""
                vcres2@vcVectorDrawOrder          = "PostDraw" 
                vcres2@vcMinDistanceF              =0.032
                plot(0)     = gsn_csm_contour(wks,p_shift_${season}_mean(:,:),res2)
                v_shift_${season}_mean_big=v_shift_${season}_mean(:,:)
                v_shift_${season}_mean_big=v_shift_${season}_mean(:,:)*40000

                vectors(0)  = gsn_csm_vector(wks,u_shift_${season}_mean(:,:),v_shift_${season}_mean_big(:,:),vcres2) 
                overlay(plot(0),vectors(0))                            ; result will be plotA
                 ;plot(0) = plot(0)                                      ; now assign plotA to array                


            ; 3nd

                res3                              = True               ; plot mods desired
                res3@gsnDraw                      = False
                res3@gsnFrame                     = False              ; don't advance frame yet     

                res3@cnFillOn                     = True               ; turn on color for contours
                res3@cnLinesOn                    = False              ; turn off contour lines
                res3@cnLineLabelsOn               = False              ; turn off contour line labels
                res3@cnInfoLabelOn                = False 

                res3@vpHeightF   = 0.28
                res3@vpWidthF    = 0.8
                res3@vpXF        = res1@vpXF
                ;res3@vpYF        = 0.9

                ;res3@cnLevelSelectionMode = "ManualLevels"       ; manually select levels
                ;res3@cnLevelSpacingF      = 2                  ; contour spacing
                ;res3@cnMinLevelValF       = 12                  ; min level
                ;res3@cnMaxLevelValF       =  28                 ; max level
                
                res3@cnLineLabelsOn       = True                 ; turn on line labels
                res3@cnFillOn             = True                 ; turn on color fill
                res3@cnFillPalette        = "GMT_panoply"      ; choose colormap
                res3@tmYRMode             = "Automatic"          ; turn off special labels on right axis
                res3@trYReverse = True      ; reverse the Y-axis
                             
                res3@lbOrientation                 = "Horizontal"     ; vertical label bar
                res3@pmLabelBarOrthogonalPosF      = 0.005          ; move label bar closer
                res3@lbTitleFontHeightF            =0.015
                res3@lbTitleFontThicknessF         =0.02
         
                ;res3@gsnMaximize         = False          ; maximize plot size
                ; Title
                res3@gsnLeftString                = "mean Temp (2S to 2N) (${season}) "
                ;res3@gsnLeftStringOrthogonalPosF = -0.001
                res3@tiXAxisFontHeightF = 0.01
                res3@gsnStringFontHeightF = 0.014
                res3@gsnRightString               = ""   
                res3@tmXBLabelFontHeightF         =0.007      
                res3@tiYAxisString        = "Depth (m)"     
                ;res3@tiYAxisFontHeightF   = 0.01 
                plot(2)     = gsn_csm_contour(wks,v_shift_${season}_mean_big(:,:),res3)

            ; create panel
                resP                     = True                ; modify the panel plot
                ;resP@gsnPanelMainString = "A plot with a common label bar"
                ;resP@gsnPanelLabelBar    = False                ; add common colorbar
                resP@gsnPanelYWhiteSpacePercent = 2

                resP@gsnPanelXWhiteSpacePercent = 2
                resP@lbLabelFontHeightF  = 0.007               ; make labels smaller
                ;resP@gsnMaximize = True

                gsn_panel(wks,plot,(/3,1/),resP)               ; now draw as one plot

                print("plot done!")
    end

EOF

ncl ${mdir}/code/inside_code/${type}_${variable}_${season}.ncl

echo "well done, Teresa, I deeply love you!"

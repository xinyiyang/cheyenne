    ;*********************************************************
    load "/glade/u/apps/dav/opt/ncl/6.6.2/intel/19.0.5//lib/ncarg/nclscripts/csm/gsn_code.ncl"
    load "/glade/u/apps/dav/opt/ncl/6.6.2/intel/19.0.5//lib/ncarg/nclscripts/csm/gsn_csm.ncl"
    load "/glade/u/apps/dav/opt/ncl/6.6.2/intel/19.0.5//lib/ncarg/nclscripts/csm/contributed.ncl"
    load "/glade/u/apps/dav/opt/ncl/6.6.2/intel/19.0.5//lib/ncarg/nclscripts/csm/shea_util.ncl"
    ;*********************************************************
    begin
        ; parameters
            latN       = 55
            latS       = -55
            lonW       = 0
            lonE       = 360
            uvlev      = 850
            ; deg is used to tune the range of longitude    
            deg        = 0
           
           ; input
            ; case_1      
                diri_1          = "/glade/work/xinyang/program/Amazon/cases/PI-control/"
                
                fili_sst_1      = "data/PI-control.lnd.elnino.JAS.nc"

                fili_uv_p_1     = "data/PI-control.lnd.elnino.JAS.nc"



                file1      = addfile(diri_1+fili_sst_1,"r")
                t          = file1->t_anom_enso_JAS_mean
                t_ttest    = file1->t_ttest
                t_sm       = file1->t_shift_season_mean
                slon       = t&lon
                slat       = t&lat
                
                file2      = addfile(diri_1+fili_uv_p_1,"r")
                u          = file2->u_anom_enso_JAS_mean
                u_ttest    = file2->u_ttest
                u_sm       = file2->u_shift_season_mean
                wlat       = u&lat
                wlon       = u&lon
                ;v          = file2->v_anom_enso_JAS_mean
                ;v_ttest    = file2->v_ttest
                ;v_sm       = file2->v_shift_season_mean
                p          = file2->p_anom_enso_JAS_mean
                p_ttest    = file2->p_ttest
                p_sm       = file2->p_shift_season_mean



            ; case_2      
                diri_2          = "/glade/work/xinyang/program/Amazon/cases/fixed-SM-Amazon/"
                
                fili_sst_2      = "data/fixed-SM-Amazon.lnd.elnino.JAS.nc"

                fili_uv_p_2     = "data/fixed-SM-Amazon.lnd.elnino.JAS.nc"



                ffile1        = addfile(diri_2+fili_sst_2,"r")
                ft            = ffile1->t_anom_enso_JAS_mean
                fslon         = ft&lon
                fslat         = ft&lat
                ft_ttest      = ffile1->t_ttest
                ft_sm         = ffile1->t_shift_season_mean
                
                ffile2        = addfile(diri_2+fili_uv_p_2,"r")
                fu            = ffile2->u_anom_enso_JAS_mean
                fu_ttest      = ffile2->u_ttest
                fu_sm         = ffile2->u_shift_season_mean
                fwlat         = fu&lat
                fwlon         = fu&lon
                ;fv            = ffile2->v_anom_enso_JAS_mean
                ;fv_ttest      = ffile2->v_ttest
                ;fv_sm         = ffile2->v_shift_season_mean
                fp            = ffile2->p_anom_enso_JAS_mean
                fp_ttest      = ffile2->p_ttest
                fp_sm         = ffile2->p_shift_season_mean

        print("Input done!")

        ; PI-control minus Fix-SM-Amazon (f) or reverse
            t_anom_enso_JAS_mean = t
            u_anom_enso_JAS_mean = u
            ;v_anom_enso_JAS_mean = v
            p_anom_enso_JAS_mean = p

            t_anom_enso_JAS_mean = ft - t + ft_sm -t_sm
            u_anom_enso_JAS_mean = fu - u + fu_sm -u_sm
            ;v_anom_enso_JAS_mean = fv - v + fv_sm -v_sm
            p_anom_enso_JAS_mean = fp - p + fp_sm -p_sm

        ; t test 
            sigr = 0.06                       ; critical sig lvl for r
            iflag= True                        ; Set to False if assumed to have the same population variance. 
                                                ; Set to True if assumed to have different population variances. 
            
            ; precip 
                  x_p     = p_ttest
                  y_p     = fp_ttest
                  dimXY_p = dimsizes(x_p)
                  ntim_p  = dimXY_p(0)
                  nlat_p  = dimXY_p(1)
                  mlon_p  = dimXY_p(2)

                  xtmp_p = x_p(lat|:,lon|:,time|:)       ; reorder but do it only once [temporary]
                  ytmp_p = y_p(lat|:,lon|:,time|:)
                    

                  xAve_p = dim_avg_Wrap(xtmp_p)              ; calculate means at each grid point 
                  yAve_p = dim_avg_Wrap(ytmp_p)
                  xVar_p = dim_variance_Wrap(xtmp_p)         ; calculate variances
                  yVar_p = dim_variance_Wrap(ytmp_p)


                  xN_p   = ntim_p
                  yN_p   = ntim_p

                  prob_p = ttest(xAve_p,xVar_p,xN_p, yAve_p,yVar_p,yN_p, iflag, False)
                  copy_VarCoords (xAve_p, prob_p)
                  prob_p@long_name = "Probability: difference between mean"

            ; wind
                ; u 
                  x_u     = u_ttest
                  y_u     = fu_ttest
                  dimXY_u = dimsizes(x_u)
                  ntim_u  = dimXY_u(0)
                  nlat_u  = dimXY_u(1)
                  mlon_u  = dimXY_u(2)

                  xtmp_u = x_u(lat|:,lon|:,time|:)       ; reorder but do it only once [temporary]
                  ytmp_u = y_u(lat|:,lon|:,time|:)
                    

                  xAve_u = dim_avg_Wrap(xtmp_u)              ; calculate means at each grid point 
                  yAve_u = dim_avg_Wrap(ytmp_u)
                  xVar_u = dim_variance_Wrap(xtmp_u)         ; calculate variances
                  yVar_u = dim_variance_Wrap(ytmp_u)

                  xN_u   = ntim_u
                  yN_u   = ntim_u

                  prob_u = ttest(xAve_u,xVar_u,xN_u, yAve_u,yVar_u,yN_u, iflag, False)
                  copy_VarCoords (xAve_u, prob_u)
                  prob_u@long_name = ""

 

            ; sst 
                  x_t     = t_ttest
                  y_t     = ft_ttest
                  dimXY_t = dimsizes(x_t)
                  ntim_t  = dimXY_t(0)
                  nlat_t  = dimXY_t(1)
                  mlon_t  = dimXY_t(2)

                  xtmp_t = x_t(lat|:,lon|:,time|:)       ; reorder but do it only once [temporary]
                  ytmp_t = y_t(lat|:,lon|:,time|:)
                    

                  xAve_t = dim_avg_Wrap(xtmp_t)              ; calculate means at each grid point 
                  yAve_t = dim_avg_Wrap(ytmp_t)
                  xVar_t = dim_variance_Wrap(xtmp_t)         ; calculate variances
                  yVar_t = dim_variance_Wrap(ytmp_t)

                  sigr = sigr                        ; critical sig lvl for r
                  xN_t   = ntim_t
                  yN_t   = ntim_t

                  prob_t = ttest(xAve_t,xVar_t,xN_t, yAve_t,yVar_t,yN_t, iflag, False)
                  copy_VarCoords (xAve_t, prob_t)
                  prob_t@long_name = "Probability: difference between mean"



        ; Plot
            wks     = gsn_open_wks("eps","/glade/work/xinyang/program/Amazon/cases/fixed-SM-Amazon/pics/diff_lnd_all_elnino_JAS")             ; open a ps plot
            nplots  = 3
            plot    = new(nplots,graphic)
            nnplots = 1
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
                ;res1@gsn_Add_Cyclic               = False
                res1@cnFillPalette                = "MPL_BrBG"       ; set the color map
                res1@lbLabelStride                = 2 
                res1@mpFillOn                     = True
                res1@mpLandFillColor              = "white"            ; set land to be gray

                res1@mpMinLonF                    = lonW+deg                 ; select a subregion
                res1@mpMaxLonF                    = lonE-deg
                res1@mpMinLatF                    = latS 
                res1@mpMaxLatF                    = latN
                res1@tmXBMinorOn                  = True
                res1@mpCenterLonF                 = 180

                res1@lbLabelBarOn                 = True               ; turn off individual cb's
                res1@lbOrientation                = "Horizontal"       ; vertical label bar
                res1@pmLabelBarOrthogonalPosF     = 0.08               ; move label bar closer

                res1@cnLevelSelectionMode         = "ManualLevels"     ; set manual contour levels
                res1@cnMinLevelValF               = -3               ; set min contour level
                res1@cnMaxLevelValF               = 3                ; set max contour level
                res1@cnLevelSpacingF              = 0.5                ; set contour spacing      
                res1@gsnRightString               = ""  

                ; Title
                res1@gsnLeftString                = " a) Top 10cm Soil Water (kg/m2) Difference (JAS) "
                ;res1@gsnLeftStringOrthogonalPosF = -0.001
                res1@gsnStringFontHeightF         = 0.017

                plot(0)     = gsn_csm_contour_map_ce(wks,t_anom_enso_JAS_mean(:,:),res1)

                ; ========================= stippling ==============================
                      sres0 = True                            ; res2 probability plots

                      sres0@gsnDraw             = False       ; Do not draw plot
                      sres0@gsnFrame            = False       ; Do not advance frome

                      sres0@cnLevelSelectionMode = "ManualLevels" ; set manual contour levels
                      sres0@cnMinLevelValF      = 0.00        ; set min contour level
                      sres0@cnMaxLevelValF      = 1.05        ; set max contour level
                      sres0@cnLevelSpacingF     = sigr        ; set contour spacing

                      sres0@cnInfoLabelOn       = False       ; turn off info label

                      sres0@cnLinesOn           = False       ; do not draw contour lines
                      sres0@cnLineLabelsOn      = False       ; do not draw contour labels

                      sres0@cnFillScaleF        = 0.6         ; add extra density
                      delete(prob_t@long_name)

                      plot0   = gsn_csm_contour(wks,gsn_add_cyclic_point(prob_t(:,:)), sres0)
                      sopt     = True
                      sopt@gsnShadeFillType = "pattern"
                      sopt@gsnShadeLow = 17 
                      plot0   = gsn_contour_shade(plot0, sigr, 30, sopt)  ; shade all areas less than the
                                                                 ; sigr contour level
                      ;overlay (plot(0), plot0)

            ; 2nd
                res3                              = True               ; plot mods desired
                res3@gsnDraw                      = False
                res3@gsnFrame                     = False              ; don't advance frame yet     

                res3@cnFillOn                     = True               ; turn on color for contours
                res3@cnLinesOn                    = False              ; turn off contour lines
                res3@cnLineLabelsOn               = False              ; turn off contour line labels
                res3@cnInfoLabelOn                = False 
                
                ;  Shaded
                ;res3@gsn_Add_Cyclic               = False
                res3@cnFillPalette                = "temp_19lev"       ; set the color map
                res3@lbLabelStride                = 2 
                res3@mpFillOn                     = True
                res3@mpLandFillColor              = "white"            ; set land to be gray

                res3@mpMinLonF                    = lonW+deg                 ; select a subregion
                res3@mpMaxLonF                    = lonE-deg
                res3@mpMinLatF                    = latS 
                res3@mpMaxLatF                    = latN
                res3@tmXBMinorOn                  = True
                res3@mpCenterLonF                 = 180

                res3@lbLabelBarOn                 = True               ; turn off individual cb's
                res3@lbOrientation                = "Horizontal"       ; vertical label bar
                res3@pmLabelBarOrthogonalPosF     = 0.08               ; move label bar closer

                res3@cnLevelSelectionMode         = "ManualLevels"     ; set manual contour levels
                res3@cnMinLevelValF               = -20               ; set min contour level
                res3@cnMaxLevelValF               = 20                ; set max contour level
                res3@cnLevelSpacingF              = 4                ; set contour spacing      
                res3@gsnRightString               = ""  

                ; Title
                res3@gsnLeftString                = " b) ET (W/m2) Difference (JAS) "
                ;res3@gsnLeftStringOrthogonalPosF = -0.001
                res3@gsnStringFontHeightF         = 0.017

                plot(1)     = gsn_csm_contour_map_ce(wks,u_anom_enso_JAS_mean(:,:),res3)

                ; ========================= stippling ==============================
                      sres1 = True                            ; res2 probability plots

                      sres1@gsnDraw             = False       ; Do not draw plot
                      sres1@gsnFrame            = False       ; Do not advance frome

                      sres1@cnLevelSelectionMode = "ManualLevels" ; set manual contour levels
                      sres1@cnMinLevelValF      = 0.00        ; set min contour level
                      sres1@cnMaxLevelValF      = 1.05        ; set max contour level
                      sres1@cnLevelSpacingF     = sigr        ; set contour spacing

                      sres1@cnInfoLabelOn       = False       ; turn off info label

                      sres1@cnLinesOn           = False       ; do not draw contour lines
                      sres1@cnLineLabelsOn      = False       ; do not draw contour labels

                      sres1@cnFillScaleF        = 0.6         ; add extra density
                      delete(prob_t@long_name)

                      plot1   = gsn_csm_contour(wks,gsn_add_cyclic_point(prob_u(:,:)), sres1)
                      sopt     = True
                      sopt@gsnShadeFillType = "pattern"
                      sopt@gsnShadeLow = 17 
                      plot1   = gsn_contour_shade(plot1, sigr, 30, sopt)  ; shade all areas less than the
                                                                 ; sigr contour level
                      ;overlay (plot(1), plot1)

            ; 3nd
                res2                              = True               ; plot mods desired
                res2@gsnDraw                      = False
                res2@gsnFrame                     = False              ; don't advance frame yet     

                res2@cnFillOn                     = True               ; turn on color for contours
                res2@cnLinesOn                    = False              ; turn off contour lines
                res2@cnLineLabelsOn               = False              ; turn off contour line labels
                res2@cnInfoLabelOn                = False 
                
                ; Shaded
                res2@cnFillPalette                = "temp_19lev"       ; set the color map
                res2@lbLabelStride                = 2 
                res2@mpLandFillColor              = "gray"             ; set land to be gray

                res2@mpMinLonF                    = lonW+deg                 ; select a subregion
                res2@mpMaxLonF                    = lonE-deg
                res2@mpMinLatF                    = latS 
                res2@mpMaxLatF                    = latN
                res2@tmXBMinorOn                  = True
                res2@mpCenterLonF                 = 180

                res2@lbLabelBarOn                 = True               ; turn off individual cb's
                res2@lbOrientation                = "Horizontal"       ; vertical label bar
                res2@pmLabelBarOrthogonalPosF     = 0.08               ; move label bar closer

                res2@cnLevelSelectionMode         = "ManualLevels"     ; set manual contour levels
                res2@cnMinLevelValF               = -30               ; set min contour level
                res2@cnMaxLevelValF               = 30                ; set max contour level
                res2@cnLevelSpacingF              = 5                ; set contour spacing 
                res2@gsnRightString               = ""

                ; Title
                res2@gsnLeftString                = " c) Net Radiative heat flux (W/m2) Differences (JAS) "
                ;res2@gsnLeftStringOrthogonalPosF = -0.001
                res2@gsnStringFontHeightF         = 0.017   
                plot(2) = gsn_csm_contour_map_ce(wks,p_anom_enso_JAS_mean(:,:),res2)

                ; ========================= stippling ==============================
                      sres2 = True                            ; res2 probability plots

                      sres2@gsnDraw             = False       ; Do not draw plot
                      sres2@gsnFrame            = False       ; Do not advance frome

                      sres2@cnLevelSelectionMode = "ManualLevels" ; set manual contour levels
                      sres2@cnMinLevelValF      = 0.00        ; set min contour level
                      sres2@cnMaxLevelValF      = 1.05        ; set max contour level
                      sres2@cnLevelSpacingF     = sigr        ; set contour spacing

                      sres2@cnInfoLabelOn       = False       ; turn off info label

                      sres2@cnLinesOn           = False       ; do not draw contour lines
                      sres2@cnLineLabelsOn      = False       ; do not draw contour labels

                      sres2@cnFillScaleF        = 0.6         ; add extra density
                      delete(prob_p@long_name)

                      plot2   = gsn_csm_contour(wks,gsn_add_cyclic_point(prob_p(:,:)), sres2)
                      sopt     = True
                      sopt@gsnShadeFillType = "pattern"
                      sopt@gsnShadeLow = 17 
                      plot2   = gsn_contour_shade(plot2, sigr, 30, sopt)  ; shade all areas less than the
                                                                 ; sigr contour level
                      ;overlay (plot(2), plot2)


            ; create panel
                resP                     = True                ; modify the panel plot
                ;resP@gsnPanelMainString = "A plot with a common label bar"
                ;resP@gsnPanelLabelBar    = False                ; add common colorbar
                resP@lbLabelFontHeightF  = 0.007               ; make labels smaller

                gsn_panel(wks,plot,(/2,2/),resP)               ; now draw as one plot
    end
     

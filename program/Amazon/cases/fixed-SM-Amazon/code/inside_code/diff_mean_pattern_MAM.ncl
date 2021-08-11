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
                
                fili_sst_1      = "data/PI-control.sst.mean_pattern_MAM.nc"

                fili_uv_p_1     = "data/PI-control.uv_p.mean_pattern_MAM.nc"



                file1       = addfile(diri_1+fili_sst_1,"r")
                t           = file1->t_shift_MAM_mean
                slon        = t&lon
                slat        = t&lat
                t_nyear_use = file1->t_tran_use
                
                file2       = addfile(diri_1+fili_uv_p_1,"r")
                u           = file2->u_shift_MAM_mean
                wlat        = u&lat
                wlon        = u&lon
                v           = file2->v_shift_MAM_mean
                p           = file2->p_shift_MAM_mean
                u_nyear_use = file2->u_tran_use
                v_nyear_use = file2->v_tran_use
                p_nyear_use = file2->p_tran_use



            ; case_2      
                diri_2          = "/glade/work/xinyang/program/Amazon/cases/fixed-SM-Amazon/"
                
                fili_sst_2      = "data/fixed-SM-Amazon.sst.mean_pattern_MAM.nc"

                fili_uv_p_2     = "data/fixed-SM-Amazon.uv_p.mean_pattern_MAM.nc"



                ffile1        = addfile(diri_2+fili_sst_2,"r")
                ft            = ffile1->t_shift_MAM_mean
                fslon         = ft&lon
                fslat         = ft&lat
                ft_nyear_use  = ffile1->t_tran_use
                
                ffile2        = addfile(diri_2+fili_uv_p_2,"r")
                fu            = ffile2->u_shift_MAM_mean
                fwlat         = fu&lat
                fwlon         = fu&lon
                fv            = ffile2->v_shift_MAM_mean
                fp            = ffile2->p_shift_MAM_mean
                fu_nyear_use  = ffile2->u_tran_use
                fv_nyear_use  = ffile2->v_tran_use
                fp_nyear_use  = ffile2->p_tran_use

        print("Input done!")

        t_shift_MAM_mean = t
        u_shift_MAM_mean = u
        v_shift_MAM_mean = v
        p_shift_MAM_mean = p

        ; ft -t means FIX-SM -CTRL
        t_shift_MAM_mean = ft - t
        u_shift_MAM_mean = fu - u
        v_shift_MAM_mean = fv - v 
        p_shift_MAM_mean = fp - p

        ; t test 
            sigr = 0.06                       ; critical sig lvl for r
            iflag= True                        ; Set to False if assumed to have the same population variance. 
            									; Set to True if assumed to have different population variances. 
            
            ; precip 
                  x_p     = p_nyear_use
                  y_p     = fp_nyear_use
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
                  x_u     = u_nyear_use
                  y_u     = fu_nyear_use
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

            	; u 
                  x_v     = v_nyear_use
                  y_v     = fv_nyear_use
                  dimXY_v = dimsizes(x_v)
                  ntim_v  = dimXY_v(0)
                  nlat_v  = dimXY_v(1)
                  mlon_v  = dimXY_v(2)

                  xtmp_v = x_v(lat|:,lon|:,time|:)       ; reorder but do it only once [temporary]
                  ytmp_v = y_v(lat|:,lon|:,time|:)
                    

                  xAve_v = dim_avg_Wrap(xtmp_v)              ; calculate means at each grid point 
                  yAve_v = dim_avg_Wrap(ytmp_v)
                  xVar_v = dim_variance_Wrap(xtmp_v)         ; calculate variances
                  yVar_v = dim_variance_Wrap(ytmp_v)

                  xN_v   = ntim_v
                  yN_v   = ntim_v

                  prob_v = ttest(xAve_v,xVar_v,xN_v, yAve_v,yVar_v,yN_v, iflag, False)
                  copy_VarCoords (xAve_v, prob_v)
                  prob_v@long_name = ""

                 ; combining prob of u/v
                 prob_u_use         = ndtooned(prob_u)
                 prob_v_use         = ndtooned(prob_v)
                 find_v             = ind(prob_v_use.le.sigr)
                 prob_u_use(find_v) = 0.03
                 prob_uv            = onedtond(prob_u_use, (/nlat_v,mlon_v/))
                 copy_VarCoords (prob_v, prob_uv)

            ; sst 
                  x_t     = t_nyear_use
                  y_t     = ft_nyear_use
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
            wks     = gsn_open_wks("eps","/glade/work/xinyang/program/Amazon/cases/fixed-SM-Amazon/pics/diff_mean_pattern_MAM")             ; open a ps plot
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
                res1@cnFillPalette                = "temp_19lev"       ; set the color map
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
                res1@cnMinLevelValF               = -0.4               ; set min contour level
                res1@cnMaxLevelValF               = 0.4                ; set max contour level
                res1@cnLevelSpacingF              = 0.05                ; set contour spacing      
                res1@gsnRightString               = ""  

                ; Title
                res1@gsnLeftString                = " a) SST Difference (MAM) "
                ;res1@gsnLeftStringOrthogonalPosF = -0.001
                res1@gsnStringFontHeightF         = 0.017

                plot(0)     = gsn_csm_contour_map_ce(wks,t_shift_MAM_mean(:,:),res1)

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
                      overlay (plot(0), plot0)

            ; 2nd
                vcres1 = True
                vcres1@gsnDraw                    = False               ; don't draw yet
                vcres1@gsnFrame                   = False               ; don't ad vance frame yet
                ;vcres1@cnInfoLabelOn              =  False
                
                ;  Shaded
                ;vcres1@gsn_Add_Cyclic             = False
                vcres1@vcRefAnnoOn                = True                ; will draw the reference  vector annotation
                vcres1@vcRefAnnoString2On         = False               ; will not display a string below 
                vcres1@vcRefAnnoPerimOn           = False               ; no outline will be drawn
                vcres1@vcRefAnnoSide              = "top"
                vcres1@vcRefAnnoOrthogonalPosF    = -0.17
                vcres1@vcRefAnnoParallelPosF      = 0.98                ;set the X-axis position of annotation 
                vcres1@vcRefLengthF               = 0.02
                vcres1@vcRefMagnitudeF            = 0.5
                vcres1@vcRefAnnoString1On         = True
                vcres1@vcRefAnnoString1           = "0.5 m/s"              ;"1.5m/s"
                vcres1@vcGlyphStyle               = "LineArrow"      ;"LineArrow","Curly Vector"
                vcres1@vcLineArrowThicknessF      = 0.9
                vcres1@vcMinDistanceF             = 0.014
                vcres1@vcLineArrowColor           = "grey39"
                vcres1@gsnRightString             = ""
                vcres1@gsnLeftString              = ""
                ;vcres1@vcVectorDrawOrder          = "PostDraw" 
 				vcres1@mpLandFillColor              = "gray"            ; set land to be gray

                vcres1@mpMinLonF                    = lonW+deg                 ; select a subregion
                vcres1@mpMaxLonF                    = lonE-deg
                vcres1@mpMinLatF                    = latS 
                vcres1@mpMaxLatF                    = latN
                vcres1@tmXBMinorOn                  = True
                vcres1@mpCenterLonF                 = 180
                vcres1@gsnRightString               = ""  

                ; Title
                vcres1@gsnLeftString                = " b) Wind Difference (MAM) "
                ;vcres1@gsnLeftStringOrthogonalPosF = -0.001
                vcres1@gsnStringFontHeightF         = 0.017

                plot(1)     = gsn_csm_vector_map(wks,u_shift_MAM_mean(::2,::2),v_shift_MAM_mean(::2,::2),vcres1) 

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

                      plot1   = gsn_csm_contour(wks,gsn_add_cyclic_point(prob_uv(:,:)), sres1)
                      sopt     = True
                      sopt@gsnShadeFillType = "pattern"
                      sopt@gsnShadeLow = 17 
                      plot1   = gsn_contour_shade(plot1, sigr, 30, sopt)  ; shade all areas less than the
                                                                 ; sigr contour level
                      overlay (plot(1), plot1)

            ; 3nd
                res2                              = True               ; plot mods desired
                res2@gsnDraw                      = False
                res2@gsnFrame                     = False              ; don't advance frame yet     

                res2@cnFillOn                     = True               ; turn on color for contours
                res2@cnLinesOn                    = False              ; turn off contour lines
                res2@cnLineLabelsOn               = False              ; turn off contour line labels
                res2@cnInfoLabelOn                = False 
                
                ; Shaded
                res2@cnFillPalette                = "MPL_BrBG"       ; set the color map
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
                res2@cnMinLevelValF               = -1               ; set min contour level
                res2@cnMaxLevelValF               = 1                ; set max contour level
                res2@cnLevelSpacingF              = 0.1                ; set contour spacing 
                res2@gsnRightString               = ""

                ; Title
                res2@gsnLeftString                = " c) Precipitation Differences (MAM) "
                ;res2@gsnLeftStringOrthogonalPosF = -0.001
                res2@gsnStringFontHeightF         = 0.017   
                plot(2) = gsn_csm_contour_map_ce(wks,p_shift_MAM_mean(:,:),res2)

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
                      overlay (plot(2), plot2)


            ; create panel
                resP                     = True                ; modify the panel plot
                ;resP@gsnPanelMainString = "A plot with a common label bar"
                ;resP@gsnPanelLabelBar    = False                ; add common colorbar
                resP@lbLabelFontHeightF  = 0.007               ; make labels smaller

                gsn_panel(wks,plot,(/3,1/),resP)               ; now draw as one plot
    end


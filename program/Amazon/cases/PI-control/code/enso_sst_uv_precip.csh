#!/bin/csh -f
 # enso composite SSTA, UV, Precip

    #==============================================================================================
    set expname                  = Amazon
    set CASE                     = PI-control

    # set type, time period, lat & lon, dataset, UV level
        # type : El Nino or Atlantic Nino
            set type             = all         # ep, all, stg, cp
            set pattern          = elnino      # lanina, atlanticnino, elnino 
            # the year that event occurs
            # el nino in PI-control (>= 1 std dev) : 12,18,23,28,33
            set specific_years    = 3,12,18,23,28,33
            # 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34
            # delete year 35 
            set rest_years        = 1,2,4,5,6,7,8,9,10,11,13,14,15,16,17,19,20,21,22,24,25,26,27,29,30,31,32,34

        # climatology
            set season           = SON      # MAN, SON, JJA, DJF
            set date_start       = 109      # if "season" is DJF, the first month of beginning time should be 12(D) 
            set date_end         = 3508
            set timespan        = "01-35"              # 01-05 or 06-35
        # Lat & Lon
            set latN             = 55
            set latS             = -55
            set lonW             = 0
            set lonE             = 360
        # UV level
            set uvlev            = 850
        # deg is used to tune the range of longitude from (lonW + deg) to (lonE - deg) for plot     
            set deg              = 0

    # directory
        # main directory
            set mdir   = /glade/work/xinyang/program/$expname/cases/$CASE/
            set dodir  = /glade/work/xinyang/program/$expname/cases/$CASE/

    #==============================================================================================

    rm -r ${mdir}/code/inside_code/${type}_${pattern}_${season}.ncl
    # composite of ssta, uv and precip for specific events and plot

    cat > ${mdir}/code/inside_code/${type}_${pattern}_${season}.ncl << EOF
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
            fili_precip = "atm/$CASE.cam.h0.surface.${timespan}.nc"
            fili_u      = "atm/U.interp.$CASE.cam.h0.${timespan}.nc"
            fili_v      = "atm/V.interp.$CASE.cam.h0.${timespan}.nc"


            file1      = addfile(diri+fili_sst,"r")
            t          = file1->TEMP(:,0,:,:)
            stime      = t&time
            slon       = t&lon
            slat       = t&lat
            
            file2      = addfile(diri+fili_u,"r")
            u          = file2->U(:,{${uvlev}},:,:)
            wlat       = u&lat
            wlon       = u&lon
            wtime      = u&time

            file3      = addfile(diri+fili_v,"r")       
            v          = file3->V(:,{${uvlev}},:,:)

        ; Precipitation
            file5      = addfile(diri+fili_precip,"r")
            pc         = file5->PRECC     ;unit: m/s
            pl         = file5->PRECL     ;unit: m/s
            ; m/s to mm/d
            pcl        = pc + pl   ;;orginal,right one
            p          = pc
            p          = pcl * 1000 * 24 * 60 * 60 
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
                        u_shift       = u(stbn1_w:stbn2_w,{latS:latN},{lonW:lonE})
                        v_shift       = v(stbn1_w:stbn2_w,{latS:latN},{lonW:lonE})
                    ; Prepcipitation
                        p_shift       = p(stbn1_p:stbn2_p,{latS:latN},{lonW:lonE}) 
                delete(t)
                delete(u)
                delete(v)
                delete(p)

        ; Remove annual cycle
            ; SST
                t_shift_mean   = clmMonTLL(t_shift)
                t_shift_anom   = calcMonAnomTLL(t_shift, t_shift_mean)
                t_shift_season_mean   = dim_avg_n_Wrap(t_shift_mean(0:2,:,:),0)
            ; U & V 
                u_shift_mean    = clmMonTLL(u_shift)
                u_shift_anom    = calcMonAnomTLL(u_shift, u_shift_mean)
                u_shift_season_mean   = dim_avg_n_Wrap(u_shift_mean(0:2,:,:),0)

                v_shift_mean    = clmMonTLL(v_shift)
                v_shift_anom    = calcMonAnomTLL(v_shift, v_shift_mean)
                v_shift_season_mean   = dim_avg_n_Wrap(v_shift_mean(0:2,:,:),0)

            ; Prepcipitation
                p_shift_mean    = clmMonTLL(p_shift)
                p_shift_anom    = calcMonAnomTLL(p_shift, p_shift_mean)
                p_shift_season_mean   = dim_avg_n_Wrap(p_shift_mean(0:2,:,:),0) 

        ; Seasonal average anomalies, D(0)J(1)F(1) as year(0) winter
            ; SST size
                nttime  = dimsizes(t_shift_anom(:,0,0))
                ntlat   = dimsizes(t_shift_anom(0,:,0))
                ntlon   = dimsizes(t_shift_anom(0,0,:))

            ; U & V size
                nwtime  = dimsizes(u_shift_anom(:,0,0))
                nwlat   = dimsizes(u_shift_anom(0,:,0))
                nwlon   = dimsizes(u_shift_anom(0,0,:))
            ; Prepcipitation
                nptime  = dimsizes(p_shift_anom(:,0,0))
                nplat   = dimsizes(p_shift_anom(0,:,0))
                nplon   = dimsizes(p_shift_anom(0,0,:))

            ; Copy VarCoords 
            	; anomalies
	                ; SST 
	                    t_anom_tran = reshape(t_shift_anom,(/nttime/12,12,ntlat,ntlon/)) ; Since we shifted the Dec to be the first month of year, we lost the original Jan(0)-Nov(0), and Dec(end), in total, we lost one year data. 

	                ; U & V
	                    u_anom_tran  = reshape(u_shift_anom,(/nwtime/12,12,nwlat,nwlon/))
	                    v_anom_tran  = reshape(v_shift_anom,(/nwtime/12,12,nwlat,nwlon/))
	                ; Prepcipitation
	                    p_anom_tran  = reshape(p_shift_anom,(/nptime/12,12,nplat,nplon/))

            	; mean + anom
	                ; SST 
	                    t_or_tran = reshape(t_shift,(/nttime/12,12,ntlat,ntlon/)) ; Since we shifted the Dec to be the first month of year, we lost the original Jan(0)-Nov(0), and Dec(end), in total, we lost one year data. 

	                ; U & V
	                    u_or_tran  = reshape(u_shift,(/nwtime/12,12,nwlat,nwlon/))
	                    v_or_tran  = reshape(v_shift,(/nwtime/12,12,nwlat,nwlon/))
	                ; Prepcipitation
	                    p_or_tran  = reshape(p_shift,(/nptime/12,12,nplat,nplon/))

        ; ENSO events in model, where nino 3.4 bigger than a standard deviation .

            ;specific_years = (/11,24,25,30,34/)
            specific_years = (/${specific_years}/)
            rest_years     = (/${rest_years}/)
            num_years      = specific_years-1
            mum_years      = rest_years - 1

            ; Copy VarCoords of var anomalies during El Nino years
                t_anom_enso   = t_anom_tran(1:dimsizes(num_years),:,:,:)
                u_anom_enso   = u_anom_tran(1:dimsizes(num_years),:,:,:)
                v_anom_enso   = v_anom_tran(1:dimsizes(num_years),:,:,:)
                p_anom_enso   = p_anom_tran(1:dimsizes(num_years),:,:,:)

                t_anom_enso1  = t_anom_tran(1:dimsizes(num_years),0:2,:,:)
                u_anom_enso1  = u_anom_tran(1:dimsizes(num_years),0:2,:,:)
                v_anom_enso1  = v_anom_tran(1:dimsizes(num_years),0:2,:,:)
                p_anom_enso1  = p_anom_tran(1:dimsizes(num_years),0:2,:,:)

                t_or_noenso   = t_or_tran(1:dimsizes(mum_years),0:2,:,:)
                u_or_noenso   = u_or_tran(1:dimsizes(mum_years),0:2,:,:)
                v_or_noenso   = v_or_tran(1:dimsizes(mum_years),0:2,:,:)
                p_or_noenso   = p_or_tran(1:dimsizes(mum_years),0:2,:,:)

                t_or_enso     = t_or_tran(1:dimsizes(num_years),0:2,:,:)
                u_or_enso     = u_or_tran(1:dimsizes(num_years),0:2,:,:)
                v_or_enso     = v_or_tran(1:dimsizes(num_years),0:2,:,:)
                p_or_enso     = p_or_tran(1:dimsizes(num_years),0:2,:,:)



            ; Extract El Nino events from original whole time data for all variables
                do  i = 0, dimsizes(num_years)-1
                    ; SST 
                        t_anom_enso(i,:,:,:) = t_anom_tran(num_years(i),:,:,:)
                    ; U & V
                        u_anom_enso(i,:,:,:) = u_anom_tran(num_years(i),:,:,:)
                        v_anom_enso(i,:,:,:) = v_anom_tran(num_years(i),:,:,:)
                    ; Prepcipitation
                        p_anom_enso(i,:,:,:) = p_anom_tran(num_years(i),:,:,:)
                end do

                do  i = 0, dimsizes(num_years)-1
                    ; SST 
                        t_anom_enso1(i,:,:,:)   = t_anom_tran(num_years(i),0:2,:,:)
                    ; U & V
                        u_anom_enso1(i,:,:,:)   = u_anom_tran(num_years(i),0:2,:,:)
                        v_anom_enso1(i,:,:,:)   = v_anom_tran(num_years(i),0:2,:,:)
                    ; Prepcipitation
                        p_anom_enso1(i,:,:,:)   = p_anom_tran(num_years(i),0:2,:,:)
                end do

            ; Extract from mean+anom
                do  i = 0, dimsizes(num_years)-1
                    ; SST 
                        t_or_enso(i,:,:,:) = t_or_tran(num_years(i),0:2,:,:)
                    ; U & V
                        u_or_enso(i,:,:,:) = u_or_tran(num_years(i),0:2,:,:)
                        v_or_enso(i,:,:,:) = v_or_tran(num_years(i),0:2,:,:)
                    ; Prepcipitation
                        p_or_enso(i,:,:,:) = p_or_tran(num_years(i),0:2,:,:)
                end do

                do  i = 0, dimsizes(mum_years)-1
                    ; SST 
                        t_or_noenso(i,:,:,:) = t_or_tran(mum_years(i),0:2,:,:)
                    ; U & V
                        u_or_noenso(i,:,:,:) = u_or_tran(mum_years(i),0:2,:,:)
                        v_or_noenso(i,:,:,:) = v_or_tran(mum_years(i),0:2,:,:)
                    ; Prepcipitation
                        p_or_noenso(i,:,:,:) = p_or_tran(mum_years(i),0:2,:,:)
                end do

                ; Mean 
                	;enso
	                    ; SST
	                        t_ttest  = dim_avg_n(t_or_enso, 1)
	                    ; U & V
	                        u_ttest  = dim_avg_n(u_or_enso, 1)
	                        v_ttest  = dim_avg_n(v_or_enso, 1)
	                    ; Prepcipitation
	                        p_ttest  = dim_avg_n(p_or_enso, 1)
                     
                nmyear = dimsizes(t_ttest(:,0,0))
                copy_VarCoords(t_shift(0:nmyear-1,:,:),t_ttest)
                copy_VarCoords(u_shift(0:nmyear-1,:,:),u_ttest)
                copy_VarCoords(v_shift(0:nmyear-1,:,:),v_ttest)
                copy_VarCoords(p_shift(0:nmyear-1,:,:),p_ttest)                


                	;non-enso
	                    ; SST
	                        t_ttest_noenso  = dim_avg_n(t_or_noenso, 1)
	                    ; U & V
	                        u_ttest_noenso  = dim_avg_n(u_or_noenso, 1)
	                        v_ttest_noenso  = dim_avg_n(v_or_noenso, 1)
	                    ; Prepcipitation
	                        p_ttest_noenso  = dim_avg_n(p_or_noenso, 1)	  

                mmyear = dimsizes(t_ttest_noenso(:,0,0))
                copy_VarCoords(t_shift(0:mmyear-1,:,:),t_ttest_noenso)
                copy_VarCoords(u_shift(0:mmyear-1,:,:),u_ttest_noenso)
                copy_VarCoords(v_shift(0:mmyear-1,:,:),v_ttest_noenso)
                copy_VarCoords(p_shift(0:mmyear-1,:,:),p_ttest_noenso)   


                ; student test 
		            sigr = 0.06                       ; critical sig lvl for r
		            iflag= True                        ; Set to False if assumed to have the same population variance. 
		            									; Set to True if assumed to have different population variances. 
		            
		            ; precip 
		                  x_p     = p_ttest
		                  y_p     = p_ttest_noenso
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
		                  y_u     = u_ttest_noenso
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
		                  x_v     = v_ttest
		                  y_v     = v_ttest_noenso
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
		                  x_t     = t_ttest
		                  y_t     = t_ttest_noenso
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


            ; Composite of selected El Nino events, in this case, DJF is the season we concerned 
                ; Mean on all events
                    ; SST
                        t_anom_enso_mean_tran  = dim_avg_n(t_anom_enso, 0)
                    ; U & V
                        u_anom_enso_mean_tran  = dim_avg_n(u_anom_enso, 0)
                        v_anom_enso_mean_tran  = dim_avg_n(v_anom_enso, 0)
                    ; Prepcipitation
                        p_anom_enso_mean_tran  = dim_avg_n(p_anom_enso, 0)

                ; Extract three month D(0)J(1)F(1) from the whole year
                    ; SST
                        t_anom_enso_${season}_tran   = t_anom_enso_mean_tran(0:2,:,:)
                    ; U & V
                        u_anom_enso_${season}_tran   = u_anom_enso_mean_tran(0:2,:,:)
                        v_anom_enso_${season}_tran   = v_anom_enso_mean_tran(0:2,:,:)
                    ; Prepcipitation
                        p_anom_enso_${season}_tran   = p_anom_enso_mean_tran(0:2,:,:)

                ; Mean on DJF
                    ; SST
                        t_anom_enso_${season}_mean   = dim_avg_n(t_anom_enso_${season}_tran, 0)
                    ; U & V
                        u_anom_enso_${season}_mean   = dim_avg_n(u_anom_enso_${season}_tran, 0)
                        v_anom_enso_${season}_mean   = dim_avg_n(v_anom_enso_${season}_tran, 0)
                    ; Prepcipitation
                        p_anom_enso_${season}_mean   = dim_avg_n(p_anom_enso_${season}_tran, 0)

        print("Calculation done!")

        ;  Define new variable   
            copy_VarCoords(t_shift_anom(0,:,:),t_anom_enso_${season}_mean)
            t_anom_enso_${season}_mean@long_name        =   "Seasonal mean anomalies SST during El Nino(${season})"
            t_anom_enso_${season}_mean@standard_name    =   "Seasonal mean anomalies SST during El Nion(${season})"
            t_anom_enso_${season}_mean@units            =   "C"
            t_anom_enso_${season}_mean@var_desc         =   "SST"

            copy_VarCoords(u_shift_anom(0,:,:),u_anom_enso_${season}_mean)
            u_anom_enso_${season}_mean@long_name        =   "Seasonal mean anomalies U during El Nino(${season})"
            u_anom_enso_${season}_mean@standard_name    =   "Seasonal mean anomalies U during El Nion(${season})"
            u_anom_enso_${season}_mean@units            =   "m/s"
            u_anom_enso_${season}_mean@var_desc         =   "U"

            copy_VarCoords(v_shift_anom(0,:,:),v_anom_enso_${season}_mean)
            v_anom_enso_${season}_mean@long_name        =   "Seasonal mean anomalies V during El Nino(${season})"
            v_anom_enso_${season}_mean@standard_name    =   "Seasonal mean anomalies V during El Nion(${season})"
            v_anom_enso_${season}_mean@units            =   "m/s"
            v_anom_enso_${season}_mean@var_desc         =   "V"
          
            copy_VarCoords(p_shift_anom(0,:,:),p_anom_enso_${season}_mean)
            p_anom_enso_${season}_mean@long_name        =   "Seasonal mean anomalies precipitation during El Nino(${season})"
            p_anom_enso_${season}_mean@standard_name    =   "Seasonal mean anomalies precp during El Nion(${season})"
            p_anom_enso_${season}_mean@units            =   "mm/day"
            p_anom_enso_${season}_mean@var_desc         =   "P"

        delete(t_anom_enso_${season}_mean@units)
        delete(u_anom_enso_${season}_mean@units)
        delete(v_anom_enso_${season}_mean@units)
        delete(p_anom_enso_${season}_mean@units)

        
        ; ------------------- output data ----------------
        datafile1 = "${mdir}/data/${CASE}.ocn.${pattern}.${season}.nc"
        system("rm -rf "+datafile1)
        fout1 =addfile(datafile1,"c")
        fout1@title ="composite of sst uv precip"
        filedimdef(fout1,"time",-1,True)
        fout1->t_ttest = t_ttest
        fout1->t_anom_enso_${season}_mean=t_anom_enso_${season}_mean
        fout1->t_shift_season_mean=t_shift_season_mean

        datafile2 = "${mdir}/data/${CASE}.atm.${pattern}.${season}.nc"
        system("rm -rf "+datafile2)
        fout2 =addfile(datafile2,"c")
        fout2@title ="composite of sst uv precip"
        filedimdef(fout2,"time",-1,True)
        fout2->u_ttest = u_ttest
        fout2->v_ttest = v_ttest
        fout2->p_ttest = p_ttest

        fout2->u_anom_enso_${season}_mean=u_anom_enso_${season}_mean
        fout2->v_anom_enso_${season}_mean=v_anom_enso_${season}_mean
        fout2->p_anom_enso_${season}_mean=p_anom_enso_${season}_mean

		fout2->u_shift_season_mean=u_shift_season_mean
		fout2->v_shift_season_mean=v_shift_season_mean
		fout2->p_shift_season_mean=p_shift_season_mean



        print("Output done!")




        ; Plot
            wks     = gsn_open_wks("eps","${mdir}/pics/${type}_${pattern}_${season}")             ; open a ps plot
            nplots  = 2
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
                res1@cnMinLevelValF               = -2.5               ; set min contour level
                res1@cnMaxLevelValF               = 2.5                ; set max contour level
                res1@cnLevelSpacingF              = 0.25                ; set contour spacing        

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
                vcres1@vcRefMagnitudeF            = 2
                vcres1@vcRefAnnoString1On         = True
                vcres1@vcRefAnnoString1           = "2m/s"              ;"1.5m/s"
                vcres1@vcGlyphStyle               = "LineArrow"      ;"LineArrow","Curly Vector"
                vcres1@vcLineArrowThicknessF      = 0.9
                vcres1@vcMinDistanceF             = 0.014
                vcres1@vcLineArrowColor           = "grey39"
                vcres1@gsnRightString             = ""
                vcres1@gsnLeftString              = ""
                vcres1@vcVectorDrawOrder          = "PostDraw" 
                ; Title
                res1@gsnLeftString                = " a) SST and Wind (${uvlev} hPa) Anomalies (${season}) "
                ;res1@gsnLeftStringOrthogonalPosF = -0.001
                res1@gsnStringFontHeightF         = 0.017

                plot(0)     = gsn_csm_contour_map_ce(wks,t_anom_enso_${season}_mean(:,:),res1)
                vectors(0)  = gsn_csm_vector(wks,u_anom_enso_${season}_mean(::2,::2),v_anom_enso_${season}_mean(::2,::2),vcres1) 
                overlay(plot(0),vectors(0))                            ; result will be plotA
                plot(0) = plot(0)                                      ; now assign plotA to array

            ; 2nd
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
                res2@cnMinLevelValF               = -6.0               ; set min contour level
                res2@cnMaxLevelValF               = 6.0                ; set max contour level
                res2@cnLevelSpacingF              = 0.5                ; set contour spacing 

                ; Title
                res2@gsnLeftString                = " b) Precipitation Anomalies (${season}) "
                ;res2@gsnLeftStringOrthogonalPosF = -0.001
                res2@gsnStringFontHeightF         = 0.017   
                plot(1) = gsn_csm_contour_map_ce(wks,p_anom_enso_${season}_mean(:,:),res2)

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

                      plot1   = gsn_csm_contour(wks,gsn_add_cyclic_point(prob_p(:,:)), sres2)
                      sopt     = True
                      sopt@gsnShadeFillType = "pattern"
                      sopt@gsnShadeLow = 17 
                      plot1   = gsn_contour_shade(plot1, sigr, 30, sopt)  ; shade all areas less than the
                                                                 ; sigr contour level
                      overlay (plot(1), plot1)


            ; create panel
                resP                     = True                ; modify the panel plot
                ;resP@gsnPanelMainString = "A plot with a common label bar"
                ;resP@gsnPanelLabelBar    = False                ; add common colorbar
                resP@lbLabelFontHeightF  = 0.007               ; make labels smaller

                gsn_panel(wks,plot,(/2,1/),resP)               ; now draw as one plot
                print("plot done!")
    end

EOF

ncl ${mdir}/code/inside_code/${type}_${pattern}_${season}.ncl

echo "well done, Teresa, I deeply love you!"

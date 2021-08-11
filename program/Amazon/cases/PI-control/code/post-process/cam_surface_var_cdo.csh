#!/bin/csh -f
#PBS -A UHWM0042
#PBS -q regular
#PBS -l select=1:ncpus=1
#PBS -l walltime=12:00:00
#PBS -S /bin/csh -V

#======================================================================================
# cheyenne: scratch, 90 days , 10 T
# cheyenne: work   , no limit, 1  T
# cheyenne: home   , no limit, 25 GB
#               created by Xinyi Yang 01/05/2021
#=======================================================================================

# This script is using for surface variable:
#                          (1) concreating all monthly files into one multi-year file;
#                          (2) calculate climatology and output *.nc (12-month)

#=======================================================================================
# surface variables: (time, lat, lon)
# FSNS             : net solar flux at surface                          , W/m2
# FLNS             : net longwave flux at surface                       , W/m2
# FSNT             : net solar flux at top of model                     , W/m2
# FLNT             : net longwave flux at top of model                  , W/m2
# LHFLX            : surface latent heat flux                           , W/m
# SHFLX            : surface sensible heat dlux                         , W/m2
# PRECC            : convective precipitation rate                      , m/s
# PRECL            : large-scale (stable) precipitation rate            , m/s
# PS               : surface pressure                                   , pa
# PSL              : sea level pressure                                 , pa
# TAUX             : zonal surface stress                               , N/m2
# TAUY             : meridional surface stress                          , N/m2
# TS               : surface temeprature                                , K
# U10              : 10 m wind speed                                    , m/s
# PBL              : PBL height                                         , m
# CLDHGH           : vertically-integrated high cloud                   , fraction
# CLDLOW           : vertically-integrated low cloud                    , fraction
# CLDMED           : vertically-integrated mid-level cloud              , fraction
# CLDTOT           : vertically-integrated total cloud                  , fraction


#=======================================================================================

#module load cdo/1.9.9
set expname         = Amazon
set CASE            = PI-control

# component and component_model must be matched
set component       = atm               # lnd, atm, ocn, glc, ice, rof
set component_model = cam               # clm2, cam, pop

set dir_in          = /glade/scratch/xinyang/archive/$CASE/$component/hist 
set dir_out         = /glade/work/xinyang/experiment/program/$expname/$CASE/post-process/$component


# surface variable: FSNS,FLNS,LHFLX,SHFLX,FLNT,FSNT,PRECC,PRECL,PS,PSL,TAUX,TAUY,U10,TS,PBLH,CLDHGH,CLDLOW,CLDMED,CLDTOT
set var_name        = "FSNS,FLNS,LHFLX,SHFLX,FLNT,FSNT,PRECC,PRECL,PS,PSL,TAUX,TAUY,U10,TS,PBLH,CLDHGH,CLDLOW,CLDMED,CLDTOT"

set y_start         = 0001
set y_end           = 0035
set timespan        = "01-35"              # 01-05 or 06-35
set m_start         = 01
set m_end           = 12




#####      Part 1: extracting specific variables and output it monthly per file
	foreach jj (`seq -f "%04g" $y_start  $y_end`)
	echo $jj
		foreach ii (`seq -f "%02g" $m_start  $m_end`)
		echo $ii
			cdo selname,$var_name $dir_in/$CASE.$component_model.h0.$jj-$ii.nc $dir_out/temp/$CASE.$component_model.h0.$jj-$ii.surface.nc
		end
		echo "Part 1 finished!"
	end


#####      Part 2: concreating all monthly files into one multi-year file
	rm -rf $dir_out/temp/$CASE.$component_model.h0.surface.${timespan}.nc
	cdo mergetime $dir_out/temp/$CASE.$component_model.h0.*.surface.nc $dir_out/temp/$CASE.$component_model.h0.surface.${timespan}.nc
	
	rm -rf $dir_out/temp/$CASE.$component_model.h0.surface.${timespan}.std.nc
	cdo setcalendar,standard $dir_out/temp/$CASE.$component_model.h0.surface.${timespan}.nc $dir_out/temp/$CASE.$component_model.h0.surface.${timespan}.std.nc


	rm -rf $dir_out/$CASE.$component_model.h0.surface.${timespan}.nc
	cdo settaxis,$y_start-01-01,12:00:00,1mon $dir_out/temp/$CASE.$component_model.h0.surface.${timespan}.std.nc $dir_out/$CASE.$component_model.h0.surface.${timespan}.nc


	#rm -rf $dir_out/temp/$CASE.$component_model.h0.*.surface.nc
	#rm -rf $dir_out/temp/$CASE.$component_model.h0.surface.${timespan}.nc
	#rm -rf $dir_out/temp/$CASE.$component_model.h0.surface.${timespan}.std.nc  

	echo "Part 2 finished!"

echo "well done, Teresa, I deeply love you!"

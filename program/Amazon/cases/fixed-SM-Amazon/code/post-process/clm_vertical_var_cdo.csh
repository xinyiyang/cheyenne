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

# This script is using for vertical variable:
#                          (1) concreating all monthly files into one multi-year file;
#                          (2) calculate climatology and output *.nc (12-month)

#=======================================================================================
# surface variables: (time, lat, lon)
# FCEV             : canopy evaporation                                 , W/m2
# FCTR             : canopy transpiration                               , W/m2
# FGEV             : ground evaporation                                 , W/m2
# QVEGE            : canopy evaporation                                 , mm/s
# QVEGT            : canopy transpiration                               , mm/s

# FGR              : heat flux into soil/snow including snow melt       , W/m2
# FIRA             : net infrared (longwave) radiation                  , W/m2
# FIRE             : emitted infrared (longwave) radiation              , W/m2
# FLDS             : atmospheric longwave radiation                     , W/m2
# FSA              : absorbed solar radiation                           , W/m2
# FSDS             : atmospheric incident solar radiation               , W/m2
# FSH              : sensible heat                                      , W/m2
# FSH_G            : sensible heat from ground                          , W/m2
# FSR              : reflected solar radiation                          , W/m2

# H2OCAN           : intercepted water                                  , mm
# SOILWATER_10CM   : soil liquid water + ice in top 10cm of soil        , kg/m2

# TG               : ground temperature                                 , K


# vertical variable: (time, levgrnd, lat, lon) 
# H2OSOI           : volumetric soil water (vegetated landunits only)   , mm3/mm3
# SOILLIQ          : soil liquid water (vegetated landunits only)       , kg/m2
# SOILICE          : soil ice (vegetated landunits only)                , kg/m2
# levgrnd
#=======================================================================================

#module load cdo/1.9.9
set expname         = Amazon
set CASE            = fixed-SM-Amazon

# component and component_model must be matched
set component       = lnd               # lnd, atm, ocn, glc, ice, rof
set component_model = clm2               # clm2, cam, pop

set dir_in          = /glade/scratch/xinyang/archive/$CASE/$component/hist 
set dir_out         = /glade/work/xinyang/experiment/program/$expname/$CASE/post-process/$component


# surface variable: H2OSOI,SOILLIQ,SOILICE
set var_name        = "H2OSOI,SOILLIQ,SOILICE,levgrnd"
set y_start         = 0001
set y_end           = 0035
set timespan        = "01-35"              ; 01-05 or 06-35
set m_start         = 01
set m_end           = 12


#####      Part 1: extracting specific variables and output it monthly per file
	foreach jj (`seq -f "%04g" $y_start  $y_end`)
	echo $jj
		foreach ii (`seq -f "%02g" $m_start  $m_end`)
		echo $ii
			rm -f $dir_out/temp/$CASE.$component_model.h0.$jj-$ii.vertical.nc
			cdo selname,$var_name $dir_in/$CASE.$component_model.h0.$jj-$ii.nc $dir_out/temp/$CASE.$component_model.h0.$jj-$ii.vertical.nc
		end
		echo "Part 1 finished!"
	end


#####      Part 2: concreating all monthly files into one multi-year file
	rm -f $dir_out/temp/$CASE.$component_model.h0.vertical.${timespan}.nc
	cdo mergetime $dir_out/temp/$CASE.$component_model.h0.*.vertical.nc $dir_out/temp/$CASE.$component_model.h0.vertical.${timespan}.nc
	
	rm -f $dir_out/temp/$CASE.$component_model.h0.vertical.${timespan}.std.nc
	cdo setcalendar,standard $dir_out/temp/$CASE.$component_model.h0.vertical.${timespan}.nc $dir_out/temp/$CASE.$component_model.h0.vertical.${timespan}.std.nc


	rm -f $dir_out/$CASE.$component_model.h0.vertical.${timespan}.nc
	cdo settaxis,$y_start-01-01,12:00:00,1mon $dir_out/temp/$CASE.$component_model.h0.vertical.${timespan}.std.nc $dir_out/$CASE.$component_model.h0.vertical.${timespan}.nc


	#rm -f $dir_out/temp/$CASE.$component_model.h0.*.vertical.nc
	#rm -f $dir_out/temp/$CASE.$component_model.h0.vertical.${timespan}.nc
	#rm -f $dir_out/temp/$CASE.$component_model.h0.vertical.${timespan}.std.nc  

	rm -f $dir_out/temp/*.nc

	echo "Part 2 finished!"

echo "well done, Teresa, I deeply love you!"

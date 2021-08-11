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
#vertical variables: (time, lev, lat, lon)

# Q                : specific humidity, kg/kg
# RELHUM           : relative humidity, percent
# T                : temperature, K
# U                : zonal wind, m/s
# V                : meridional wind, m/s
# OMEGA            : vertical velocity (pressure), pa/s
# Z3               : geopotential height (above sea level), m


#=======================================================================================

#module load cdo/1.9.9
#module load ncl/6.6.2

set expname         = Amazon
set CASE            = PI-control

# component and component_model must be matched
set component       = atm               # lnd, atm, ocn, glc, ice, rof
set component_model = cam               # clm2, cam, pop

set dir_in          = /glade/scratch/xinyang/archive/$CASE/$component/hist 
set dir_out         = /glade/work/xinyang/experiment/program/$expname/$CASE/post-process/$component



set var_name        = Q            # Q, OMEGA, RELHUM, T, U, V, Z3
set y_start         = 0001
set y_end           = 0035
set timespan        = "01-35"              ; 01-05 or 06-35
set m_start         = 01
set m_end           = 12


#####      Part 1: extracting specific variables, interpolation and output it monthly per file
foreach jj (`seq -f "%04g" $y_start  $y_end`)
echo $jj
foreach ii (`seq -f "%02g" $m_start  $m_end`)
echo $ii

rm -f /glade/work/xinyang/program//$expname/cases/$CASE/code/inside_code/intep_${var_name}.ncl
cat > /glade/work/xinyang/program//$expname/cases/$CASE/code/inside_code/intep_${var_name}.ncl << EOF
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"    
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"  
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/popRemap.ncl"  
;************************************************
		begin
     			infile01  = addfile ("$dir_in/$CASE.$component_model.h0.$jj-$ii.nc","r")
		        var       = infile01->${var_name}                       ; select variable to ave
		        P0mb      = 1000.
		        hyam      = infile01->hyam                              ; get a coefficiants
		        hybm      = infile01->hybm                              ; get b coefficiants
		        PS        = infile01->PS                                ; get pressure
		        TIME      = var&time
		        LAT       = var&lat
		        LON       = var&lon
		        ntim      = dimsizes(TIME)
		        nlat      = dimsizes(LAT)
		        nlon      = dimsizes(LON)
		;************************************************
		; define other arguments required by vinth2p
		;************************************************
		; type of interpolation: 1 = linear, 2 = log, 3 = loglog
		        interp = 2 

		; is extrapolation desired if data is outside the range of PS
		        extrap = False

		; create an array of desired pressure levels:
		        pnew = (/1000.,950.,900.,850.,800.,750.,700.,650.,600.,550.,500.,450.,400.,350.,300.,250.,200.,150.,100./)  
		 ;  pnew = (/850.,200./)
		        pnew!0         = "lev"                  ; variable/dim name 
		        pnew&lev       =  pnew                   ; create coordinate variable
		        pnew@long_name = "pressure"               ; attach some attributes
		        pnew@units     = "hPa"
		        pnew@positive  = "down"   
		;************************************************
		; calculate U on pressure levels
		;************************************************
		; note, the 7th argument is not used, and so is set to 1.
		;************************************************
		        var_use = vinth2p(var(:,:,:,:),hyam,hybm,pnew,PS(:,:,:),interp,P0mb,1,extrap)
		   
		        nlev     = dimsizes(pnew)
		        var_use!0  = "time"
		        var_use&time = TIME
		        var_use!1  = "lev"
		        var_use&lev = pnew 
		        var_use!2  = "lat"
		        var_use&lat = LAT  
		        var_use!3  = "lon"
		        var_use&lon = LON    
		        copy_VarAtts(var,var_use)
		;-------------------------------------------------------------------------------
		        system("/bin/rm -f $dir_out/temp/${var_name}.interp.$CASE.$component_model.h0.$jj-$ii.nc")
		        outfile = addfile("$dir_out/temp/${var_name}.interp.$CASE.$component_model.h0.$jj-$ii.nc","c")
		        setfileoption(outfile,"DefineMode",True)
		        fAtt = True
		        fAtt@title = ""
		        fileattdef(outfile,fAtt)
		        dimNames = (/"time",  "lev" ,"lat", "lon"/)
		        dimSizes = (/ -1   ,  nlev,  nlat,  nlon/)
		        dimUnlim = (/ True ,  False, False, False/)
		        filedimdef(outfile,dimNames,dimSizes,dimUnlim)
		;-------------------------------------------------------------------------------
		        filevardef(outfile,"time", typeof(TIME), getvardims(TIME))
		        filevardef(outfile,"lev",  typeof(pnew), getvardims(pnew))
		        filevardef(outfile,"lat",  typeof(LAT),  getvardims(LAT))
		        filevardef(outfile,"lon",  typeof(LON),  getvardims(LON))
		        filevardef(outfile,"$var_name",typeof(var_use),getvardims(var_use))
		        filevarattdef(outfile,"time", TIME)
		        filevarattdef(outfile,"lev", pnew)
		        filevarattdef(outfile,"lat",  LAT)
		        filevarattdef(outfile,"lon",  LON)
		        filevarattdef(outfile,"${var_name}",var_use)
		        setfileoption(outfile,"DefineMode",False)
		;-------------------------------------------------------------------------------
		        outfile->time   = (/TIME/)
		        outfile->lev    = (/pnew/)
		        outfile->lat    = (/LAT/)
		        outfile->lon    = (/LON/)
		        outfile->${var_name}   = (/var_use/)
		end 

EOF

ncl /glade/work/xinyang/program//$expname/cases/$CASE/code/inside_code/intep_${var_name}.ncl

end      
end
echo "Part 1 finished!"


#####      Part 2: concreating all monthly files into one multi-year file

cdo mergetime $dir_out/temp/${var_name}.interp.$CASE.$component_model.h0.*.nc $dir_out/temp/${var_name}.interp.$CASE.$component_model.h0.${timespan}.nc
cdo setcalendar,standard $dir_out/temp/${var_name}.interp.$CASE.$component_model.h0.${timespan}.nc $dir_out/temp/${var_name}.interp.$CASE.$component_model.h0.${timespan}.std.nc
rm -f $dir_out/${var_name}.interp.$CASE.$component_model.h0.${timespan}.nc
cdo settaxis,$y_start-01-01,12:00:00,1mon $dir_out/temp/${var_name}.interp.$CASE.$component_model.h0.${timespan}.std.nc $dir_out/${var_name}.interp.$CASE.$component_model.h0.${timespan}.nc

rm -rf $dir_out/temp/*.nc
echo "Part 2 finished!"

echo "well done, Teresa, I deeply love you!"

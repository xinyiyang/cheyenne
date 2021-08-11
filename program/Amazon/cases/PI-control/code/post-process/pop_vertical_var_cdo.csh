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
#                          (1) remap and concreating all monthly files into one multi-year file;
#                          (2) calculate climatology and output *.nc (12-month)

#=======================================================================================
#vertical variables: (time, lev, lat, lon)

# TEMP                : potential temperature, C
# UVEL                : velocity in grid-x direction, cm/s
# VVEL                : velocity in grid-y direction, cm/s
# UVEL                : vertical velocity, cm/s
# SATL                : salinity, g/kg
# PV                  : potential voticity, 1/s/cm
# PD                  : potential density Ref to surface, g/cm^3


#=======================================================================================

#module load cdo/1.9.9
#module load ncl/6.6.2
#export NCL_POP_REMAP=/glade/work/xinyang/cesm1_2_2_1/

set expname         = Amazon
set CASE            = PI-control

# component and component_model must be matched
set component       = ocn               # lnd, atm, ocn, glc, ice, rof
set component_model = pop               # clm2, cam, pop

set dir_in          = /glade/scratch/xinyang/archive/$CASE/$component/hist 
set dir_out         = /glade/work/xinyang/experiment/program/$expname/$CASE/post-process/$component



set var_name        = UVEL            # TEMP, UVEL, VVEL, PV, PD, SALT
set y_start         = 0001
set y_end           = 0035
set timespan        = "01-35"              # 01-05 or 06-35
set m_start         = 01
set m_end           = 12


#####      Part 1: extracting specific variables, interpolation and output it monthly per file
foreach jj (`seq -f "%04g" $y_start  $y_end`)
echo $jj
foreach ii (`seq -f "%02g" $m_start  $m_end`)
echo $ii

rm -f /glade/work/xinyang/program//$expname/cases/$CASE/code/inside_code/vertical_intep_${var_name}.ncl

rm -f $dir_out/temp/$var_name.$CASE.$component_model.h.$jj-$ii.1x1d.nc

cat > /glade/work/xinyang/program//$expname/cases/$CASE/code/inside_code/vertical_intep_${var_name}.ncl << EOF
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"    
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"  
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/popRemap.ncl"  
;************************************************
begin
        infile01  = addfile ("$dir_out/store/y.$CASE.$component_model.h.$jj-$ii.nc","r")
        time     = infile01->time
        var      = infile01->${var_name}(:,0:26,:,:) 
;************************************************
; convert pop to a 1x1 degree grid
;************************************************
        remap_var = PopLatLon(var,"gx1v6","1x1d","bilin","da","100716")
        ;printVarSummary(remap_var)
  
        TIME          = var&time
       	z_t           = var&z_t
        z_t           = z_t*1.E-2         ; convert from cm to m
        z_t@long_name = "Depth (T grid)"  ; overwrite long name
        z_t@units     = "m"               ; fix units attribute
  
        LAT           = fspan(-89.5, 89.5,180)
        LON           = fspan(  0.5,359.5,360)
        LAT!0         = "lat"
        LAT&lat       = LAT
        LAT@long_name = "latitude"
        LAT@standard_name = "latitude"  
        LAT@units     = "degrees_north"
        LAT@axis      = "Y"
        LON!0         = "lon"
        LON&lon       = LON  
        LON@long_name = "longitude"
        LON@standard_name = "longitude"  
        LON@units     = "degrees_east"
        LON@axis      = "X"  
        nlat          = dimsizes(LAT)
        nlon          = dimsizes(LON)  
        nlev          = dimsizes(z_t)
;-------------------- output to NC file -----------------------------
        system("/bin/rm -f $dir_out/temp/$var_name.$CASE.$component_model.h.$jj-$ii.1x1d.nc")
        outfile = addfile("$dir_out/temp/$var_name.$CASE.$component_model.h.$jj-$ii.1x1d.nc","c")
        setfileoption(outfile,"DefineMode",True)
        fAtt = True
        fAtt@title = ""
        fileattdef(outfile,fAtt)
        dimNames = (/"time", "z_t" ,  "lat",  "lon"/)
        dimSizes = (/ -1   ,  nlev     ,   nlat,   nlon/)
        dimUnlim = (/ True ,  False    ,  False  ,  False/)
        filedimdef(outfile,dimNames,dimSizes,dimUnlim)
        ;-------------------------------------------------------------------------------
        filevardef(outfile,"time", typeof(TIME), getvardims(TIME))
        filevardef(outfile,"z_t",  typeof(z_t),  getvardims(z_t))
        filevardef(outfile,"lat",  typeof(TIME), getvardims(LAT))
        filevardef(outfile,"lon",  typeof(TIME), getvardims(LON))
        filevardef(outfile,"$var_name",typeof(remap_var),getvardims(remap_var))
        filevarattdef(outfile,"time", TIME)
        filevarattdef(outfile,"z_t", z_t)
        filevarattdef(outfile,"lat",  LAT)
        filevarattdef(outfile,"lon",  LON)
        filevarattdef(outfile,"$var_name",  remap_var)
        setfileoption(outfile,"DefineMode",False)
        ;-------------------------------------------------------------------------------
        outfile->time   = (/TIME/)
        outfile->z_t    = (/z_t/)
        outfile->lat    = (/LAT/)
        outfile->lon    = (/LON/)
        outfile->$var_name   = (/remap_var/)
        ;===============================================================================
end

EOF

ncl /glade/work/xinyang/program//$expname/cases/$CASE/code/inside_code/vertical_intep_${var_name}.ncl

end      
end
echo "Part 1 finished!"


#####      Part 2: concreating all monthly files into one multi-year file

cdo mergetime $dir_out/temp/$var_name.$CASE.$component_model.h.*.1x1d.nc $dir_out/temp/$var_name.$CASE.$component_model.h.${timespan}.1x1d.nc

rm -f $dir_out/temp/$var_name.$CASE.$component_model.h.${timespan}.1x1d.std.nc
cdo setcalendar,standard $dir_out/temp/$var_name.$CASE.$component_model.h.${timespan}.1x1d.nc $dir_out/temp/$var_name.$CASE.$component_model.h.${timespan}.1x1d.std.nc

rm -f $dir_out/$var_name.$CASE.$component_model.h.${timespan}.1x1d.nc
cdo settaxis,$y_start-01-01,12:00:00,1mon $dir_out/temp/$var_name.$CASE.$component_model.h.${timespan}.1x1d.std.nc $dir_out/$var_name.$CASE.$component_model.h.${timespan}.1x1d.nc

rm -f $dir_out/temp/*.nc
echo "Part 2 finished!"

echo "well done, Teresa, I deeply love you!"

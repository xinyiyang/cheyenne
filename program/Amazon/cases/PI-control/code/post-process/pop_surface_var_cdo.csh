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

#=======================================================================================
#surface variables: (time, lat, lon)

# HMXL                : mixed-layer depth, cm
# SSH                 : sea surface height, cm
# BSF                 : diagnostic barotropic streamfunction, sv
# PREC_F              : precipitation flux from CPL, kg/m2/s 

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

rm -f /glade/work/xinyang/program//$expname/cases/$CASE/code/inside_code/surf_POP2latlon.ncl
cat > /glade/work/xinyang/program//$expname/cases/$CASE/code/inside_code/surf_POP2latlon.ncl << EOF
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"    
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"  
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/popRemap.ncl"  
;************************************************
begin

        infile01  = addfile ("$dir_out/store/y.$CASE.$component_model.h.$jj-$ii.nc","r")
        time      = infile01->time
        mld       = infile01->HMXL(:,:,:)
        ssh       = infile01->SSH(:,:,:)
        bsf       = infile01->BSF(:,:,:)
        prf       = infile01->PREC_F(:,:,:)
  
;************************************************
; convert pop to a 1x1 degree grid
;************************************************
        remap_mld  = PopLatLon(mld,"gx1v6","1x1d","bilin","da","100716")
        ;printVarSummary(remap_mld)
        remap_ssh  = PopLatLon(ssh,"gx1v6","1x1d","bilin","da","100716")
        ;printVarSummary(remap_ssh)
        remap_bsf  = PopLatLon(bsf,"gx1v6","1x1d","bilin","da","100716")
        ;printVarSummary(remap_bsf)
        remap_prf  = PopLatLon(prf,"gx1v6","1x1d","bilin","da","100716")
        ;printVarSummary(remap_prf)
  
        TIME          = mld&time 
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

;-------------------- output to NC file -----------------------------
        system("/bin/rm -f $dir_out/temp/y.$CASE.$component_model.h.$jj-$ii.1x1d.nc")
        outfile = addfile("$dir_out/temp/y.$CASE.$component_model.h.$jj-$ii.1x1d.nc","c")
        setfileoption(outfile,"DefineMode",True)
        fAtt    = True
        fAtt@title = ""
        fileattdef(outfile,fAtt)
        dimNames = (/"time",  "lat",  "lon"/)
        dimSizes = (/ -1   ,     nlat,   nlon/)
        dimUnlim = (/ True ,   False  ,  False/)
        filedimdef(outfile,dimNames,dimSizes,dimUnlim)
        ;-------------------------------------------------------------------------------
        filevardef(outfile,"time", typeof(TIME), getvardims(TIME))
        filevardef(outfile,"lat",  typeof(TIME),  getvardims(LAT))
        filevardef(outfile,"lon",  typeof(TIME),  getvardims(LON))
        filevardef(outfile,"mld",typeof(remap_mld),getvardims(remap_mld))
        filevardef(outfile,"ssh",typeof(remap_ssh),getvardims(remap_ssh))
        filevardef(outfile,"bsf",typeof(remap_bsf),getvardims(remap_bsf))
        filevardef(outfile,"prf",typeof(remap_bsf),getvardims(remap_prf))
        filevarattdef(outfile,"time", TIME)
        filevarattdef(outfile,"lat",  LAT)
        filevarattdef(outfile,"lon",  LON)
        filevarattdef(outfile,"mld",  remap_mld)
        filevarattdef(outfile,"ssh",  remap_ssh)
        filevarattdef(outfile,"bsf",  remap_bsf)
        filevarattdef(outfile,"prf",  remap_prf)
        setfileoption(outfile,"DefineMode",False)
        ;-------------------------------------------------------------------------------
        outfile->time   = (/TIME/)
        outfile->lat    = (/LAT/)
        outfile->lon    = (/LON/)
        outfile->mld    = (/remap_mld/)
        outfile->ssh    = (/remap_ssh/)
        outfile->bsf    = (/remap_bsf/)
        outfile->prf    = (/remap_prf/)
        ;=====================================================================================
end 
EOF

ncl /glade/work/xinyang/program//$expname/cases/$CASE/code/inside_code/surf_POP2latlon.ncl

end      
end
echo "Part 1 finished!"


#####      Part 2: concreating all monthly files into one multi-year file

rm -f $dir_out/y.$CASE.$component_model.h.${timespan}.surface.1x1d.nc 
cdo mergetime $dir_out/temp/y.$CASE.$component_model.h.*.1x1d.nc $dir_out/y.$CASE.$component_model.h.${timespan}.surface.1x1d.nc
rm -f $dir_out/temp/y.$CASE.$component_model.h.*.1x1d.nc

rm -f $dir_out/y.$CASE.$component_model.h.${timespan}.surface.1x1d.std.nc
cdo setcalendar,standard $dir_out/y.$CASE.$component_model.h.${timespan}.surface.1x1d.nc $dir_out/y.$CASE.$component_model.h.${timespan}.surface.1x1d.std.nc
rm -f $dir_out/y.$CASE.$component_model.h.${timespan}.surface.1x1d.nc 

rm -f $dir_out/$CASE.$component_model.h.${timespan}.surface.1x1d.nc
cdo settaxis,$y_start-01-01,12:00:00,1mon $dir_out/y.$CASE.$component_model.h.${timespan}.surface.1x1d.std.nc $dir_out/$CASE.$component_model.h.${timespan}.surface.1x1d.nc
rm -f $dir_out/y.$CASE.$component_model.h.${timespan}.surface.1x1d.std.nc 

echo "well done, Teresa, I deeply love you!"

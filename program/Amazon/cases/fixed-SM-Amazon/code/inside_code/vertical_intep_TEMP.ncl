load "/glade/u/apps/dav/opt/ncl/6.6.2/intel/19.0.5//lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "/glade/u/apps/dav/opt/ncl/6.6.2/intel/19.0.5//lib/ncarg/nclscripts/csm/gsn_csm.ncl"    
load "/glade/u/apps/dav/opt/ncl/6.6.2/intel/19.0.5//lib/ncarg/nclscripts/csm/contributed.ncl"  
load "/glade/u/apps/dav/opt/ncl/6.6.2/intel/19.0.5//lib/ncarg/nclscripts/csm/popRemap.ncl"  
;************************************************
begin
        infile01  = addfile ("/glade/work/xinyang/experiment/program/Amazon/fixed-SM-Amazon/post-process/ocn/store/y.fixed-SM-Amazon.pop.h.0035-12.nc","r")
        time     = infile01->time
        var      = infile01->TEMP(:,0:26,:,:) 
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
        system("/bin/rm -f /glade/work/xinyang/experiment/program/Amazon/fixed-SM-Amazon/post-process/ocn/temp/TEMP.fixed-SM-Amazon.pop.h.0035-12.1x1d.nc")
        outfile = addfile("/glade/work/xinyang/experiment/program/Amazon/fixed-SM-Amazon/post-process/ocn/temp/TEMP.fixed-SM-Amazon.pop.h.0035-12.1x1d.nc","c")
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
        filevardef(outfile,"TEMP",typeof(remap_var),getvardims(remap_var))
        filevarattdef(outfile,"time", TIME)
        filevarattdef(outfile,"z_t", z_t)
        filevarattdef(outfile,"lat",  LAT)
        filevarattdef(outfile,"lon",  LON)
        filevarattdef(outfile,"TEMP",  remap_var)
        setfileoption(outfile,"DefineMode",False)
        ;-------------------------------------------------------------------------------
        outfile->time   = (/TIME/)
        outfile->z_t    = (/z_t/)
        outfile->lat    = (/LAT/)
        outfile->lon    = (/LON/)
        outfile->TEMP   = (/remap_var/)
        ;===============================================================================
end


load "/glade/u/apps/dav/opt/ncl/6.6.2/intel/19.0.5//lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "/glade/u/apps/dav/opt/ncl/6.6.2/intel/19.0.5//lib/ncarg/nclscripts/csm/gsn_csm.ncl"    
load "/glade/u/apps/dav/opt/ncl/6.6.2/intel/19.0.5//lib/ncarg/nclscripts/csm/contributed.ncl"  
load "/glade/u/apps/dav/opt/ncl/6.6.2/intel/19.0.5//lib/ncarg/nclscripts/csm/popRemap.ncl"  
;************************************************
begin

        infile01  = addfile ("/glade/work/xinyang/experiment/program/Amazon/fixed-SM-Amazon/post-process/ocn/store/y.fixed-SM-Amazon.pop.h.0035-12.nc","r")
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
        system("/bin/rm -f /glade/work/xinyang/experiment/program/Amazon/fixed-SM-Amazon/post-process/ocn/temp/y.fixed-SM-Amazon.pop.h.0035-12.1x1d.nc")
        outfile = addfile("/glade/work/xinyang/experiment/program/Amazon/fixed-SM-Amazon/post-process/ocn/temp/y.fixed-SM-Amazon.pop.h.0035-12.1x1d.nc","c")
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

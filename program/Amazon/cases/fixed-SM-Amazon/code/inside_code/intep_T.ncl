load "/glade/u/apps/dav/opt/ncl/6.6.2/intel/19.0.5//lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "/glade/u/apps/dav/opt/ncl/6.6.2/intel/19.0.5//lib/ncarg/nclscripts/csm/gsn_csm.ncl"    
load "/glade/u/apps/dav/opt/ncl/6.6.2/intel/19.0.5//lib/ncarg/nclscripts/csm/contributed.ncl"  
load "/glade/u/apps/dav/opt/ncl/6.6.2/intel/19.0.5//lib/ncarg/nclscripts/csm/popRemap.ncl"  
;************************************************
		begin
     			infile01  = addfile ("/glade/scratch/xinyang/archive/fixed-SM-Amazon/atm/hist/fixed-SM-Amazon.cam.h0.0035-12.nc","r")
		        var       = infile01->T                       ; select variable to ave
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
		        system("/bin/rm -f /glade/work/xinyang/experiment/program/Amazon/fixed-SM-Amazon/post-process/atm/temp/T.interp.fixed-SM-Amazon.cam.h0.0035-12.nc")
		        outfile = addfile("/glade/work/xinyang/experiment/program/Amazon/fixed-SM-Amazon/post-process/atm/temp/T.interp.fixed-SM-Amazon.cam.h0.0035-12.nc","c")
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
		        filevardef(outfile,"T",typeof(var_use),getvardims(var_use))
		        filevarattdef(outfile,"time", TIME)
		        filevarattdef(outfile,"lev", pnew)
		        filevarattdef(outfile,"lat",  LAT)
		        filevarattdef(outfile,"lon",  LON)
		        filevarattdef(outfile,"T",var_use)
		        setfileoption(outfile,"DefineMode",False)
		;-------------------------------------------------------------------------------
		        outfile->time   = (/TIME/)
		        outfile->lev    = (/pnew/)
		        outfile->lat    = (/LAT/)
		        outfile->lon    = (/LON/)
		        outfile->T   = (/var_use/)
		end 


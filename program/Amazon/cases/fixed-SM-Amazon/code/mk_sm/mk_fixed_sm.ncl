load "$NCARG_LIB/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_LIB/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_LIB/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_LIB/ncarg/nclscripts/csm/shea_util.ncl"

begin
     ;----------------------------------------------------------
     ;----
     ;---- Select region to be modified
     ;----
     ;----------------------------------------------------------
;     blat  =  32.0
;     elat  =  42.0
;     blon  =  -125.0  +  360.
;     elon  =  -115.0  +  360.

;      blat  =  -18.0
;      elat  =   4.0
;      blon  =  -76.0  +  360.
;      elon  =  -47  +  360.
      blat  =  -15.0
      elat  =   1.0
      blon  =  -76.0  +  360.
      elon  =  -50  +  360.

     ;----------------------------------------------------------
     ;----
     ;---- Select Directory and file
     ;---- Can be multiple files
     ;----
     ;----------------------------------------------------------
      g_data_month          =(/"01","02","03","04","05","06","07","08","09","10","11","12"/)
      ;e.g. /glade/work/xinyang/experiment/program/Amazon/PI-control/post-process/temp/PI-control.clm2.h1.climatology.02.nc
      g_data_path           = "/glade/work/xinyang/experiment/program/Amazon/PI-control/post-process/temp/PI-control.clm2.h1.climatology."+g_data_month
      outdir                = "/glade/work/xinyang/experiment/program/Amazon/PI-control/post-process/"
      
      ctrl_in1              =  addfile (g_data_path(0)+".nc", "r")   ; note the "s" of addfile
      clat                  =  ctrl_in1->cols1d_lat
      clon                  =  ctrl_in1->cols1d_lon
      h2osoi_liq01          =  ctrl_in1->SOILLIQ            ;[levgrnd | 15] x [column | 13693]
      h2osoi_ice01          =  ctrl_in1->SOILICE            ;[levgrnd | 15] x [column | 13693]

      nmonths  =  dimsizes(g_data_month)
      nlevsoi  =  dimsizes(ctrl_in1->SOILLIQ(:,0))+ 5 ; extra top 5 layers are snow layers
      ncolumn  =  dimsizes(clon)

     ;----------------------------------------------------------
     ;----
     ;---- Return indices contained within the desired domain
     ;----
     ;----------------------------------------------------------
     idomain   =   ind( clat.ge.blat  .and.  clat.le.elat  .and.  \
                        clon.ge.blon  .and.  clon.le.elon         )

     ;----------------------------------------------------------
     ;----
     ;---- Identify the region to apply the prescribed soil moisture
     ;----
     ;----------------------------------------------------------
     prescribed_mask  =  new( (/        nlevsoi,ncolumn/), float  )
     h2osoi_ice       =  new( (/nmonths,nlevsoi,ncolumn/), double )
     h2osoi_liq       =  new( (/nmonths,nlevsoi,ncolumn/), double )
     prescribed_mask  =  0.0
     ; top 5 layers are snow, 1st soil layer starts at 5 in NCL
     prescribed_mask(5:7,idomain)  =  1.0     

      do ff = 0,nmonths-1

        ;----------------------------------------------------------
        ;---- open the file
        ;----------------------------------------------------------
         ctrl_in            =  addfile (g_data_path(ff)+".nc", "r")
         h2osoi_liq(ff,5:19,:) =  ctrl_in->SOILLIQ
         h2osoi_ice(ff,5:19,:) =  ctrl_in->SOILICE

      end do       

           ;----------------------------------------------------------
     ;----
     ;---- Assign metadata for output purposes
     ;----
     ;----------------------------------------------------------
     prescribed_mask!0  =  "levtot"
     prescribed_mask!1  =  "column"

     h2osoi_ice!0  =  "time"
     h2osoi_ice!1  =  "levtot"
     h2osoi_ice!2  =  "column"

     h2osoi_liq!0  =  "time"
     h2osoi_liq!1  =  "levtot"
     h2osoi_liq!2  =  "column"

     time          =  ispan(1,12,1) * 1.0
     time!0        =  "time"
     time&time     =  time
     ;----------------------------------------------------------
     ;---- write to a new output file containing the experiment name
     ;----------------------------------------------------------
     outfile  =  "/glade/work/xinyang/program/Amazon/cesm/forcing/Amazon.lev1-3.nc"
     if( isfilepresent(outfile) ) then
         system("rm -rf "+outfile)
     end if
     ncout  =  addfile( outfile, "c" )

     ;===================================================================
     ; explicitly declare file definition mode. Improve efficiency.
     ;===================================================================
     setfileoption(ncout,"DefineMode",True)

     ;===================================================================
     ; predefine the coordinate variables and their dimensionality
     ; Note: to get an UNLIMITED record dimension, we set the dimensionality
     ; to -1 (or the actual size) and set the dimension name to True.
     ;===================================================================
     dimNames = (/"time", "levtot", "column" /)  
     dimSizes = (/ -1   ,  nlevsoi,  ncolumn /) 
     dimUnlim = (/ True ,  False  ,  False   /)   
     filedimdef(ncout,dimNames,dimSizes,dimUnlim)

     ;===================================================================
     ; predefine the the dimensionality of the variables to be written out
     ;===================================================================
     filevardef(ncout, "time"           , typeof(time           ) , getvardims(time)           ) 
     filevardef(ncout, "H2OSOI_LIQ"     , typeof(h2osoi_liq     ) , getvardims(h2osoi_liq)     )    
     filevardef(ncout, "H2OSOI_ICE"     , typeof(h2osoi_ice     ) , getvardims(h2osoi_ice)     )    
     filevardef(ncout, "PRESCRIBE_MASK" , typeof(prescribed_mask) , getvardims(prescribed_mask))    

     ;===================================================================
     ; Copy attributes associated with each variable to the file
     ; All attributes associated with each variable will be copied.
     ;====================================================================
     filevarattdef(ncout,"time"           , time           )                    ; copy time attributes
     filevarattdef(ncout,"H2OSOI_LIQ"     , h2osoi_liq     )                           
     filevarattdef(ncout,"H2OSOI_ICE"     , h2osoi_ice     )                           
     filevarattdef(ncout,"PRESCRIBE_MASK" , prescribed_mask)                           

     ;===================================================================
     ; explicitly exit file definition mode. **NOT REQUIRED**
     ;===================================================================
     setfileoption(ncout,"DefineMode",False)

     ncout->time            =   (/ time            /)
     ncout->H2OSOI_LIQ      =   (/ h2osoi_liq      /)
     ncout->H2OSOI_ICE      =   (/ h2osoi_ice      /)
     ncout->PRESCRIBE_MASK  =   (/ prescribed_mask /)

end 
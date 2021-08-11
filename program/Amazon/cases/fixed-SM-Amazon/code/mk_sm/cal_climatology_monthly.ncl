load "$NCARG_LIB/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_LIB/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_LIB/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_LIB/ncarg/nclscripts/csm/shea_util.ncl"

begin
     ;module load ncl/6.6.2 
     ;----------------------------------------------------------
     ;----
     ;---- Select Directory and file
     ;---- Can be multiple files
     ;----
     ;----------------------------------------------------------
      g_data_month          =(/"01"/)
      g_data_year           = (/"06","07","08","09","10","11","12","13","14","15","16","17","18","19","20","21","22","23","24","25","26","27","28","29","30","31","32","33","34","35"/)
      ;e.g. /glade/scratch/xinyang/archive/PI-control/lnd/hist/PI-control.clm2.h1.0035-12.nc
      g_data_path           = "/glade/scratch/xinyang/archive/PI-control/lnd/hist/PI-control.clm2.h1.00" +g_data_year
      outdir                = "/glade/work/xinyang/experiment/program/Amazon/PI-control/post-process/temp/"
      
      ctrl_in1              =  addfile (g_data_path(0)+"-"+g_data_month+".nc", "r")   ; note the "s" of addfile
      clat                  =  ctrl_in1->cols1d_lat
      clon                  =  ctrl_in1->cols1d_lon
      h2osoi_liq01          =  ctrl_in1->SOILLIQ            ;[time | 1] x [levgrnd | 15] x [column | 13693]
      h2osoi_ice01          =  ctrl_in1->SOILICE            ;[time | 1] x [levgrnd | 15] x [column | 13693]

      nyears   =  dimsizes(g_data_year)
      nlevsoi  =  dimsizes(ctrl_in1->SOILLIQ(0,:,0))
      ncolumn  =  dimsizes(clon)

      h2osoi_ice_allyear       =  new( (/nyears,nlevsoi,ncolumn/), typeof(h2osoi_ice01) )
      h2osoi_liq_allyear       =  new( (/nyears,nlevsoi,ncolumn/), typeof(h2osoi_liq01) )
      h2osoi_ice               =  new( (/       nlevsoi,ncolumn/), typeof(h2osoi_ice01) )
      h2osoi_liq               =  new( (/       nlevsoi,ncolumn/), typeof(h2osoi_liq01) )

      do ff = 0,nyears-1

        ;----------------------------------------------------------
        ;---- open the file
        ;----------------------------------------------------------
         ctrl_in = addfile (g_data_path(ff)+"-"+g_data_month+".nc", "r")
         h2osoi_liq_allyear(ff,:,:) =  ctrl_in->SOILLIQ
         h2osoi_ice_allyear(ff,:,:) =  ctrl_in->SOILICE

      end do 
      h2osoi_liq=dim_avg_n_Wrap(h2osoi_liq_allyear, 0)   ;[levgrnd | 15] x [column | 13693
      h2osoi_ice=dim_avg_n_Wrap(h2osoi_ice_allyear, 0)   ;[levgrnd | 15] x [column | 13693

     ;----------------------------------------------------------
     ;---- write to a new output file containing the experiment name
     ;----------------------------------------------------------
     outfile  =  outdir+"PI-control.clm2.h1.climatology."+g_data_month+".nc"
     if( isfilepresent(outfile) ) then
         system("rm -rf "+outfile)
     end if
     ncout  =  addfile( outfile, "c" )
     ncout->cols1d_lat            =   clat   
     ncout->SOILLIQ               =   h2osoi_liq
     ncout->SOILICE               =   h2osoi_ice
     ncout->cols1d_lon            =   clon
     print(" Well done!")
end 

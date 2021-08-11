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
#   Variables deleted:
### ADVT_ISOP,ADVS_ISOP,ADVT_SUBM,ADVS_SUBM,ADVT,ADVS,
### dTEMP_POS_2D,dTEMP_NEG_2D,DIA_DEPTH，
### FW,
### HOR_DIFF,HLS_SUBM,HDIFT,HDIFS,HBLT,
### IOFF_F，IFRAC，IAGE，INT_DEPTH,
### KVMIX,KVMIX_M,KAPPA_ISOP,KAPPA_THIC,
### MOC,MELT_F,MELTH_F，
### QSW_HBL，QSW_HTP,QFLUX,
### RHO_VINT,RESID_T,RESID_S,ROFF_F,
### SU,SV,SSH2,SFWF,SFWF_WRST,SNOW_F,SALT_F，
### TAUX2,TAUY2,TFW_T,TFW_S,TPOWER,TLT,TMXL,TBLT
### UVEL2,UISOP,USUBM,UET,UES,
### VVEL2,VDC_T,VDC_S,VVC,VISOP,VNT_ISOP,VNS_ISOP,VSUBM, VNT_SUBM,VNS_SUBM,VNT,VNS,
### WISOP，,WSUBM,WVEL2,WTT,WTS,
### XMXL,XBLT,


#=======================================================================================

#module load cdo/1.9.9
set expname         = Amazon
set CASE            = PI-control

# component and component_model must be matched
set component       = ocn               # lnd, atm, ocn, glc, ice, rof
set component_model = pop               # clm2, cam, pop

set dir_in          = /glade/scratch/xinyang/archive/$CASE/$component/hist 
set dir_out         = /glade/work/xinyang/experiment/program/$expname/$CASE/post-process/$component

set var_name        = UVEL2,VVEL2,dTEMP_POS_2D,dTEMP_NEG_2D,RHO_VINT,RESID_T,RESID_S,SU,SV,SSH2,SFWF,SFWF_WRST,TAUX2,TAUY2,FW,TFW_T,TFW_S,SNOW_F,MELT_F,ROFF_F,IOFF_F,SALT_F,MELTH_F,IFRAC,IAGE,QSW_HBL,KVMIX,KVMIX_M,TPOWER,VDC_T,VDC_S,VVC,KAPPA_ISOP,KAPPA_THIC,HOR_DIFF,DIA_DEPTH,TLT,INT_DEPTH,UISOP,VISOP,WISOP,ADVT_ISOP,ADVS_ISOP,VNT_ISOP,VNS_ISOP,USUBM,VSUBM,WSUBM,HLS_SUBM,ADVT_SUBM,ADVS_SUBM,VNT_SUBM,VNS_SUBM,HDIFT,HDIFS,WVEL2,UET,VNT,WTT,UES,VNS,WTS,ADVT,ADVS,QSW_HTP,QFLUX,XMXL,TMXL,HBLT,XBLT,TBLT
set y_start         = 0001
set y_end           = 0005
set timespan        = "01-05"              # 01-05 or 06-35
set m_start         = 01
set m_end           = 12


	foreach jj (`seq -f "%04g" $y_start  $y_end`)
	echo $jj
		foreach ii (`seq -f "%02g" $m_start  $m_end`)
		echo $ii
			rm -f $dir_out/temp/x.$CASE.$component_model.h.$jj-$ii.nc
			cdo sellevidx,1/28 $dir_in/$CASE.$component_model.h.$jj-$ii.nc $dir_out/temp/x.$CASE.$component_model.h.$jj-$ii.nc

			rm -f $dir_out/temp/y.$CASE.$component_model.h.$jj-$ii.nc
			cdo delvar,$var_name $dir_out/temp/x.$CASE.$component_model.h.$jj-$ii.nc $dir_out/store/y.$CASE.$component_model.h.$jj-$ii.nc	

			rm -f $dir_out/temp/x.$CASE.$component_model.h.$jj-$ii.nc
		end
	end


echo "well done, Teresa, I deeply love you!"

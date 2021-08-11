#!/bin/csh -f

## model: ACCESS-CM2   (1), ACCESS-ESM1-5 (2), BCC-CSM2-MR     (3), CAMS-CSM1-0   (4), 
##        CanESM5      (5), CESM2         (6), E3SM-1-0        (7), FGOALS-f3-L   (8),
##        GFDL-ESM4    (9), GISS-E2-1-G   (10), GISS-E2-1-H   (11), IPSL-CM6A-LR (12),
##        MIROC6      (13), MRI-ESM2-0    (14), NESM3         (15), NorESM2-MM    (16).   

set model_name      = (ACCESS-CM2 ACCESS-ESM1-5 BCC-CSM2-MR CAMS-CSM1-0 CanESM5 CESM2 E3SM-1-0 FGOALS-f3-L GFDL-ESM4 GISS-E2-1-G GISS-E2-1-H IPSL-CM6A-LR MIROC6 MRI-ESM2-0 NESM3 NorESM2-MM)

#set var            = pr    # pr, tos
#set var_ID         = Amon  # Amon, Omon
#set model_num       = (3 10 1 2 25 3 1 1 1 0 0 6 50 1 2 1)

set var             = tos    # pr, tos
set var_ID          = Omon  # Amon, Omon
set model_num       = (3 10 1 2 25 3 1 3 1 0 0 6 50 1 2 1)

## ensemble number
set model_index     = 16    # for selecting model

## ensemble number
set r_start         = 1
#set r_end           = 3


mkdir ${model_name[$model_index]}
mkdir ${model_name[$model_index]}/${var}

set dir_in          = /glade/scratch/xinyang/cmip6/ssp585/original/${model_name[$model_index]}/${var}
set dir_out         = /glade/scratch/xinyang/cmip6/ssp585/post-process/${model_name[$model_index]}/${var}
set dir_out2        = /glade/scratch/xinyang/cmip6/ssp585/post-process/ensmean/${var}       ## for ensemble mean 

# loop
	foreach ii (`seq -f "%01g" $r_start  ${model_num[$model_index]}`)
			echo $ii
			cdo remapbil,r360x180 ${dir_in}/${var}_${var_ID}_${model_name[$model_index]}_ssp585_r${ii}i1p1f1_gn_201501-210012.nc ${dir_out}/${var}_${var_ID}_${model_name[$model_index]}_ssp585_r${ii}i1p1f1_1x1_201501-210012.nc 
	end
set a = 
echo $a

if(${model_num[${model_index}]} == 1)then
	cp ${dir_out}/${var}_${var_ID}_${model_name[$model_index]}_ssp585_r1i1p1f1_1x1_201501-210012.nc ${dir_out2}/${var}_${var_ID}_${model_name[$model_index]}_ssp585_ensmean_1x1_201501-210012.nc
	echo "copy dir"
else 
	cdo ensmean ${dir_out}/${var}_${var_ID}_${model_name[$model_index]}_ssp585_r*i1p1f1_1x1_201501-210012.nc ${dir_out2}/${var}_${var_ID}_${model_name[$model_index]}_ssp585_ensmean_1x1_201501-210012.nc
	echo "cdo ensmean"
endif


echo "well done, Teresa, I deeply love you!"

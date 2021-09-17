#!/bin/csh -f

## ensemble number
set r_start         = 1
set r_end           = 32

## model: ACCESS-CM2   (3), ACCESS-ESM1-5 (30), BCC-CSM2-MR    (3), CAMS-CSM1-0   (2), 
##        CanESM5     (25), CESM2         (11), E3SM-1-0       (5), FGOALS-f3-L   (3),
##        GFDL-ESM4    (3), GISS-E2-1-G   (10), GISS-E2-1-H   (10), IPSL-CM6A-LR (32),
##        MIROC6      (50), MRI-ESM2-0     (5), NESM3          (5), NorESM2-MM    (3).   

set model           = "IPSL-CM6A-LR"

set var            = pr    # pr, tos
set var_ID         = Amon  # Amon, Omon

#set var             = tos    # pr, tos
#set var_ID          = Omon  # Amon, Omon

mkdir ${model}
mkdir ${model}/${var}

set dir_in          = /glade/scratch/xinyang/cmip6/historical/original/${model}/${var}
set dir_out         = /glade/scratch/xinyang/cmip6/historical/post-process/${model}/${var}
set dir_out2        = /glade/scratch/xinyang/cmip6/historical/post-process/ensmean/${var}       ## for ensemble mean 

# loop
	foreach ii (`seq -f "%01g" $r_start  $r_end`)
			echo $ii
			#cdo remapbil,r360x180 ${dir_in}/${var}_${var_ID}_${model}_historical_r${ii}i1p1f1_gn_185001-201412.nc ${dir_out}/${var}_${var_ID}_${model}_historical_r${ii}i1p1f1_1x1_185001-201412.nc
	end


cdo ensmean ${dir_out}/${var}_${var_ID}_${model}_historical_r*i1p1f1_1x1_185001-201412.nc ${dir_out2}/${var}_${var_ID}_${model}_historical_ensmean_1x1_185001-201412.nc

echo "well done, Teresa, I deeply love you!"

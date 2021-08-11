#!/bin/csh -f

## ensemble number
set r_start         = 1
set r_end           = 16

set model_name      = (ACCESS-CM2 ACCESS-ESM1-5 BCC-CSM2-MR CAMS-CSM1-0 CanESM5 CESM2 E3SM-1-0 FGOALS-f3-L GFDL-ESM4 GISS-E2-1-G GISS-E2-1-H IPSL-CM6A-LR MIROC6 MRI-ESM2-0 NESM3 NorESM2-MM)

set model_num       = (3 30 3 2 25 11 5 3 3 10 10 32 50 5 5 3)

## model: ACCESS-CM2   (3), ACCESS-ESM1-5 (30), BCC-CSM2-MR    (3), CAMS-CSM1-0   (2), 
##        CanESM5     (25), CESM2         (11), E3SM-1-0       (5), FGOALS-f3-L   (3),
##        GFDL-ESM4    (3), GISS-E2-1-G   (10), GISS-E2-1-H   (10), IPSL-CM6A-LR (32),
##        MIROC6      (50), MRI-ESM2-0     (5), NESM3          (5), NorESM2-MM    (3).   

set main_dir        = /glade/scratch/xinyang/cmip6/ssp585/original


# loop
	foreach ii (`seq -f "%01g" $r_start  $r_end`)
			echo $ii
			set model           = ${model_name[$ii]}
			echo $model
			mkdir ${main_dir}/${model}
			mkdir ${main_dir}/${model}/pr
			mkdir ${main_dir}/${model}/tos
	end

echo "well done, Teresa, I deeply love you!"

#======================================================================
#!/bin/csh 
# cheyenne: scratch, 90 days , 10 T
# cheyenne: work   , no limit, 1  T
# cheyenne: home   , no limit, 25 GB
#               created by Xinyi Yang 12/16/2020
#======================================================================


## ====================================================================
#   user-defined
## ====================================================================
export MACH='cheyenne'
export PROJECT='UHWM0042'

export expname='Amazon'
export CASE='PI-control'
export res='f19_g16'
export compset='B1850C5CN'

export CESMROOT=/glade/work/xinyang/cesm1_2_2_1                           # $CCSMROOT: CESM root directory.
export CASEROOT=/glade/work/xinyang/program/$expname/cesm/cases/${CASE}        # $CASEROOT: full pathname of the case ($CASE) will be created.
export EXEROOT=/glade/scratch/xinyang/CESM1_2_2/${CASE}/bld               # $EXEROOT : executable directory. 
export RUNDIR=/glade/scratch/xinyang/CESM1_2_2/${CASE}/run/               # $RUNDIR  : where CESM actually runs, normally set to $EXEROOT/run. 


#-------------------------------------------------------
# WORKFLOW: create new case, configure, compile and run
#-------------------------------------------------------
#rm -rf $CASEROOT
cd $CESMROOT/scripts

# create new case

./create_newcase -case ${CASEROOT} -res ${res} -compset  ${compset} -mach $MACH -compiler intel

#------------------
## set environment
#------------------

cd $CASEROOT

#./xmlchange -file env_run.xml -id RUN_TYPE -val 'hybrid' 
./xmlchange -file env_run.xml -id STOP_OPTION  -val  'nmonths'
./xmlchange -file env_run.xml -id STOP_N -val '60'
./xmlchange -file env_run.xml -id REST_N -val '12'


./xmlchange -file env_mach_pes.xml -id NTASKS_ATM -val '128'
./xmlchange -file env_mach_pes.xml -id NTHRDS_ATM -val '1'
./xmlchange -file env_mach_pes.xml -id ROOTPE_ATM -val '0'

./xmlchange -file env_mach_pes.xml -id NTASKS_LND -val '128'
./xmlchange -file env_mach_pes.xml -id NTHRDS_LND -val '1'
./xmlchange -file env_mach_pes.xml -id ROOTPE_LND -val '0'

./xmlchange -file env_mach_pes.xml -id NTASKS_ICE -val '128'
./xmlchange -file env_mach_pes.xml -id NTHRDS_ICE -val '1'
./xmlchange -file env_mach_pes.xml -id ROOTPE_ICE -val '0'

./xmlchange -file env_mach_pes.xml -id NTASKS_OCN -val '128'
./xmlchange -file env_mach_pes.xml -id NTHRDS_OCN -val '1'
./xmlchange -file env_mach_pes.xml -id ROOTPE_OCN -val '0'

./xmlchange -file env_mach_pes.xml -id NTASKS_GLC -val '128'
./xmlchange -file env_mach_pes.xml -id NTHRDS_GLC -val '1'
./xmlchange -file env_mach_pes.xml -id ROOTPE_GLC -val '0'

./xmlchange -file env_mach_pes.xml -id NTASKS_CPL -val '128'
./xmlchange -file env_mach_pes.xml -id NTHRDS_CPL -val '1'
./xmlchange -file env_mach_pes.xml -id ROOTPE_CPL -val '0'

./xmlchange -file env_mach_pes.xml -id NTASKS_ROF -val '128'
./xmlchange -file env_mach_pes.xml -id NTHRDS_ROF -val '1'
./xmlchange -file env_mach_pes.xml -id ROOTPE_ROF -val '0'

./xmlchange -file env_mach_pes.xml -id NTASKS_WAV -val '128'
./xmlchange -file env_mach_pes.xml -id NTHRDS_WAV -val '1'
./xmlchange -file env_mach_pes.xml -id ROOTPE_WAV -val '0'


./xmlchange -file env_run.xml -id RESUBMIT -val '6'

#------------------
## configure
#------------------
cd $CASEROOT
# env_mech_pes.xml variables need to be changed before invoking ./cesm_setup. Otherwise, ./cesm_setup -clean.
./cesm_setup
./xmlchange -file env_build.xml -id EXEROOT   -val $EXEROOT
./xmlchange -file env_run.xml   -id RUNDIR    -val $RUNDIR 


#-------------------------------
## modifing setting of namelist
#-------------------------------

# Wanna revise the setting on namelist, just delete the lines below.  
cat << EOF >> $CASEROOT/user_nl_clm
 hist_fincl2 = 'H2OSOI', 'SOILLIQ','SOILICE'
 hist_dov2xy = .true., .false.
 hist_type1d_pertape = ' ', 'COLS'
 hist_mfilt       =  1,1 
 hist_nhtfrq      =  0,0 

EOF

#------------------
## build
#------------------
cd $CASEROOT
 ./preview_namelists
./${CASE}.build

#------------------
## submit
#------------------
./${CASE}.submit



exit
 
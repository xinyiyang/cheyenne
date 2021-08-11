#======================================================================
#!/bin/bash
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
export CASE='hteng_reproduce'
export res='f09_f09'
export compset='F1850'

export CESMROOT=/glade/work/xinyang/cesm1_2_2_1                           # $CCSMROOT: CESM root directory.
export CASEROOT=/glade/work/xinyang/program/$expname/cesm/cases/${CASE}        # $CASEROOT: full pathname of the case ($CASE) will be created.
export EXEROOT=/glade/scratch/xinyang/CESM1_2_2/${CASE}/bld               # $EXEROOT : executable directory. 
export RUNDIR=/glade/scratch/xinyang/CESM1_2_2/${CASE}/run/               # $RUNDIR  : where CESM actually runs, normally set to $EXEROOT/run. 


#-------------------------------------------------------
# WORKFLOW: create new case, configure, compile and run
#-------------------------------------------------------
rm -rf $CASEROOT
cd $CESMROOT/scripts

# create new case

./create_newcase -case ${CASEROOT} -res ${res} -compset  ${compset} -mach $MACH -compiler intel

#------------------
## set environment
#------------------

cd $CASEROOT

#./xmlchange -file env_run.xml -id RUN_TYPE -val 'startup' 
#./xmlchange -file env_run.xml -id STOP_OPTION  -val  'nmonths'
#./xmlchange -file env_run.xml -id STOP_N -val '1'


#------------------
## configure
#------------------
cd $CASEROOT
# env_mech_pes.xml variables need to be changed before invoking ./cesm_setup. Otherwise, ./cesm_setup -clean.
./cesm_setup
./xmlchange -file env_build.xml -id EXEROOT   -val $EXEROOT
./xmlchange -file env_run.xml   -id RUNDIR    -val $RUNDIR 


#------------------------------------------------------------------
## modification of setting prescribed Soil Moisture: two main steps
#-------------------------------------------------------------------

# 1.copy modified sourcecodes
cp -rf /glade/work/xinyang/program/Amazon/cesm/modified_src_scl/* ${CASEROOT}/SourceMods/src.clm/

# 2. modifing setting of namelist: 
# adding user-defined varaibles in namelist NEEDS TO REVISE $CESMROOT/models/lnd/clm/bld/ build-namelist file and 
# */namelist_files/*.xml (namelist_defaults_clm4_0.xml & namelist_definition_clm4_0.xml). Otherwise, will get error
# "CLM build-namelist ERROR: Invalid namelist variable". Three files in total.

# copy modified namelist (1) or modify directly (2)

# 1
cp /glade/work/xinyang/program/Amazon/cesm/namelist/user_nl_clm  ${caseroot}/user_nl_clm 

# 2
#cat << EOF >> ${caseroot}/user_nl_clm
#&clm_inparm
# fsoilprescribed  =  "/glade/work/xinyang/program/Amazon/cesm/forcing/P1_lev1.nc"
# hist_mfilt       =  1,365 
# hist_nhtfrq      =  0,-24  
# hist_fincl2      =  'SOILWATER_10CM', 'SOILLIQ', 'H2OSOI',
#
#EOF

#------------------
## build
#------------------
cd $CASEROOT
./${CASE}.build

#------------------
## submit
#------------------
./${CASE}.submit



exit
 
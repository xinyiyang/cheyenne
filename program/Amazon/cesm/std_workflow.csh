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


#------------------
# WORKFLOW: create new case, configure, compile and run
#------------------
rm -rf $CASEROOT
cd $CESMROOT/scripts

# create new case

./create_newcase -case ${CASEROOT} -res ${res} -compset  ${compset} -mach $MACH -compiler intel

#------------------
## set environment
#------------------

cd $CASEROOT

./xmlchange -file env_run.xml -id RUN_TYPE -val 'branch' 
./xmlchange -file env_run.xml -id RUN_STARTDATE -val $icyr'-07-01'
./xmlchange -file env_run.xml -id RUN_REFDATE -val $icyr'-07-01' 
./xmlchange -file env_run.xml -id RUN_REFCASE -val 'PJun0_lev1-2_1mon-'$member 
./xmlchange -file env_run.xml -id STOP_OPTION  -val  'nmonths'
./xmlchange -file env_run.xml -id STOP_N -val '8'
./xmlchange -file env_run.xml -id REST_N -val '8'
./xmlchange -file env_run.xml -id GET_REFCASE -val 'FALSE'

#------------------
## configure
#------------------
cd $CASEROOT
  
./cesm_setup
./xmlchange -file env_build.xml -id EXEROOT   -val $EXEROOT
./xmlchange -file env_run.xml   -id RUNDIR    -val $RUNDIR 

#------------------
## build
#------------------

cp -rf ${CASEROOT_INI}/SourceMods ${CASEROOT}
cp -rf /glade/work/leishanj/CESM1_2_2/sst_nudging/* ${CASEROOT}/SourceMods/src.pop2

# sed -i "62s/^.*$/set nrevsn_rtm = \"nrevsn_rtm=\'\$\{RUN_REFCASE\}.rtm.r.\$\{RUN_REFDATE\}-\$\{RUN_REFTOD\}.nc\'\"/" ${CASEROOT}/Buildconf/rtm.buildnml.csh  #it is a bug of cesm

cd $CASEROOT
csh ./${CASE}.build

cp ${RUNDIR_INI}/${CASE_INI}*${YEAR_INI}-${MONTH_INI}-01* ${RUNDIR}
cp ${RUNDIR_INI}/${CASE_INI}*${YEAR_INI_OCN}-${MONTH_INI_OCN}-01* ${RUNDIR}
cp ${RUNDIR_INI}/rpointer* ${RUNDIR}
change_rpointer ${RUNDIR} ${YEAR_INI} ${MONTH_INI} 01
change_rpointer_ocn ${RUNDIR} ${YEAR_INI_OCN} ${MONTH_INI_OCN} 01

# sed -i "/chmod.*\+x.*qsub_submit.csh/,+2000d" ./${CASE}.run

# csh ./${CASE}.run

cat << EOF >> ${RUNDIR}/pop2_in
&res_nml
forcing_infile_sst='/glade/work/leishanj/CESM1_2_2/sst_flow/ideal/ctrl/TALideal/sst/obsclim/day/sst'
forcing_infile_spc='/glade/work/leishanj/CESM1_2_2/sst_flow/ideal/ctrl/TALideal/spc/day/spc'
/
EOF

exit
 
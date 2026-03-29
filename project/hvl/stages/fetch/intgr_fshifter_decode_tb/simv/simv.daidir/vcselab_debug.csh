#!/bin/csh -f

cd /home/ecelrc/students/aak3265/MICROARCH/project/hvl/stages/fetch/intgr_fshifter_decode_tb/simv

#This ENV is used to avoid overriding current script in next vcselab run 
setenv SNPS_VCSELAB_SCRIPT_NO_OVERRIDE  1

/usr/local/packages/synopsys_2022/vcs/T-2022.06/linux64/bin/vcselab $* \
    -o \
    simv \
    -nobanner \

cd -


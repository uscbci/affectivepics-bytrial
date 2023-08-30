#!/opt/conda/bin/python

import os,sys
from subprocess import call

featfolder = sys.argv[1]
print("Making reg folder for %s" % featfolder)

FLYWHEEL_BASE = '/flywheel/v0' # On Flywheel
#FLYWHEEL_BASE = '/Users/bciuser/fMRI/flywheel/affint/local_gear_testing/input' #Local testing

regfolder = "%s/reg" % featfolder
if not os.path.exists(regfolder):
	os.mkdir(regfolder)

identity_matrix = "%s/ident.mat" % FLYWHEEL_BASE
standard_image = "%s/standard.nii.gz" % FLYWHEEL_BASE

command = "cp %s/example_func.nii.gz %s/reg/example_func.nii.gz " % (featfolder,featfolder)
print(command)
call(command,shell=True)

command = "cp %s %s/reg/standard.nii.gz" % (standard_image,featfolder)
print(command)
call(command,shell=True)

command = "cp %s %s/reg/example_func2standard.mat" % (identity_matrix,featfolder)
print(command)
call(command,shell=True)

command = "cp %s %s/reg/standard2example_func.mat" % (identity_matrix,featfolder)
print(command)
call(command,shell=True)
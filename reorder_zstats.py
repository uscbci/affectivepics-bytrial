#!/opt/conda/bin/python

import os
import shutil
import csv
import pandas as pd
import sys
from subprocess import call

#command line options
if (len(sys.argv) < 2):
	print ("\n\tusage: %s <subject>\n") % sys.argv[0]
	sys.exit()
else:
	subject = sys.argv[1]

print("Reordering Affective Picture zstat images...")

FLYWHEEL_BASE="/flywheel/v0"
# FLYWHEEL_BASE = "/Volumes/BCI/TWCF2/Flywheel_gears/affint_RL"
OUTPUT_DIR="%s/output" % FLYWHEEL_BASE
INPUT_DIR="%s/input" % FLYWHEEL_BASE

reorder_file="%s/%s_emotion_order.csv" % (INPUT_DIR, subject)
df = pd.read_csv(reorder_file)

#Make output folder
newfolder="%s/%s_new_stats" % (OUTPUT_DIR,subject)
if not os.path.exists(newfolder):
	print("Making folder %s",newfolder)
	os.mkdir(newfolder)


for i, row in df.iterrows():
	print("Copying - OG Names...")
	#og_names = f"flywheel/v0/output/{subject}_affectivepictures_run{row[0]}.feat/stats/zstat{row[1]}.nii.gz"
	og_names = "%s/output/%s_affectivepictures_run%s.feat/stats/zstat%s.nii.gz" % (FLYWHEEL_BASE,subject, row[0], row[1])

	print(og_names)
	print("Creating...")
	#new_names = f"flywheel/v0/output/{subject}_new_stats/zstat{row[2]}.nii.gz"
	new_names = "%s/output/%s_new_stats/zstat%s.nii.gz" % (FLYWHEEL_BASE,subject, row[2])

	print(new_names)
	if not os.path.exists(og_names):
		print("Original file does not exist")
	elif os.path.exists(new_names):
		print("New file already exists")
	else:
		#shutil.copy(og_names, new_names)
		os.system("cp %s %s" %(og_names,new_names))
		print("Copied\n")

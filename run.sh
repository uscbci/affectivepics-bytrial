#! /bin/bash
#
#

# Edited 8.29.23 RL 
###############################################################################
# Built to flywheel-v0 spec.

CONTAINER=affint-feat
echo -e "$CONTAINER  Initiated"

FLYWHEEL_BASE=/flywheel/v0
OUTPUT_DIR=$FLYWHEEL_BASE/output
INPUT_DIR=$FLYWHEEL_BASE/input
MANIFEST=$FLYWHEEL_BASE/manifest.json
CONFIG_FILE=$FLYWHEEL_BASE/config.json
DATA_DIR=$INPUT_DIR

[ ! -d ${INPUT_DIR} ] && mkdir ${INPUT_DIR}

#Colors
RED='\033[0;31m'
NC='\033[0m'

###############################################################################
# Configure the ENV

export FSLDIR=/usr/local/fsl
source $FSLDIR/etc/fslconf/fsl.sh
export USER=Flywheel
source ~/.bashrc


##############################################################################
# Parse configuration

function parse_config {

  CONFIG_FILE=$FLYWHEEL_BASE/config.json
  MANIFEST_FILE=$FLYWHEEL_BASE/manifest.json

#   if [[ -f $CONFIG_FILE ]]; then
#     echo "$(cat $CONFIG_FILE | jq -r '.config.'$1)"
#   else
#     CONFIG_FILE=$MANIFEST_FILE
#     echo "$(cat $MANIFEST_FILE | jq -r '.config.'$1'.default')"
#   fi
 }



###############################################################################
# Gather input files

#run script to get input files
${FLYWHEEL_BASE}/get_files.py

#unzip the logfiles
mkdir ${DATA_DIR}/logs
unzip ${DATA_DIR}/logfiles.zip -d ${DATA_DIR}/logs

echo Looking in /input/logs:
ls ${INPUT_DIR}/logs

#unzip reorder file
unzip ${DATA_DIR}/AffectivePics_StimReorder.zip -d ${DATA_DIR} 

#echo Lets look inside $INPUT_DIR
ls $INPUT_DIR

echo "LISTING FILES IN FLYWHEEL_BASE:"
ls ${FLYWHEEL_BASE}
echo ""
echo ""

###############################################################################
# Determine Subject ID

subfolder=`find $INPUT_DIR/*affpics1_cleaned* -maxdepth 0 | head -1`
echo "Testing length of $subfolder: ${#subfolder}"
if [[ ${#subfolder} > 56 ]]
then
  echo "3digit subject number detected"
  subject=${subfolder: 19:5}
else
  echo "2digit subject number detected"
  subject=${subfolder: 19:4}
fi

echo "Subject is $subject"

####################################################################
# AFFECTIVEPICTURES ANALYSIS
####################################################################

TEMPLATE=affectivepictures_template.fsf

for RUN in {1..3}
do
	echo -e "\n\n${CONTAINER} Beginning analysis for affective pictures run ${RUN}"

	INPUT_DATA=${INPUT_DIR}/${subject}_affpics${RUN}_cleaned_standard.nii.gz
	FEAT_OUTPUT_DIR=${OUTPUT_DIR}/${subject}_affectivepictures_run${RUN}.feat
	NEUTRAL1_EV=${DATA_DIR}/logs/${subject}_affectivepictures_run${RUN}_Neutral1.txt
  NEUTRAL2_EV=${DATA_DIR}/logs/${subject}_affectivepictures_run${RUN}_Neutral2.txt
  NEUTRAL3_EV=${DATA_DIR}/logs/${subject}_affectivepictures_run${RUN}_Neutral3.txt
	FEAR1_EV=${DATA_DIR}/logs/${subject}_affectivepictures_run${RUN}_Fear1.txt
  FEAR2_EV=${DATA_DIR}/logs/${subject}_affectivepictures_run${RUN}_Fear2.txt
  FEAR3_EV=${DATA_DIR}/logs/${subject}_affectivepictures_run${RUN}_Fear3.txt
	HAPPY1_EV=${DATA_DIR}/logs/${subject}_affectivepictures_run${RUN}_Happy1.txt
  HAPPY2_EV=${DATA_DIR}/logs/${subject}_affectivepictures_run${RUN}_Happy2.txt
  HAPPY3_EV=${DATA_DIR}/logs/${subject}_affectivepictures_run${RUN}_Happy3.txt
	SAD1_EV=${DATA_DIR}/logs/${subject}_affectivepictures_run${RUN}_Sad1.txt
  SAD2_EV=${DATA_DIR}/logs/${subject}_affectivepictures_run${RUN}_Sad2.txt
  SAD3_EV=${DATA_DIR}/logs/${subject}_affectivepictures_run${RUN}_Sad3.txt
	DISGUST1_EV=${DATA_DIR}/logs/${subject}_affectivepictures_run${RUN}_Disgust1.txt
  DISGUST2_EV=${DATA_DIR}/logs/${subject}_affectivepictures_run${RUN}_Disgust2.txt
  DISGUST3_EV=${DATA_DIR}/logs/${subject}_affectivepictures_run${RUN}_Disgust3.txt


	TEMPLATE=$FLYWHEEL_BASE/affectivepictures_template.fsf
	DESIGN_FILE=${OUTPUT_DIR}/affectivepictures_run${RUN}.fsf
	cp ${TEMPLATE} ${DESIGN_FILE}

  #Check number of timepoints in data
  echo INPUT DATA is ${INPUT_DATA}
  NUMTIMEPOINTS=`fslinfo ${INPUT_DATA} | grep ^dim4 | awk {'print $2'}`

  #Should be 120 for these runs
  if [ $NUMTIMEPOINTS -eq 186 ]; then
    echo "Number of timepoints is correct at ${NUMTIMEPOINTS}"
  else
    echo -e "${RED}WARNING!!! Number of timepoints should be 186 but is ${NUMTIMEPOINTS} ${NC}"
  fi

  VAR_STRINGS=( INPUT_DATA FEAT_OUTPUT_DIR NEUTRAL1_EV NEUTRAL2_EV NEUTRAL3_EV FEAR1_EV FEAR2_EV FEAR3_EV HAPPY1_EV HAPPY2_EV HAPPY3_EV SAD1_EV SAD2_EV SAD3_EV DISGUST1_EV DISGUST2_EV DISGUST3_EV NUMTIMEPOINTS)


	# loop through and preform substitution
	for var_name in ${VAR_STRINGS[@]}; do

	  var_val=` eval 'echo $'$var_name `

	  echo will substitute $var_val for $var_name in design file
	  #We need to replace and backslashes with "\/"
	  var_val=` echo ${var_val////"\/"} `

	  sed -i -e "s/\^${var_name}\^/${var_val}/g" ${DESIGN_FILE}
	  echo sed -i -e "s/\^${var_name}\^/${var_val}/g" ${DESIGN_FILE}

	done

	# RUN THE Algorithm with the .FSF FILE
	ls $INPUT_DATA

	echo Starting FEAT for Affective Pictures run ${RUN}...
	time feat ${DESIGN_FILE}
	FEAT_EXIT_STATUS=$?

	if [[ $FEAT_EXIT_STATUS == 0 ]]; then
	  echo -e "FEAT completed successfully!"
	fi

	echo What have we got now
	ls ${OUTPUT_DIR}

  #add a fake reg folder
  ${FLYWHEEL_BASE}/make_reg_folder.py ${FEAT_OUTPUT_DIR}

	# Upon success, convert index to a webpage
	if [[ $FEAT_EXIT_STATUS == 0 ]]; then
	  # Convert index to standalone index
	  echo "$CONTAINER  generating output html..."
	  output_html_files=$(find ${FEAT_OUTPUT_DIR} -type f -name "report_poststats.html")
	  for f in $output_html_files; do
	    web2htmloutput=${OUTPUT_DIR}/${subject}_affpics_run${RUN}_`basename $f`
	    python /opt/webpage2html/webpage2html.py -q -s "$f" > "$web2htmloutput"
	  done
	fi



done

####################################################################
# AFFECTIVEPICTURES PREPARE FOR MVPA
####################################################################


#RUN THE CONCATENATION SCRIPT
#${FLYWHEEL_BASE}/mvpa_prepare.py ${subject}






#RUN THE REORDER SCRIPT - RL 11.15.22
${FLYWHEEL_BASE}/reorder_zstats.py ${subject}


#### TRYING TO FSLMERGE ALL OF THE REORDERED ZSTATS - RL 11.15.22 ####
time fslmerge -t ${OUTPUT_DIR}/${subject}_all_zstats_bytrial.nii.gz ${OUTPUT_DIR}/${subject}_new_stats/zstat1.nii.gz ${OUTPUT_DIR}/${subject}_new_stats/zstat2.nii.gz ${OUTPUT_DIR}/${subject}_new_stats/zstat3.nii.gz ${OUTPUT_DIR}/${subject}_new_stats/zstat4.nii.gz ${OUTPUT_DIR}/${subject}_new_stats/zstat5.nii.gz ${OUTPUT_DIR}/${subject}_new_stats/zstat6.nii.gz ${OUTPUT_DIR}/${subject}_new_stats/zstat7.nii.gz ${OUTPUT_DIR}/${subject}_new_stats/zstat8.nii.gz ${OUTPUT_DIR}/${subject}_new_stats/zstat9.nii.gz ${OUTPUT_DIR}/${subject}_new_stats/zstat10.nii.gz ${OUTPUT_DIR}/${subject}_new_stats/zstat11.nii.gz ${OUTPUT_DIR}/${subject}_new_stats/zstat12.nii.gz ${OUTPUT_DIR}/${subject}_new_stats/zstat13.nii.gz ${OUTPUT_DIR}/${subject}_new_stats/zstat14.nii.gz ${OUTPUT_DIR}/${subject}_new_stats/zstat15.nii.gz ${OUTPUT_DIR}/${subject}_new_stats/zstat16.nii.gz ${OUTPUT_DIR}/${subject}_new_stats/zstat17.nii.gz ${OUTPUT_DIR}/${subject}_new_stats/zstat18.nii.gz ${OUTPUT_DIR}/${subject}_new_stats/zstat19.nii.gz ${OUTPUT_DIR}/${subject}_new_stats/zstat20.nii.gz ${OUTPUT_DIR}/${subject}_new_stats/zstat21.nii.gz ${OUTPUT_DIR}/${subject}_new_stats/zstat22.nii.gz ${OUTPUT_DIR}/${subject}_new_stats/zstat23.nii.gz ${OUTPUT_DIR}/${subject}_new_stats/zstat24.nii.gz ${OUTPUT_DIR}/${subject}_new_stats/zstat25.nii.gz ${OUTPUT_DIR}/${subject}_new_stats/zstat26.nii.gz ${OUTPUT_DIR}/${subject}_new_stats/zstat27.nii.gz ${OUTPUT_DIR}/${subject}_new_stats/zstat28.nii.gz ${OUTPUT_DIR}/${subject}_new_stats/zstat29.nii.gz ${OUTPUT_DIR}/${subject}_new_stats/zstat30.nii.gz ${OUTPUT_DIR}/${subject}_new_stats/zstat31.nii.gz ${OUTPUT_DIR}/${subject}_new_stats/zstat32.nii.gz ${OUTPUT_DIR}/${subject}_new_stats/zstat33.nii.gz ${OUTPUT_DIR}/${subject}_new_stats/zstat34.nii.gz ${OUTPUT_DIR}/${subject}_new_stats/zstat35.nii.gz ${OUTPUT_DIR}/${subject}_new_stats/zstat36.nii.gz ${OUTPUT_DIR}/${subject}_new_stats/zstat37.nii.gz ${OUTPUT_DIR}/${subject}_new_stats/zstat38.nii.gz ${OUTPUT_DIR}/${subject}_new_stats/zstat39.nii.gz ${OUTPUT_DIR}/${subject}_new_stats/zstat40.nii.gz ${OUTPUT_DIR}/${subject}_new_stats/zstat41.nii.gz ${OUTPUT_DIR}/${subject}_new_stats/zstat42.nii.gz ${OUTPUT_DIR}/${subject}_new_stats/zstat43.nii.gz ${OUTPUT_DIR}/${subject}_new_stats/zstat44.nii.gz ${OUTPUT_DIR}/${subject}_new_stats/zstat45.nii.gz
rm -r ${OUTPUT_DIR}/${subject}_new_stats

#### TRYING TO MERGE WITHOUT THE RUN FORLOOP - RL 11.15.22 ####


#NOW WE CAN ZIP THE FEAT FOLDERS
# CLEANUP THE OUTPUT DIRECTORIES

for RUN in {1..3}
do
  FEAT_OUTPUT_DIR=${OUTPUT_DIR}/${subject}_affectivepictures_run${RUN}.feat
  echo feat directory is ${FEAT_OUTPUT_DIR}

  if [[ $FEAT_EXIT_STATUS == 0 ]]; then

    echo -e "${CONTAINER}  Compressing outputs..."

    # Zip and move the relevant files to the output directory
    zip -rq ${OUTPUT_DIR}/${subject}_affectivepictures_run${RUN}.zip ${FEAT_OUTPUT_DIR}
    rm -rf ${FEAT_OUTPUT_DIR}

  fi
done
echo Lets see what we have after zipping etc
ls ${OUTPUT_DIR}

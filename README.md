# affectivepics-gear
Flywheel gear, analyzing the affective pictures task data by individual trial and reorganizing zstat outputs to the same order per subject.

This gear will analyze preprocessed fMRI data selected on Flywheel and run a FEAT GLM analysis across images (by trial). It will then run a python script to reorder all of the resulting zstats, so that each participant has a 4-dimensional nifti file as their final output, containing all the zstats arranged in the same order across subjects. 

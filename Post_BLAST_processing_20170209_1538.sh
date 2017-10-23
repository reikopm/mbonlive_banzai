/home/mbonteam/USF/Anni/scripts
SCRIPT_DIR=/home/mbonteam/dev
RSCRIPTS=/home/mbonteam/MBARI/reiko/scripts
###################################################################################################
# CHANGE THESE DIRECTORIES TO YOUR DIRECTORIES
ANALYSIS_DIR=/home/mbonteam/USF/Anni/processed/18S/18S_0316/Analysis_20170209_1538
DIR=/home/mbonteam/USF/Anni/processed/18S/18S_0316/Analysis_20170209_1538/all_lib
START_TIME=20170209_1538
param_file=18S_params.sh
BIOM_FILE=18S_0316
###################################################################################################

OTU_table="${DIR}"/OTUs_swarm/OTU_table.csv
# Write a log file of output from this script (everything that prints to terminal)
LOGFILE="${ANALYSIS_DIR}"/all_lib/Post_MEGANlogfile.txt
exec > >(tee "${LOGFILE}") 2>&1

source "${param_file}"

# run megan script
gunzip "${DIR}"/*.xml.gz
bash "${DIR}"/megan_script.sh

		# Modify the MEGAN output so that it is a standard CSV file with clusterID, N_reads, and Taxon
		echo '**sed process on megan, remove size= text'
		sed 's|;size=|,|' <"${DIR}"/meganout_${COLLAPSE_RANK1}.csv >"${DIR}"/meganout_${COLLAPSE_RANK1}_mod.csv
		sed 's|;size=|,|' <"${DIR}"/meganout_${COLLAPSE_RANK2}.csv >"${DIR}"/meganout_${COLLAPSE_RANK2}_mod.csv
		sed 's|;size=|,|' <"${DIR}"/meganout_${COLLAPSE_RANK3}.csv >"${DIR}"/meganout_${COLLAPSE_RANK3}_mod.csv
		sed 's|;size=|,|' <"${DIR}"/meganout_kingdom.csv >"${DIR}"/meganout_Kingdom_mod.csv
		sed 's|;size=|,|' <"${DIR}"/meganout_species.csv >"${DIR}"/meganout_Species_mod.csv
		sed 's|;size=|,|' <"${DIR}"/meganout_class.csv >"${DIR}"/meganout_Class_mod.csv
		sed 's|;size=|,|' <"${DIR}"/meganout_order.csv >"${DIR}"/meganout_Order_mod.csv
		# Some taxanomic names have single quotes in them, this messes up the biom obs metadata processing, mostly because of PYTHON and the stupid way it handles quotes
		sed -i 's/\x27//g' "${DIR}"/meganout_${COLLAPSE_RANK1}_mod.csv
		sed -i 's/\x27//g' "${DIR}"/meganout_${COLLAPSE_RANK2}_mod.csv
		sed -i 's/\x27//g' "${DIR}"/meganout_${COLLAPSE_RANK3}_mod.csv
		sed -i 's/\x27//g' "${DIR}"/meganout_Kingdom_mod.csv
		sed -i 's/\x27//g' "${DIR}"/meganout_Species_mod.csv
		sed -i 's/\x27//g' "${DIR}"/meganout_Class_mod.csv
		sed -i 's/\x27//g' "${DIR}"/meganout_Order_mod.csv

		# rm "${DIR}"/meganout_${COLLAPSE_RANK1}.csv 
		# Run the R script, passing the current tag directory as the directory to which R will "setwd()"
		echo '**Rscript megan_plotter_reiko.R Based on MEGAN output.' "${DIR}"
		#Rscript "$SCRIPT_DIR/megan_plotter.R" "${DIR}"
		Rscript "/home/mbonteam/MBARI/reiko/scripts/megan_plotter_reiko.R" "${DIR}"

		# Run the R script, passing the current tag directory as the directory to which R will "setwd()"
		# echo '**Rscript mgean_plotter_reiko.R '
		# Rscript "$SCRIPT_DIR/megan_plotter.R" "${DIR}"



################################################################################
# PRELIMINARY ANALYSES
################################################################################
# Once you have a final CSV file of the number of occurences of each OTU in each sample, run some preliminary analyses in R
# TODO rename preliminary to OTU analyses; move analysis script to OTU analysis directory
OUTPUT_PDF="${ANALYSIS_DIR}"/analysis_results_"${START_TIME}".pdf

echo $(date +%H:%M) "passing args to R for preliminary analysis..."
echo " output pdf: " "${OUTPUT_PDF}"
echo " otu table: " "${OTU_table}" 
echo " sequencing metadata: " "${SEQUENCING_METADATA}" 
echo " libraray column name: " "${LIBRARY_COLUMN_NAME}" 
echo " tag column name:" "${TAG_COLUMN_NAME}" 
echo " column name sample name: " "${ColumnName_SampleName}" 
echo " columnName sample type: " "${ColumnName_SampleType}"
#Rscript "/home/mbonteam/dev/analyses_prelim.R" "${OUTPUT_PDF}" "${OTU_table}" "${SEQUENCING_METADATA}" "${LIBRARY_COLUMN_NAME}" "${TAG_COLUMN_NAME}" "${ColumnName_SampleName}" "${ColumnName_SampleType}"
echo Rscript "/home/mbonteam/MBARI/reiko/scripts/analyses_prelim_reiko.R " "${OUTPUT_PDF}" "${OTU_table}" "${SEQUENCING_METADATA}" "${LIBRARY_COLUMN_NAME}" "${TAG_COLUMN_NAME}" "${ColumnName_SampleName}" "${ColumnName_SampleType}"
Rscript "/home/mbonteam/MBARI/reiko/scripts/analyses_prelim_reiko.R" "${OUTPUT_PDF}" "${OTU_table}" "${SEQUENCING_METADATA}" "${LIBRARY_COLUMN_NAME}" "${TAG_COLUMN_NAME}" "${ColumnName_SampleName}" "${ColumnName_SampleType}"

echo $(date +%H:%M) "completed R for preliminary analysis..."

# EMPTY PDFs are 3829 bytes
minimumsize=4000
size_PDF=$(wc -c <"${OUTPUT_PDF}")
if [ "${size_PDF}" -lt "${minimumsize}" ]; then
    echo 'There was a problem generating the PDF.'
else
	REMOTE_PDF="${OUTPUT_PDF_DIR}"/analysis_results_"${START_TIME}".pdf
	cp "${OUTPUT_PDF}" "${REMOTE_PDF}"
	echo $(date +%H:%M) "analysis_results pdf written; R for preliminary analysis..."

fi

# ::::::::::::::::::: CREATE BIOM FILE ::::::::::::::::::::::::

# Create sample metadata file
echo ::: Create biom file metadata :::
# working files will end up in the source file directory, biom file metadata will be written to analysis all_lib directory
MY_SCRIPT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo 'Creating software version file.  /home/mbonteam/MBARI/reiko/scripts/find_versions.sh >' "${MY_SCRIPT}"'/versions.txt'
/home/mbonteam/MBARI/reiko/scripts/find_versions.sh > "${MY_SCRIPT}"/versions.txt

echo Creating parameter metadata file, output is banzai_sample_metadata.txt
echo python /home/mbonteam/MBARI/reiko/scripts/extract_params_metadata_v1.py "${MY_SCRIPT}" "${MY_SCRIPT}"/"${param_file}"
python /home/mbonteam/MBARI/reiko/scripts/extract_params_metadata_v1.py "${MY_SCRIPT}" "${MY_SCRIPT}"/"${param_file}"

echo Create sample metadata file.  python /home/mbonteam/MBARI/reiko/scripts/make_sample_metadata_USF.py "${MY_SCRIPT}" "${SEQUENCING_METADATA}" "${MY_SCRIPT}"/banzai_param_sample_metadata.txt "${MY_SCRIPT}"/static_sample_metadata.csv "${MY_SCRIPT}"/versions.txt "${ANALYSIS_DIR}"/all_lib/sample_metadata_biom.txt

python /home/mbonteam/MBARI/reiko/scripts/make_sample_metadata_USF.py "${MY_SCRIPT}" "${SEQUENCING_METADATA}" "${MY_SCRIPT}"/banzai_param_sample_metadata.txt "${MY_SCRIPT}"/static_sample_metadata.csv "${MY_SCRIPT}"/versions.txt "${ANALYSIS_DIR}"/all_lib/sample_metadata_biom.txt

		echo "Make observational metadata, concatenate taxa ranks. python /home/mbonteam/MBARI/reiko/scripts/Merge_taxa_ranks.py" "${ANALYSIS_DIR}"/all_lib
		python "/home/mbonteam/MBARI/reiko/scripts/Merge_taxa_ranks.py" "${ANALYSIS_DIR}"/all_lib
		sed -i -e 's/DUP/OTU/' -e 's/,/\t/' "${ANALYSIS_DIR}"/all_lib/phinch_obs_md.csv
		sed -i -e 's/;/,/g' "${ANALYSIS_DIR}"/all_lib/phinch_obs_md.csv
		echo "#OTU_ID	taxonomy" > "${ANALYSIS_DIR}"/all_lib/obs_md.txt
		cat "${ANALYSIS_DIR}"/all_lib/phinch_obs_md.csv >> "${ANALYSIS_DIR}"/all_lib/obs_md.txt
		echo $(date +%H:%M) "Create new otu tables with taxonomic ranks"
		echo python /home/mbonteam/MBARI/reiko/scripts/merge_otu_taxa.py  "${ANALYSIS_DIR}"/all_lib "${ANALYSIS_DIR}"/all_lib/obs_md.txt "${ANALYSIS_DIR}"/all_lib/OTUs_swarm/OTU_table.txt
		python /home/mbonteam/MBARI/reiko/scripts/merge_otu_taxa.py  "${ANALYSIS_DIR}"/all_lib "${ANALYSIS_DIR}"/all_lib/obs_md.txt "${ANALYSIS_DIR}"/all_lib/OTUs_swarm/OTU_table.txt
		sed -i -e 's/\x27/"/g' "${ANALYSIS_DIR}"/all_lib/OTU_table_taxa.txt
#		sed -i -e 's/\x27/"/g' "${ANALYSIS_DIR}"/all_lib/obs_md.txt

		
# Stuff for phinch.  Add prefixes for the taxonomic ranks.  Then merge by OTU id and concatenate the ranks
		echo $(date +%H:%M) "Create Phinch style taxonomic names, ie. p__ prefix for phylum"
		sed -i -e 's|,"|,"f__|' "${DIR}"/meganout_${COLLAPSE_RANK1}_mod.csv
		sed -i -e 's|,"|,"g__|' "${DIR}"/meganout_${COLLAPSE_RANK2}_mod.csv
		sed -i -e 's|,"|,"p__|' "${DIR}"/meganout_${COLLAPSE_RANK3}_mod.csv
		sed -i -e 's|,"|,"s__|' "${DIR}"/meganout_Species_mod.csv
		sed -i -e 's|,"|,"c__|' "${DIR}"/meganout_Class_mod.csv
		sed -i -e 's|,"|,"o__|' "${DIR}"/meganout_Order_mod.csv
		sed -i -e 's|,"|,"k__|' "${DIR}"/meganout_Kingdom_mod.csv
		echo "Make phinch observational metadata, python /home/mbonteam/MBARI/reiko/scripts/Merge_taxa_ranks.py" "${ANALYSIS_DIR}"/all_lib
		python "/home/mbonteam/MBARI/reiko/scripts/Merge_taxa_ranks.py" "${ANALYSIS_DIR}"/all_lib
		sed -i -e 's/DUP/OTU/' -e 's/,/\t/' "${ANALYSIS_DIR}"/all_lib/phinch_obs_md.csv
#		sed -i -e 's/\x27/"/g' "${ANALYSIS_DIR}"/all_lib/phinch_obs_md.csv
#		sed -i -e 's/;/,/g' "${ANALYSIS_DIR}"/all_lib/phinch_obs_md.csv
		echo "#OTU_ID	taxonomy" > "${ANALYSIS_DIR}"/all_lib/phinch_obs_md.txt
		cat "${ANALYSIS_DIR}"/all_lib/phinch_obs_md.csv >> "${ANALYSIS_DIR}"/all_lib/phinch_obs_md.txt
		echo "Create OTU table of taxanomic hits only"
		echo /home/mbonteam/MBARI/reiko/scripts/python make_OTU_table_hits.py "${DIR}"
		python /home/mbonteam/MBARI/reiko/scripts/make_OTU_table_hits.py "${DIR}"

echo $(date +%H:%M) "Create new otu tables with Phinch style ranks"
echo " Merge taxonomy to OTU table.  Does not include no hits, not assigned.  Output is OTU_table_taxa_phinch.txt with Phinch prefixes denoting taxonomic rank.  i.e. p__Proteobacteria"
python /home/mbonteam/MBARI/reiko/scripts/merge_otu_taxa2.py "${ANALYSIS_DIR}"/all_lib
# python adds quotes even though the string is not quoted.  To get it to not put quotes in is a pain.  This is totally stupid
sed -i 's/"//g' "${ANALYSIS_DIR}"/all_lib/OTU_table_taxa_phinch.txt
python /home/mbonteam/MBARI/reiko/scripts/merge_otu_taxa_all.py "${ANALYSIS_DIR}"/all_lib

echo "HDF biom "
echo biom convert -i "${ANALYSIS_DIR}"/all_lib/OTUs_swarm/OTU_table.txt -o "${ANALYSIS_DIR}"/all_lib/"${BIOM_FILE_NAME}"_hdf.biom --table-type='"OTU table"' --to-hdf5
biom convert -i "${ANALYSIS_DIR}"/all_lib/OTUs_swarm/OTU_table.txt -o "${ANALYSIS_DIR}"/all_lib/"${BIOM_FILE_NAME}"_hdf.biom --table-type="OTU table" --to-hdf5

echo biom add-metadata -i "${ANALYSIS_DIR}"/all_lib/"${BIOM_FILE_NAME}"_hdf.biom -o "${ANALYSIS_DIR}"/all_lib/"${BIOM_FILE_NAME}"_hdf_obs.biom --observation-metadata-fp "${ANALYSIS_DIR}"/all_lib/obs_md.txt --int-fields size --sc-separated taxonomy
biom add-metadata -i "${ANALYSIS_DIR}"/all_lib/"${BIOM_FILE_NAME}"_hdf.biom -o "${ANALYSIS_DIR}"/all_lib/"${BIOM_FILE_NAME}"_hdf_obs.biom --observation-metadata-fp "${ANALYSIS_DIR}"/all_lib/obs_md.txt --int-fields size --sc-separated taxonomy

echo biom add-metadata -i "${ANALYSIS_DIR}"/all_lib/"${BIOM_FILE_NAME}"_hdf_obs.biom -o "${ANALYSIS_DIR}"/all_lib/"${BIOM_FILE_NAME}"_hdf_obs_md.biom --sample-metadata-fp  "${ANALYSIS_DIR}"/all_lib/sample_metadata_biom.txt
biom add-metadata -i "${ANALYSIS_DIR}"/all_lib/"${BIOM_FILE_NAME}"_hdf_obs.biom -o "${ANALYSIS_DIR}"/all_lib/"${BIOM_FILE_NAME}"_hdf_obs_md.biom --sample-metadata-fp  "${ANALYSIS_DIR}"/all_lib/sample_metadata_biom.txt


echo "JSON biom "
echo biom convert -i "${ANALYSIS_DIR}"/all_lib/OTU_table_hits.txt -o "${ANALYSIS_DIR}"/all_lib/"${BIOM_FILE_NAME}"_json.biom --table-type="OTU table" --to-json
biom convert -i "${ANALYSIS_DIR}"/all_lib/OTU_table_hits.txt -o "${ANALYSIS_DIR}"/all_lib/"${BIOM_FILE_NAME}"_json.biom --table-type="OTU table" --to-json 

echo biom add-metadata -i "${ANALYSIS_DIR}"/all_lib/"${BIOM_FILE_NAME}"_json.biom -o "${ANALYSIS_DIR}"/all_lib/"${BIOM_FILE_NAME}"_json_obs.biom --observation-metadata-fp "${ANALYSIS_DIR}"/all_lib/obs_md.txt  --output-as-json
biom add-metadata -i "${ANALYSIS_DIR}"/all_lib/"${BIOM_FILE_NAME}"_json.biom -o "${ANALYSIS_DIR}"/all_lib/"${BIOM_FILE_NAME}"_json_obs.biom --observation-metadata-fp "${ANALYSIS_DIR}"/all_lib/obs_md.txt  --output-as-json

# PYTHON messes up the quotes so we have to fix it. 
# replace single quotes with double quotes which is what phyloseq wants
sed -i -e 's/\x27/"/g' "${ANALYSIS_DIR}"/all_lib/"${BIOM_FILE_NAME}"_json_obs.biom
# biom adds double quotes around the square brackets
# replace "[" with ["
sed -i 's/\"\[\"/\[\"/g' "${ANALYSIS_DIR}"/all_lib/"${BIOM_FILE_NAME}"_json_obs.biom
# replace "]" with "]
sed -i 's/\"\]\"/\"\]/g' "${ANALYSIS_DIR}"/all_lib/"${BIOM_FILE_NAME}"_json_obs.biom

echo biom add-metadata -i "${ANALYSIS_DIR}"/all_lib/"${BIOM_FILE_NAME}"_json_obs.biom -o "${ANALYSIS_DIR}"/all_lib/"${BIOM_FILE_NAME}"_json_obs_md.biom --sample-metadata-fp "${ANALYSIS_DIR}"/all_lib/sample_metadata_biom.txt --output-as-json
biom add-metadata -i "${ANALYSIS_DIR}"/all_lib/"${BIOM_FILE_NAME}"_json_obs.biom -o "${ANALYSIS_DIR}"/all_lib/"${BIOM_FILE_NAME}"_json_obs_md.biom --sample-metadata-fp "${ANALYSIS_DIR}"/all_lib/sample_metadata_biom.txt --output-as-json

FINISH_TIME=$(date +%Y%m%d_%H%M)

if [ "$NOTIFY_EMAIL" = "YES" ]; then
	echo 'Pipeline finished! Started at' $START_TIME 'and finished at' $FINISH_TIME | mail -s "banzai is finished" "${EMAIL_ADDRESS}"
else
	echo 'Pipeline finished! Started at' $START_TIME 'and finished at' $FINISH_TIME
fi
echo 'Data are in ' "${ANALYSIS_DIR}"
# remove some of the repetitive lines, read percents from kmers, fastq etc.  makes it difficult to read logfile.
# grep -v flag means output everything except pattern, -f means pattern is in text file, i.e. grep_patterns.txt
mv "${ANALYSIS_DIR}"/logfile.txt "${ANALYSIS_DIR}"/logfile_orig.txt 
grep -v -f /home/mbonteam/MBARI/reiko/scripts/grep_patterns.txt "${ANALYSIS_DIR}"/logfile_orig.txt > "${ANALYSIS_DIR}"/logfile.txt
# Quick scan of logfile2.txt for errors, error line and 3 lines before, -B 3
grep -n -B 3 "error" "${ANALYSIS_DIR}"/logfile.txt >"${ANALYSIS_DIR}"/errors.txt
# echo -e '\n'$(date +%H:%M)'\tAll finished! Why not treat yourself to a...\n'
# echo
# echo -e '\t~~~ MAI TAI ~~~'
# echo -e '\t2 oz\taged rum'
# echo -e '\t0.75 oz\tfresh squeezed lime juice'
# echo -e '\t0.5 oz\torgeat'
# echo -e '\t0.5 oz\ttriple sec'
# echo -e '\t0.25 oz\tsimple syrup'
# echo -e '\tShake, strain, and enjoy!' '\xf0\x9f\x8d\xb9\x0a''\n'
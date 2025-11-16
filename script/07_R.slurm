#!/bin/bash
#SBATCH --job-name=Analyse
#SBATCH --output=log/slurmjob-%A-%a
#SBATCH --time=00:30:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --array=0
#SBATCH --partition=normal

###############################################
# R Analysis – Statistical analysis and visualization
###############################################

set -euo pipefail
IFS=$'\n\t'

echo "===== Starting R merge Data ====="

echo "[INFO] Running R analysis script: all_counts.R" >&2
Rscript all_counts.R

echo "===== Starting R analysis job ====="

echo "[INFO] Running R analysis script: Analyse.R" >&2

# Before launching Analyse.R, verify that the merged counts file exists
# and appears to have been produced (or at least updated) after running all_counts.R.
COUNTS_FILE="$PWD/all_featureCounts_counts.txt"
ALLCOUNTS_SCRIPT="$PWD/all_counts.R"

if [ ! -f "$COUNTS_FILE" ]; then
	echo "[ERROR] Counts file not found: $COUNTS_FILE" >&2
	exit 1
fi

if [ ! -s "$COUNTS_FILE" ]; then
	echo "[ERROR] Counts file is empty: $COUNTS_FILE" >&2
	exit 1
fi

Rscript Analyse.R

echo "===== R analysis job completed successfully ====="
echo "Stopped at: $(date)" >&2
#!/bin/bash
#SBATCH --job-name=Analyse
#SBATCH --output=log/07_R-%A-%a.out
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

# Load conda environment
module purge
source /home/users/shared/conda_envs/miniconda3/bin/activate
conda activate rnaseq

set -euo pipefail
IFS=$'\n\t'

# Input directory containing deduplicated BAM files
COUNTS_DIR="$HOME/results/RNAseq/counts"

# Scratch directory for temporary computation
SCRATCHDIR="/storage/scratch/$USER/R_analyse"
mkdir -p -m 700 "$SCRATCHDIR"

# Output directory for final results
OUTPUT="$HOME/results/RNAseq/R"
mkdir -p "$OUTPUT"

# Change to scratch directory to ensure all operations happen there
cd "$SCRATCHDIR"

echo "===== Starting R merge Data ====="

echo "[INFO] Running R analysis script: all_counts.R" >&2
Rscript all_counts.R "$COUNTS_DIR" >&2

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

Rscript Analyse.R "$SCRATCHDIR" >&2

###########################################
# Move results to final output
###########################################
mv -r "$SCRATCHDIR"/* "$OUTPUT"/

# Clean scratch directory
rm -rf "$SCRATCHDIR"

conda deactivate

echo "===== R analysis job completed successfully ====="
echo "Stopped at: $(date)" >&2

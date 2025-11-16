#!/bin/bash
#SBATCH --job-name=trim
#SBATCH --output=log/slurmjob-%A-%a
#SBATCH --time=00:40:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=6G
#SBATCH --array=0-47
#SBATCH --partition=normal

#############################################################
# Trimmomatic – Read trimming and quality filtering (PE mode)
#############################################################

set -euo pipefail
IFS=$'\n\t'

echo "===== Starting Trimming job ====="

# Load required modules
module purge
module load gcc/8.1.0 java/oracle-1.7.0_79 trimmomatic/0.38

###########################################
# Input and output directories
###########################################
DATA_DIR="/home/users/shared/data/stategra/RNAseq/raw/"
PRIMER_DIR="/home/users/shared/data/stategra"
OUTPUT="$HOME/results/RNAseq/raw/trim"

mkdir -p "$OUTPUT"

###########################################
# Scratch directory
###########################################
SCRATCHDIR="/storage/scratch/$USER/$SLURM_JOB_ID"
mkdir -p -m 700 "$SCRATCHDIR"

# Change to scratch directory to ensure all operations happen there
cd "$SCRATCHDIR"

echo "[INFO] Scratch directory: $SCRATCHDIR" >&2
echo "[INFO] Output directory:  $OUTPUT" >&2

###########################################
# Retrieve FASTQ file pairs
###########################################
echo "[INFO] Detecting FASTQ pairs..." >&2

tab_fwd=($(ls "$DATA_DIR"/*_1.fastq.gz | sort))
tab_rev=($(ls "$DATA_DIR"/*_2.fastq.gz | sort))

echo "[INFO] Forward reads:" >&2
printf '  %s\n' "${tab_fwd[@]}" >&2

echo "[INFO] Reverse reads:" >&2
printf '  %s\n' "${tab_rev[@]}" >&2

# Base name of the current sample
filename=$(basename "${tab_fwd[$SLURM_ARRAY_TASK_ID]}" _1.fastq.gz)

###########################################
# Run Trimmomatic
###########################################
echo "[INFO] Running Trimmomatic on sample: $filename" >&2

/usr/bin/time -v \
java -jar /opt/apps/trimmomatic-0.38/trimmomatic-0.38.jar PE \
    -threads ${SLURM_CPUS_PER_TASK} \
    -trimlog "$OUTPUT/${filename}_trim.log" \
    -summary "$OUTPUT/${filename}_summary.txt" \
    "${tab_fwd[$SLURM_ARRAY_TASK_ID]}" "${tab_rev[$SLURM_ARRAY_TASK_ID]}" \
    "${filename}_1_trim_paired.fastq.gz" \
    "${filename}_1_trim_unpaired.fastq.gz" \
    "${filename}_2_trim_paired.fastq.gz" \
    "${filename}_2_trim_unpaired.fastq.gz" \
    ILLUMINACLIP:"$PRIMER_DIR"/NexteraPE-PE.fa:2:30:10:2:keepBothReads \
    LEADING:3 \
    TRAILING:3 \
    SLIDINGWINDOW:4:15

###########################################
# Move final trimmed files to output
###########################################
mv "$SCRATCHDIR"/* "$OUTPUT"/

# Clean scratch directory
rm -rf "$SCRATCHDIR"

echo "===== Trimming job completed successfully ====="
echo "Stopped at: $(date)" >&2

unset IFS

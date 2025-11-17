#!/bin/bash
#SBATCH --job-name=qc_init
#SBATCH --output=log/01_fastqc-%A-%a.out
#SBATCH --time=00:30:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=2G
#SBATCH --array=0-47
#SBATCH --partition=normal

###############################################
# FastQC – Initial quality control on raw reads
###############################################

set -euo pipefail
IFS=$'\n\t'

echo "===== Starting FastQC job (initial QC) ====="

# Load required modules
module load java/oracle-1.7.0_79 fastqc/0.11.7

# Input directory
RAW_DIR="/home/users/shared/data/stategra/RNAseq/raw"

echo "[INFO] Listing FASTQ files in: $RAW_DIR" >&2
fastq_files=($(ls "$RAW_DIR"/*.fastq.gz))

echo "[INFO] Files detected:" >&2
printf '  %s\n' "${fastq_files[@]}" >&2

# Select the file corresponding to the array ID
filename=$(basename "${fastq_files[$SLURM_ARRAY_TASK_ID]}" .fastq.gz)

# Scratch directory for temporary computation
SCRATCHDIR="/storage/scratch/$USER/${filename}/fastqc-init"
mkdir -p -m 700 "$SCRATCHDIR"

# Output directory for final FastQC results
OUTPUT="$HOME/results/RNAseq/raw/qc-init/$filename"
mkdir -p "$OUTPUT"

# Change to scratch directory to ensure all operations happen there
cd "$SCRATCHDIR"

# Ensure output is clean
if [ -d "$OUTPUT/fastqc-init" ]; then
    if [ "$(ls -A "$OUTPUT"/fastqc-init)" ]; then
        echo "[WARN] $OUTPUT/fastqc-init is not empty. Cleaning it." >&2
        rm -rf "$OUTPUT/fastqc-init"
    else
        echo "[INFO] $OUTPUT/fastqc-init exists but is empty." >&2
    fi
fi

echo "[INFO] Running FastQC on: ${fastq_files[$SLURM_ARRAY_TASK_ID]}" >&2
fastqc \
    "${fastq_files[$SLURM_ARRAY_TASK_ID]}" \
    --dir "$SCRATCHDIR" \
    -o "$SCRATCHDIR"

# Move results to final output
mv "$SCRATCHDIR"/* "$OUTPUT"/

# Clean scratch directory
rm -rf "$SCRATCHDIR"

echo "===== FastQC job completed successfully ====="
echo "Stopped at: $(date)" >&2

#!/bin/bash
#SBATCH --job-name=qc_post
#SBATCH --output=log/03_fastqc-%A-%a.out
#SBATCH --time=00:30:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=2G
#SBATCH --array=0-95
#SBATCH --partition=normal

###############################################
# FastQC – Post-trimming quality control
###############################################

set -euo pipefail
IFS=$'\n\t'

echo "===== Starting FastQC job (post-trimming QC) ====="

# Load required modules
module purge
module load java/oracle-1.7.0_79 fastqc/0.11.7

# Input directory containing trimmed FASTQ files
TRIM_DIR="$HOME/results/RNAseq/raw/trim"

echo "[INFO] Listing trimmed FASTQ files in: $TRIM_DIR" >&2
fastq_files=($(ls "$TRIM_DIR"/*/*trim*.fastq.gz))

echo "[INFO] Files detected:" >&2
printf '  %s\n' "${fastq_files[@]}" >&2

# Select the file corresponding to the array ID
current_file="${fastq_files[$SLURM_ARRAY_TASK_ID]}"

# Extract filename and determine read type (paired/unpaired)
if [[ "$current_file" =~ "trim_paired" ]]; then
    filename=$(basename "$current_file" _trim_paired.fastq.gz)
    echo "[INFO] Paired-end reads detected for: $filename" >&2
elif [[ "$current_file" =~ "trim_unpaired" ]]; then
    filename=$(basename "$current_file" _trim_unpaired.fastq.gz)
    echo "[INFO] Single-end reads detected for: $filename" >&2
else
    echo "[ERROR] No paired or unpaired expression found in filename: $current_file" >&2
    exit 1
fi

# Scratch directory for temporary computation
SCRATCHDIR="/storage/scratch/$USER/${filename}/fastqc-post"
mkdir -p -m 700 "$SCRATCHDIR"

# Output directory for final FastQC results
OUTPUT="$HOME/results/RNAseq/raw/qc-post/$filename"
mkdir -p "$OUTPUT"

# Change to scratch directory to ensure all operations happen there
cd "$SCRATCHDIR"

echo "[INFO] Running FastQC on: $current_file" >&2
fastqc \
    "$current_file" \
    --dir "$SCRATCHDIR" \
    -o "$SCRATCHDIR"

# Move results to final output
mv "$SCRATCHDIR"/* "$OUTPUT"/

# Clean scratch directory
rm -rf "$SCRATCHDIR"

echo "===== FastQC job completed successfully ====="
echo "Stopped at: $(date)" >&2


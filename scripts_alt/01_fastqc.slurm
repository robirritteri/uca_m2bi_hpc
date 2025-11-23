#!/bin/bash
#SBATCH --job-name=qc_raw
#SBATCH --output=log/slurmjob-%A-%a
#SBATCH --time=00:30:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=2G
#SBATCH --array=0-47
#SBATCH --partition=normal


set -euo pipefail
IFS=$'\n\t'

module load conda
conda activate rnaseq

echo "===== Starting FastQC job (RAW) ====="

# ==========================
# Path
# ==========================
RAW_DIR="/home/users/shared/data/stategra/RNAseq/raw"

# List raw FASTQ files
fastq_files=($(ls "$RAW_DIR"/*.fastq.gz 2>/dev/null))
if [ ${#fastq_files[@]} -eq 0 ]; then
  echo "[ERROR] No .fastq.gz found in $RAW_DIR" >&2
  exit 1
fi

# Limit the array size to the actual number of files
if [ ${SLURM_ARRAY_TASK_ID} -ge ${#fastq_files[@]} ]; then
  echo "[INFO] Task ID ${SLURM_ARRAY_TASK_ID} >= number of files, nothing to do."
  exit 0
fi

filename=$(basename "${fastq_files[$SLURM_ARRAY_TASK_ID]}" .fastq.gz)

# Scratch + final output (modified)
SCRATCHDIR="/storage/scratch/$USER/${filename}/fastqc-init"
OUTPUT_BASE="$HOME/results/RNAseq/raw/qc-init"
OUTPUT="$OUTPUT_BASE/$filename"

mkdir -p -m 700 "$SCRATCHDIR" "$OUTPUT_BASE" "$OUTPUT"

echo "[INFO] FastQC on: ${fastq_files[$SLURM_ARRAY_TASK_ID]}"
fastqc \
  "${fastq_files[$SLURM_ARRAY_TASK_ID]}" \
  --dir "$SCRATCHDIR" \
  -o "$SCRATCHDIR"

# Move to final output directory
mv "$SCRATCHDIR"/* "$OUTPUT"/
rm -rf "$SCRATCHDIR"

# Run MultiQC only once (for example on task 0)
if [ "${SLURM_ARRAY_TASK_ID}" -eq 0 ]; then
  echo "[INFO] Running MultiQC (RAW)"
  multiqc -o "$OUTPUT_BASE" "$OUTPUT_BASE"
fi

echo "===== FastQC RAW done ====="

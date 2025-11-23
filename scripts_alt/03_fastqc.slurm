#!/bin/bash
#SBATCH --job-name=qc_posttrim
#SBATCH --output=log/slurmjob-%A-%a
#SBATCH --time=00:30:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=2G
#SBATCH --array=0-47
#SBATCH --partition=normal

###############################################
# Quality control - Post-trimming
###############################################

set -euo pipefail
IFS=$'\n\t'

module load conda
conda activate rnaseq

# ==========================
# Path
# ==========================
TRIM_DIR="$HOME/results/RNAseq/trimmed/paired"
QC_TRIM_DIR="$HOME/results/RNAseq/trimmed/qc-post"

mkdir -p "$QC_TRIM_DIR"

# List all trimmed FASTQ files
trimmed=($(ls "$TRIM_DIR"/*.fastq.gz 2>/dev/null))
if [ ${#trimmed[@]} -eq 0 ]; then
  echo "[ERROR] No trimmed fastq.gz found in $TRIM_DIR" >&2
  exit 1
fi

# Array boundary
if [ ${SLURM_ARRAY_TASK_ID} -ge ${#trimmed[@]} ]; then
  echo "[INFO] Task ID ${SLURM_ARRAY_TASK_ID} >= number of files, nothing to do."
  exit 0
fi

fq="${trimmed[$SLURM_ARRAY_TASK_ID]}"
filename=$(basename "$fq" .fastq.gz)

SCRATCHDIR="/storage/scratch/$USER/${filename}/fastqc-post"
OUT_SAMPLE="$QC_TRIM_DIR/$filename"

mkdir -p -m 700 "$SCRATCHDIR" "$OUT_SAMPLE"

echo "[INFO] FastQC (post-trim) on: $fq"
fastqc \
  "$fq" \
  --dir "$SCRATCHDIR" \
  -o "$SCRATCHDIR"

mv "$SCRATCHDIR"/* "$OUT_SAMPLE"/
rm -rf "$SCRATCHDIR"

# MultiQC only once
if [ "${SLURM_ARRAY_TASK_ID}" -eq 0 ]; then
  echo "[INFO] Running MultiQC (post-trim)"
  multiqc -o "$QC_TRIM_DIR" "$QC_TRIM_DIR"
fi

echo "===== FastQC post-trim done ====="

#!/bin/bash
#SBATCH --job-name=trim_pe
#SBATCH --output=log/slurmjob-%A-%a
#SBATCH --time=01:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=4G
#SBATCH --array=0-999
#SBATCH --partition=normal

###############################################
# Trimming - Cutadapt
###############################################

set -euo pipefail
IFS=$'\n\t'


# ==========================
# Path
# ==========================
RAW_DIR="/home/users/shared/data/stategra/RNAseq"
TRIM_DIR="/home/users/student14/uca_m2bi_hpc/results/RNAseq/trimmed/paired"
QC_TRIM_DIR="$HOME/results/RNAseq/trimmed/qc-post"   # MultiQC post-trim (optional here)

mkdir -p "$TRIM_DIR" "$QC_TRIM_DIR"

# Parameters
QUAL=20
MINLEN=30

# ==== REPLACED BY YOUR ADAPTERS ====
ADAPTER_R1="AGATGTGTATAAGAGACAG"
ADAPTER_R2="AGATGTGTATAAGAGACAG"
# ===================================

# Build the list of R1
r1_files=($(ls "$RAW_DIR"/*_1.fastq.gz 2>/dev/null))
if [ ${#r1_files[@]} -eq 0 ]; then
  echo "[ERROR] No *_1.fastq.gz found in $RAW_DIR" >&2
  exit 1
fi

# Array limit check
if [ ${SLURM_ARRAY_TASK_ID} -ge ${#r1_files[@]} ]; then
  echo "[INFO] Task ID ${SLURM_ARRAY_TASK_ID} >= number of files, nothing to do."
  exit 0
fi

fq1="${r1_files[$SLURM_ARRAY_TASK_ID]}"
base="$(basename "$fq1" _1.fastq.gz)"
fq2="$RAW_DIR/${base}_2.fastq.gz"

if [ ! -s "$fq2" ]; then
  echo "[ERROR] Pair not found for $fq1 -> $fq2" >&2
  exit 1
fi

out_fq1="$TRIM_DIR/${base}_R1.trim.fastq.gz"
out_fq2="$TRIM_DIR/${base}_R2.trim.fastq.gz"

echo "=== [Trimming] $base ==="
cutadapt \
  -q $QUAL,$QUAL \
  -m $MINLEN \
  -a "$ADAPTER_R1" \
  -A "$ADAPTER_R2" \
  -o "$out_fq1" \
  -p "$out_fq2" \
  "$fq1" "$fq2"

# MultiQC only once (optional here, otherwise leave it for post-trim)
if [ "${SLURM_ARRAY_TASK_ID}" -eq 0 ]; then
  multiqc -o "$QC_TRIM_DIR" "$TRIM_DIR"
fi

echo "=== Done: $base ==="

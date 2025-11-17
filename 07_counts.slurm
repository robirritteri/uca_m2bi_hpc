#!/bin/bash
#SBATCH --job-name=count
#SBATCH --output=log/slurmjob-%A-%a
#SBATCH --time=00:30:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --array=0-47
#SBATCH --partition=normal

###############################################
# SAMtools & featureCounts – Read filtering and counting
###############################################

set -euo pipefail
IFS=$'\n\t'

echo "===== Starting read filtering and counting job ====="

# Load conda environment
module purge
source /home/users/shared/conda_envs/miniconda3/bin/activate
conda activate rnaseq

# Reference genome annotation
GTF="/home/users/shared/databanks/Mus_musculus_GRCm39/flat/genomic.gtf"

# Input directory containing deduplicated BAM files
PICARD_DIR="/home/users/student14/uca_m2bi_hpc/results/RNAseq/picard/bamTraite/paired"

echo "[INFO] Listing deduplicated BAM files in: $PICARD_DIR" >&2
bam_files=("$PICARD_DIR"/dedup_*.bam)

if [ ${#bam_files[@]} -eq 0 ]; then
  echo "[ERROR] No dedup_*.bam files found in $PICARD_DIR" >&2
  exit 1
fi

# Bound check for array
if [ ${SLURM_ARRAY_TASK_ID} -ge ${#bam_files[@]} ]; then
  echo "[INFO] Task ID ${SLURM_ARRAY_TASK_ID} >= number of BAM files, nothing to do." >&2
  exit 0
fi

echo "[INFO] BAM files detected:" >&2
printf '  %s\n' "${bam_files[@]}" >&2

# Extract sample filename (without .bam)
filename=$(basename "${bam_files[$SLURM_ARRAY_TASK_ID]}" .bam)

# Scratch directory for temporary computation
SCRATCHDIR="/storage/scratch/$USER/${filename}/count"
mkdir -p -m 700 "$SCRATCHDIR"

# Output directory for final results
OUTPUT="/home/users/student14/uca_m2bi_hpc/results/RNAseq/samtools/$filename"
mkdir -p "$OUTPUT"

# Change to scratch directory to ensure all operations happen there
cd "$SCRATCHDIR"

###########################################
# Step 1: Filter reads by quality
###########################################
echo "[INFO] Filtering reads by quality (proper pairs, mapped)..." >&2
samtools view -b -f 1 -F 12 \
    "${bam_files[$SLURM_ARRAY_TASK_ID]}" > "${filename}_RO_MP_GQ.bam"

###########################################
# Step 2: Sort reads by name
###########################################
echo "[INFO] Sorting reads by name..." >&2
samtools sort -n "${filename}_RO_MP_GQ.bam" -o "${filename}_ready.bam"

###########################################
# Step 3: Count reads per feature
###########################################
echo "[INFO] Counting reads per feature using featureCounts..." >&2
featureCounts -p -s 2 -a "$GTF" \
    -o "${filename}.featureCounts.txt" \
    "${filename}_ready.bam"

###########################################
# Move results to final output
###########################################
mv "$SCRATCHDIR"/* "$OUTPUT"/

# Clean scratch directory
rm -rf "$SCRATCHDIR"

conda deactivate

echo "===== Read filtering and counting job completed successfully ====="
echo "Stopped at: $(date)" >&2

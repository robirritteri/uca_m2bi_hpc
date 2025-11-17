#!/bin/bash
#SBATCH --job-name=picard
#SBATCH --output=log/05_picard-%A-%a.out
#SBATCH --time=00:30:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --array=0-47
#SBATCH --partition=normal

###############################################
# Picard – SAM/BAM processing and QC metrics
###############################################

set -euo pipefail
IFS=$'\n\t'

echo "===== Starting Picard job ====="

# Load required modules
module purge
module load java/oracle-1.11.0_11 picard/2.18.25
source /home/users/shared/conda_envs/miniconda3/bin/activate
conda activate rnaseq

# Picard JAR file location
PICARD="/opt/apps/picard-2.18.25/picard.jar"

# Input directory containing aligned BAM files
ALIGN_DIR="$HOME/results/RNAseq/raw/align"

echo "[INFO] Listing aligned BAM files in: $ALIGN_DIR" >&2
bam_files=($(ls "$ALIGN_DIR"/*/*aligned.sorted.bam))

echo "[INFO] BAM files detected:" >&2
printf '  %s\n' "${bam_files[@]}" >&2

# Extract sample filename
filename=$(basename "${bam_files[$SLURM_ARRAY_TASK_ID]}" _aligned.sorted.bam)

# Scratch directory for temporary computation
SCRATCHDIR="/storage/scratch/$USER/${filename}/picard"
mkdir -p -m 700 "$SCRATCHDIR"

# Output directory for final results
OUTPUT="$HOME/results/RNAseq/picard/$filename"
mkdir -p "$OUTPUT"

# Change to scratch directory to ensure all operations happen there
cd "$SCRATCHDIR"

###########################################
# Step 1: Sort reads by coordinate
###########################################
echo "[INFO] Sorting reads using Picard SortSam..." >&2
java -jar "$PICARD" SortSam \
    INPUT="${bam_files[$SLURM_ARRAY_TASK_ID]}" \
    OUTPUT="${filename}_RO.bam" \
    SORT_ORDER=coordinate \
    VALIDATION_STRINGENCY=LENIENT

# Index the sorted BAM file
samtools index "${filename}_RO.bam"

###########################################
# Step 2: Mark duplicate reads
###########################################
echo "[INFO] Marking duplicates using Picard MarkDuplicates..." >&2
java -jar "$PICARD" MarkDuplicates \
    INPUT="${filename}_RO.bam" \
    OUTPUT="${filename}_RO_MP.bam" \
    CREATE_INDEX=false \
    VALIDATION_STRINGENCY=LENIENT \
    ASSUME_SORTED=false \
    REMOVE_DUPLICATES=false \
    METRICS_FILE="${filename}_MP.metrics"

# Index the deduplicated BAM file
samtools index "${filename}_RO_MP.bam"

###########################################
# Move results to final output
###########################################
mv "$SCRATCHDIR"/* "$OUTPUT"/

# Clean scratch directory
rm -rf "$SCRATCHDIR"

conda deactivate

echo "===== Picard job completed successfully ====="
echo "Stopped at: $(date)" >&2


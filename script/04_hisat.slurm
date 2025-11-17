#!/bin/bash
#SBATCH --job-name=hisat2
#SBATCH --output=log/04_hisat-%A-%a.out
#SBATCH --time=04:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=5G
#SBATCH --array=0-23
#SBATCH --partition=normal

###############################################
# HISAT2 – RNA-seq read alignment
###############################################

set -euo pipefail
IFS=$'\n\t'

echo "===== Starting HISAT2 alignment job ====="

# Load conda environment
module purge
source /home/users/shared/conda_envs/miniconda3/bin/activate
conda activate rnaseq

# Reference genome index and annotation
INDEX="/home/users/shared/databanks/Mus_musculus_GRCm39/hisat2/all"
GTF="/home/users/shared/databanks/Mus_musculus_GRCm39/flat/genomic.gtf"

# Input directory containing trimmed FASTQ files
TRIM_DIR="$HOME/results/RNAseq/raw/trim"

echo "[INFO] Listing trimmed FASTQ files in: $TRIM_DIR" >&2
# Forward reads
forward_reads=($(ls "$TRIM_DIR"/*1_trim_paired.fastq.gz))
echo "[INFO] Forward reads detected:" >&2
printf '  %s\n' "${forward_reads[@]}" >&2

# Reverse reads
reverse_reads=($(ls "$TRIM_DIR"/*2_trim_paired.fastq.gz))
echo "[INFO] Reverse reads detected:" >&2
printf '  %s\n' "${reverse_reads[@]}" >&2

# Extract sample filename
filename=$(basename "${forward_reads[$SLURM_ARRAY_TASK_ID]}" _1_trim_paired.fastq.gz)

# Scratch directory for temporary computation
SCRATCHDIR="/storage/scratch/$USER/${filename}/align"
mkdir -p -m 700 "$SCRATCHDIR"

# Output directory for final alignment results
OUTPUT="$HOME/results/RNAseq/align/$filename"
mkdir -p "$OUTPUT"

# Change to scratch directory to ensure all operations happen there
cd "$SCRATCHDIR"

echo "[INFO] Running HISAT2 alignment on sample: $filename" >&2
# Align reads with HISAT2
hisat2 -p "$SLURM_CPUS_PER_TASK" \
    --rna-strandness RF \
    --dta \
    -x "$INDEX/Mus_musculus" \
    -1 "${forward_reads[$SLURM_ARRAY_TASK_ID]}" \
    -2 "${reverse_reads[$SLURM_ARRAY_TASK_ID]}" \
    -S "${filename}_aligned.sam"

# Convert SAM to BAM and sort
echo "[INFO] Converting SAM to BAM and sorting..." >&2
samtools view -@ "$SLURM_CPUS_PER_TASK" -bS "${filename}_aligned.sam" \
    | samtools sort -@ "$SLURM_CPUS_PER_TASK" -o "${filename}_aligned.sorted.bam"

# Index BAM file
echo "[INFO] Indexing BAM file..." >&2
samtools index "${filename}_aligned.sorted.bam"

# Move results to final output
mv "$SCRATCHDIR"/* "$OUTPUT"/

# Clean scratch directory
rm -rf "$SCRATCHDIR"

conda deactivate

echo "===== HISAT2 alignment job completed successfully ====="
echo "Stopped at: $(date)" >&2


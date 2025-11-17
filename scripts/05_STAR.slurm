#!/bin/bash
#SBATCH --job-name=star_align_paired
#SBATCH --output=log/slurmjob-%A-%a
#SBATCH --time=02:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=20G
#SBATCH --array=0-23
#SBATCH --partition=normal

set -euo pipefail
IFS=$'\n\t'

###############################################
# STAR – Alignment
###############################################

echo "===== Starting STAR alignment job ====="

# ==========================
# Path
# ==========================
TRIM_DIR="/home/users/student14/uca_m2bi_hpc/results/RNAseq/trimmed/paired"
OUT_DIR="/home/users/student14/uca_m2bi_hpc/results/RNAseq/alignment/paired"
GENOME_DIR="/home/users/student14/uca_m2bi_hpc/index_star"

mkdir -p "$OUT_DIR"

paired1=( "$TRIM_DIR"/*R1*.fastq.gz )
paired2=( "${paired1[@]/R1/R2}" )

fq1="${paired1[$SLURM_ARRAY_TASK_ID]}"
fq2="${paired2[$SLURM_ARRAY_TASK_ID]}"
sample_name=$(basename "$fq1" | sed 's/_R1.*.fastq.gz//')

SCRATCHDIR="/storage/scratch/$USER/${sample_name}/star"
mkdir -p -m 700 "$SCRATCHDIR"

OUTPUT="$OUT_DIR/$sample_name"
mkdir -p "$OUTPUT"

cd "$SCRATCHDIR"

STAR \
    --runThreadN "$SLURM_CPUS_PER_TASK" \
    --runMode alignReads \
    --genomeDir "$GENOME_DIR" \
    --readFilesIn "$fq1" "$fq2" \
    --readFilesCommand zcat \
    --outSAMtype BAM SortedByCoordinate \
    --outFileNamePrefix "$SCRATCHDIR/${sample_name}_" \
    --sjdbOverhang 99 \
    --quantMode TranscriptomeSAM GeneCounts

mv "$SCRATCHDIR"/* "$OUTPUT"/
rm -rf "$SCRATCHDIR"

echo "===== STAR alignment done for $sample_name ====="

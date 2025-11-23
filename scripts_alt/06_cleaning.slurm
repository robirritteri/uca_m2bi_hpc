#!/bin/bash
#SBATCH --job-name=picard_clean
#SBATCH --output=log/slurmjob-%A-%a
#SBATCH --time=00:30:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --array=0-23
#SBATCH --partition=normal

###############################################
# Picard – SAM/BAM processing and QC metrics
###############################################

set -euo pipefail
IFS=$'\n\t'

module load conda
conda activate rnaseq

echo "===== Starting Picard job (batch post-processing) ====="

# ==========================
# Path
# ==========================
BAMs=( "$HOME/results/RNAseq/alignment/paired"/*/*.bam )
pairedBAMs=$(echo "${BAMs[@]}")

folder="$HOME/results/RNAseq/picard/bamTraite"
sub_folders=("paired")

mkdir -p "$folder/paired"

for bam in $pairedBAMs; do
    fixmate="fixmate_$(basename "$bam")"
    sorted="sorted_$(basename "$bam")"
    dedup="$folder/paired/dedup_$(basename "$bam")"
    metrics="$folder/paired/metrics_$(basename "${bam%.bam}").txt"

    samtools fixmate -m "$bam" "$fixmate"
    samtools view -b -q 28 "$fixmate" | samtools sort -@ 4 -o "$sorted"
    picard MarkDuplicates \
        I="$sorted" \
        O="$dedup" \
        M="$metrics" \
        REMOVE_DUPLICATES=true \
        VALIDATION_STRINGENCY=LENIENT
    rm "$sorted" "$fixmate"
done

echo "===== Picard job completed successfully ====="
echo "Stopped at: $(date)" >&2

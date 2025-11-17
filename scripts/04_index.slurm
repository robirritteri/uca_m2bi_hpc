#!/bin/bash
#SBATCH --job-name=star_index
#SBATCH --output=log/slurmjob-%A.out
#SBATCH --time=02:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=14
#SBATCH --mem=32G
#SBATCH --partition=normal

###############################################
# STAR – Genome index generation
###############################################

set -euo pipefail
IFS=$'\n\t'

echo "===== Starting STAR index generation ====="
date

#####
# Script to prepare the reference genome used by STAR
#####

# ==========================
# Path
# ==========================
INDEX_DIR="$HOME/index_star"

# create the index folder if it does not exist
if test ! -d "$INDEX_DIR"; then
    mkdir -p "$INDEX_DIR"
    echo "Creating index folder: $INDEX_DIR"
else
    echo "Index folder already exists: $INDEX_DIR"
fi

# FASTA and GTF
FASTA="/home/users/shared/databanks/Mus_musculus_GRCm39/fasta/all.fasta"
GTF="/home/users/shared/databanks/Mus_musculus_GRCm39/flat/genomic.gtf"

echo "  FASTA : $FASTA"
echo "  GTF   : $GTF"
echo "  INDEX : $INDEX_DIR"

# runMode defines the mode to prepare the reference genome for STAR.
# runThreadN : number of cores
# genomeDir : destination directory for the index
# genomeFastaFiles : reference FASTA
# sjdbGTFfile : GTF annotation
# sjdbOverhang : read length -1 (e.g. read length = 100 → 99)

STAR \
    --runMode genomeGenerate \
    --runThreadN 14 \
    --genomeDir "$INDEX_DIR" \
    --genomeFastaFiles "$FASTA" \
    --sjdbGTFfile "$GTF" \
    --sjdbOverhang 99

echo "===== STAR index generation completed successfully ====="
date

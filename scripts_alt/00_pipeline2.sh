#!/bin/bash
###############################################
# RNA-seq Pipeline Launcher
# Runs all steps of the workflow in sequence
###############################################

# Strict error handling
set -euo pipefail

mkdir -p log

echo "===== Starting RNA-seq pipeline ====="

# Step 1 — FastQC sur RAW
echo "[1/8] Running FastQC on raw reads..."
sbatch 01_fastqc.slurm

# Step 2 — Trimming (cutadapt)
echo "[2/8] Trimming reads..."
sbatch 02_cutadapt.slurm

# Step 3 — FastQC après trimming
echo "[3/8] Running FastQC on trimmed reads..."
sbatch 03_fastqc.slurm

# Step 4 — Création de l’index STAR
echo "[4/8] Building STAR genome index..."
sbatch 04_index.slurm

# Step 5 — Alignement (STAR)
echo "[5/8] Aligning reads to reference genome..."
sbatch 05_STAR.slurm

# Step 6 — Traitement BAM (Picard + samtools)
echo "[6/8] Cleaning BAM files (Picard/samtools)..."
sbatch 06_cleaning.slurm

# Step 7 — Comptage (featureCounts)
echo "[7/8] Counting reads (featureCounts)..."
sbatch 07_counts.slurm

# Step 8 — Normalisation & DE (DESeq2)
echo "[8/8] Running normalization and DESeq2 analysis..."
sbatch 08_R.slurm

echo "===== Pipeline submitted successfully ====="

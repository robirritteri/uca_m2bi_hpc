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
echo "[1/7] Running FastQC on raw reads..."
sbatch 01_fastqc.slurm

# Step 2 — Trimming (cutadapt)
echo "[2/7] Trimming reads..."
sbatch 02_trimming.slurm

# Step 3 — FastQC après trimming
echo "[3/7] Running FastQC on trimmed reads..."
sbatch 03_fastqc_posttrimming.slurm

# Step 4 — Alignement (STAR)
echo "[4/7] Aligning reads to reference genome..."
sbatch 04_alignement.slurm

# Step 5 — Traitement BAM (Picard + samtools)
echo "[5/7] Cleaning BAM files (Picard/samtools)..."
sbatch 05_traitement_bam.slurm

# Step 6 — Comptage (featureCounts)
echo "[6/7] Counting reads (featureCounts)..."
sbatch 06_comptage_featurecounts.slurm

# Step 7 — Normalisation & DE (DESeq2)
echo "[7/7] Running normalization and DESeq2 analysis..."
sbatch 07_normalisation_deseq2.slurm

echo "===== Pipeline submitted successfully ====="

#!/bin/bash
###############################################
# RNA-seq Pipeline Launcher
# Runs all steps of the workflow in sequence
###############################################

# Strict error handling
set -euo pipefail

# Create output directories if they do not exist
mkdir -p ../results
mkdir -p ../log

echo "===== Starting RNA-seq pipeline ====="

# Step 1 — Raw FastQC
echo "[1/7] Running FastQC on raw reads..."
sbatch 01_fastqc.slurm

# Step 2 — Trimming
echo "[2/7] Trimming reads..."
sbatch 02_trimming.slurm

# Step 3 — FastQC after trimming
echo "[3/7] Running FastQC on trimmed reads..."
sbatch 03_fastqc.slurm

# Step 4 — Alignment
echo "[4/7] Aligning reads to reference genome..."
sbatch 04_hisat.slurm

# Step 5 — BAM cleanup and QC (Picard)
echo "[5/7] Cleaning BAM files (Picard)..."
sbatch 05_picard.slurm

# Step 6 — Quantification
echo "[6/7] Counting reads (Samtools)..."
sbatch 06_samtools.slurm

# Step 7 — Downstream analysis in R
echo "[7/7] Running downstream analysis (R script)..."
sbatch 07_R.slurm

echo "===== Pipeline submitted successfully ====="

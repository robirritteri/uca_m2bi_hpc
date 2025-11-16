#!/bin/bash
#SBATCH --job-name=Analyse
#SBATCH --output=log/slurmjob-%A-%a
#SBATCH --time=00:30:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --array=0
#SBATCH --partition=normal

###############################################
# R Analysis – Statistical analysis and visualization
###############################################

set -euo pipefail
IFS=$'\n\t'

echo "===== Starting R analysis job ====="

echo "[INFO] Running R analysis script: Analyse.R" >&2
Rscript Analyse.R

echo "===== R analysis job completed successfully ====="
echo "Stopped at: $(date)" >&2
#!/bin/bash
#SBATCH --time=0:30:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --mem-per-cpu=16G
#SBATCH --cpus-per-task=20
#SBATCH --array=0-47
#SBATCH -o 04-log/slurmjob-%A-%a
#SBATCH --job-name=tophat
#SBATCH --partition=normal

echo 'samtools'

# Handling errors
set -euo pipefail

IFS=$'\n\t'

# Upload whatever required packages
module purge
source /home/users/shared/conda_envs/miniconda3/bin/activate

conda activate base
# Environnement must exist at this step
conda activate rnaseq


echo "Set up directories ..." >&2
# Set up data and result directories
# Run QC on trimmed data

EXPERIMENT=RNAseq 

DATA_DIR="$HOME"/03-results/"$EXPERIMENT"/align

echo "select file for analyse..." >&2

tab_bam=($(ls "$DATA_DIR"/*/*_RO_MP.bam))
echo "tab file bam = " >&2
printf '%s\n' "${tab_bam[@]}" >&2

# file name
filename=( $(basename "${tab_bam[$SLURM_ARRAY_TASK_ID]}" _RO_MP.bam) )

# temporaire file 
SCRATCHDIR=/storage/scratch/"$USER"/"$filename"/samtools
mkdir -p -m 700 "$SCRATCHDIR"

# file for storage
OUTPUT="$HOME"/03-results/"$EXPERIMENT"/samtools/"$filename"
mkdir -p "$OUTPUT"

cd "$SCRATCHDIR"


echo "Filter by quality" >&2
# Filter
samtools view -b -f 1 -F 12 ${tab_bam[$SLURM_ARRAY_TASK_ID]} "$SCRATCHDIR"/"$filename"_RO_MP_GQ.bam

tab_sort=($(ls "$SCRATCHDIR"/*_RO_MP_GQ.bam))
echo "tab file bam sort = " >&2
printf '%s\n' "${tab_sort[@]}" >&2

# Sort
samtools sort -n ${tab_sort[$SLURM_ARRAY_TASK_ID]} "$SCRATCHDIR"/"$filename"_ready

mv "$SCRATCHDIR"/* "$OUTPUT"/

# Cleaning in case something went wrong
rm -rf  "$SCRATCHDIR"

echo "Stop job : "`date` >&2

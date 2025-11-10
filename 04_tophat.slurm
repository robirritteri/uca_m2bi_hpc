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

echo 'alignment'

# Handling errors
set -euo pipefail

IFS=$'\n\t'

echo "start alignment on $SLURMD_NODENAME $date"

# Upload whatever required packages
module purge
source /home/users/shared/conda_envs/miniconda3/bin/activate

conda activate base
# Environnement must exist at this step
conda activate rnaseq

echo "Set up directories ..." >&2
# Set up data and result directories
# Run QC on trimmed data

INDEX=/home/users/shared/databanks/Mus_musculus_GRCm39/bowtie2/

EXPERIMENT=RNAseq 

DATA_DIR="$HOME"/03-results/"$EXPERIMENT"/trim 

echo "select file for analyse..." >&2
sscontrol_0h_B1_R1_1_trim_paired.fastq.gz
tab_trim_fw=($(ls "$DATA_DIR"/*/*1_trim_paired.fastq.gz))
echo "tab forward= " >&2
printf '%s\n' "${tab_trim_fw[@]}" >&2

tab_trim_rv=($(ls "$DATA_DIR"/*/*2_trim_paired.fastq.gz))
echo "tab revers= " >&2
printf '%s\n' "${tab_trim_rv[@]}" >&2

# file name
filename=( $(basename "${tab_trim_fw[$SLURM_ARRAY_TASK_ID]}" _1_trim_paired.fastq.gz) )

# temporaire file 
SCRATCHDIR=/storage/scratch/"$USER"/"$filename"/fastqc-post
mkdir -p -m 700 "$SCRATCHDIR"

# file for storage
OUTPUT="$HOME"/03-results/"$EXPERIMENT"/align/"$filename"
mkdir -p "$OUTPUT"

cd "$SCRATCHDIR"

# Run the program
echo "Start on $SLURMD_NODENAME: "`date` >&2

echo "Running Tophat2 on sample: ${tab_trim[$SLURM_ARRAY_TASK_ID]} ... " >&2
tophat2 -r 200 -p $SLURM_CPUS_PER_TASK -o "$OUTPUT" --b2-very-sensitive --library-type fr-firststrand --no-mixed "$INDEX/all"  "${tab_trim_fw[$SLURM_ARRAY_TASK_ID]}" "${tab_trim_rv[$SLURM_ARRAY_TASK_ID]}"

mv "$SCRATCHDIR" "$OUTPUT"

# Cleaning in case something went wrong
rm -rf  "$SCRATCHDIR"

echo "Stop job : "`date` >&2

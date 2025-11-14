#!/bin/bash
#SBATCH --time=6:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --mem=32G
#SBATCH --cpus-per-task=14
#SBATCH --array=0-23
#SBATCH -o 04-log/slurmjob-%A-%a
#SBATCH --job-name=hisat2
#SBATCH --partition=normal

echo 'alignment'

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

INDEX=$HOME/tophat_transcriptome_index/all

GTF=/home/users/shared/databanks/Mus_musculus_GRCm39/flat/genomic.gtf

EXPERIMENT=RNAseq 

DATA_DIR="$HOME"/03-results/"$EXPERIMENT"/trim 

echo "select file for analyse..." >&2

tab_trim_fw=($(ls "$DATA_DIR"/*/*1_trim_paired.fastq.gz))
echo "tab forward= " >&2
printf '%s\n' "${tab_trim_fw[@]}" >&2

tab_trim_rv=($(ls "$DATA_DIR"/*/*2_trim_paired.fastq.gz))
echo "tab revers= " >&2
printf '%s\n' "${tab_trim_rv[@]}" >&2

# file name
filename=( $(basename "${tab_trim_fw[$SLURM_ARRAY_TASK_ID]}" _1_trim_paired.fastq.gz) )

# temporaire file 
SCRATCHDIR=/storage/scratch/"$USER"/"$filename"/align
mkdir -p -m 700 "$SCRATCHDIR"

# file for storage
OUTPUT="$HOME"/03-results/"$EXPERIMENT"/align/"$filename"
mkdir -p "$OUTPUT"

cd "$SCRATCHDIR"

# Run the program
echo "Start on $SLURMD_NODENAME: "`date` >&2

echo "Running Tophat2 on sample: $filename ... " >&2
/usr/bin/time -v \
hisat2 -p $SLURM_CPUS_PER_TASK \
    --rna-strandness RF \
    --dta \
    -x "$INDEX/Mus_musculus" \
    -1 "${tab_trim_fw[$SLURM_ARRAY_TASK_ID]}" \
    -2 "${tab_trim_rv[$SLURM_ARRAY_TASK_ID]}" \
    -S "$SCRATCHDIR"/aligned.sam
    2> $HOME/04-log/"$filename"_time_text.txt

mv "$SCRATCHDIR"/* "$OUTPUT"/

# Cleaning in case something went wrong
rm -rf  "$SCRATCHDIR"

conda deactivate

echo "Stop job : "`date` >&2


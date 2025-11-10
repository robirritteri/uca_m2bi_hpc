#!/bin/bash
#SBATCH --time=0:30:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --mem-per-cpu=2G
#SBATCH --cpus-per-task=2
#SBATCH --array=0-47
#SBATCH -o 04-log/slurmjob-%A-%a
#SBATCH --job-name=qc_init
#SBATCH --partition=normal


echo 'Quality control'

# Handling errors
set -o errexit # ensure script will stop in case of ignored error
set -o nounset # force variable initialisation

IFS=$'\n\t'

# Upload whatever required packages
module load java/oracle-1.7.0_79 fastqc/0.11.7 

echo "Set up directories ..." >&2
# Set up data and result directories
# Run QC on raw data and an trimmed data

EXPERIMENT=RNAseq
PATH_DIR=/home/users/shared/data/stategra/RNAseq

echo "Set up an array with all fastq.gz subset sequence files..." >&2
tab_fastq=($(ls "$PATH_DIR"/*.fastq.gz))
echo "tab = " >&2
printf '%s\n' "${tab_fastq[@]}" >&2

# Set up the temporary directory
filename=$(basename "${tab_fastq[$SLURM_ARRAY_TASK_ID]}" .fastq.gz )

SCRATCHDIR=/storage/scratch/"$USER"/"$filename"/fastqc-init

OUTPUT="$HOME"/03-results/"$EXPERIMENT"/qc/"$filename"
mkdir -p "$OUTPUT"
# Look for empty result directory
if [ -d "$OUTPUT/fastqc-init" ]
then
    if [ "$(ls -A $OUTPUT/fastqc-init)" ]; then
    echo "$OUTPUT/fastqc-init is not empty and must be cleaned."
    rm -rf "$OUTPUT"/fastqc-init
    else
    echo "Directory $OUTPUT/fastqc-init is empty."
    fi
fi

mkdir -p -m 700 "$SCRATCHDIR"

cd "$SCRATCHDIR"

# Run the program
echo "Start on $SLURMD_NODENAME: "`date` >&2

echo "Run the initial quality control... " >&2
fastqc "${tab_fastq[$SLURM_ARRAY_TASK_ID]}" --dir "$SCRATCHDIR" -o "$SCRATCHDIR"
mv "$SCRATCHDIR" "$OUTPUT"

# Cleaning in case something went wrong
rm -rf  "$SCRATCHDIR"

echo "Stop job : "`date` >&2


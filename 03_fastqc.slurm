#!/bin/bash
#SBATCH --time=0:30:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --mem-per-cpu=2G
#SBATCH --cpus-per-task=2
#SBATCH --array=0-95
#SBATCH -o 04-log/slurmjob-%A-%a
#SBATCH --job-name=qc_post
#SBATCH --partition=normal

echo 'Quality control'

# Handling errors
set -o errexit # ensure script will stop in case of ignored error
set -o nounset # force variable initialisation


IFS=$'\n\t'

# Upload whatever required packages
module purge
module load java/oracle-1.7.0_79 fastqc/0.11.7 

echo "Set up directories ..." >&2
# Set up data and result directories
# Run QC on trimmed data

EXPERIMENT=RNAseq 

DATA_DIR="$HOME"/03-results/"$EXPERIMENT"/trim 

echo "Set up an array with all fastq.gz sequence files..." >&2
tab_trim=($(ls "$DATA_DIR"/*/*trim*.fastq.gz))
echo "tab = " >&2
printf '%s\n' "${tab_trim[@]}" >&2

# Set up the temporary directory
#SCRATCHDIR=/storage/scratch/"$USER"/"$SLURM_JOB_ID"

if [[ "${tab_trim[$SLURM_ARRAY_TASK_ID]}" =~ "trim_paired" ]] ; then
   echo "Paired expression found in filename in trim directory."
   filename=($(basename "${tab_trim[$SLURM_ARRAY_TASK_ID]}" _trim_paired.fastq.gz ))
elif [[ "${tab_trim[$SLURM_ARRAY_TASK_ID]}" =~ "trim_unpaired" ]] ; then
   echo "Unpaired expression found in filename in trim directory."
   filename=($(basename "${tab_trim[$SLURM_ARRAY_TASK_ID]}" _trim_unpaired.fastq.gz ))
else 
   echo "No paired or unpaired match expression in filename."
fi

SCRATCHDIR=/storage/scratch/"$USER"/"$filename"/fastqc-post

OUTPUT="$HOME"/03-results/"$EXPERIMENT"/qc/"$filename"
mkdir -p "$OUTPUT"
mkdir -p -m 700 "$SCRATCHDIR"

cd "$SCRATCHDIR"

# Run the program
echo "Start on $SLURMD_NODENAME: "`date` >&2

echo "Run the post-trimming quality control on "${tab_trim[$SLURM_ARRAY_TASK_ID]}" ... " >&2
fastqc "${tab_trim[$SLURM_ARRAY_TASK_ID]}" -dir "$SCRATCHDIR" -o "$SCRATCHDIR"
mv "$SCRATCHDIR" "$OUTPUT"

# Cleaning in case something went wrong
rm -rf  "$SCRATCHDIR"

echo "Stop job : "`date` >&2


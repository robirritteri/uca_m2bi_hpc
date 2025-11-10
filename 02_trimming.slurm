#!/bin/bash
#SBATCH --time=0:40:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
##SBATCH --mem=3G
#SBATCH --mem=12G
#SBATCH --cpus-per-task=6
#SBATCH --array=0-47
#SBATCH -o 04-log/slurmjob-%A-%a
#SBATCH --job-name=trim
#SBATCH --partition=normal


echo 'Quality control and trimming'

# Handling errors
set -o errexit # ensure script will stop in case of ignored error
set -o nounset # force variable initialisation


IFS=$'\n\t'

#Set up whatever package we need to run with
module purge
module load gcc/8.1.0 java/oracle-1.7.0_79 trimmomatic/0.38


echo "Set up directories ..." >&2
#Set up the temporary directory

EXPERIMENT=RNAseq
SCRATCHDIR=/storage/scratch/"$USER"/"$SLURM_JOB_ID"

OUTPUT="$HOME"/03-results/"$EXPERIMENT"/trim
mkdir -p "$OUTPUT"
mkdir -p -m 700 "$SCRATCHDIR"
cd "$SCRATCHDIR"

DATA_DIR=/home/users/shared/data/stategra/"$EXPERIMENT" 
PRIMER_DIR=/home/users/shared/data/stategra

#Run the program
echo "Start on $SLURMD_NODENAME: "`date` >&2

echo "Set up 2 arrays with forward and reverse fastq.gz sequence files..." >&2

tab_fwd=($(ls "$DATA_DIR"/*_1.fastq.gz | sort -k9,9 ))
echo "tab_fwd = " >&2
printf '%s\n' "${tab_fwd[@]}" >&2

tab_rev=($(ls "$DATA_DIR"/*_2.fastq.gz | sort -k9,9))
echo "tab_rev = " >&2
printf '%s\n' "${tab_rev[@]}" >&2

echo "Run the trimming with trimmomamic tool..." >&2
java -jar /opt/apps/trimmomatic-0.38/trimmomatic-0.38.jar PE -threads ${SLURM_CPUS_ON_NODE} \
    -trimlog "$OUTPUT"/trim.log -summary "$OUTPUT"/stats \
    "${tab_fwd[$SLURM_ARRAY_TASK_ID]}" "${tab_rev[$SLURM_ARRAY_TASK_ID]}" \
    $(basename "${tab_fwd[$SLURM_ARRAY_TASK_ID]}" .fastq.gz)_trim_paired.fastq.gz \
    $(basename "${tab_fwd[$SLURM_ARRAY_TASK_ID]}" .fastq.gz)_trim_unpaired.fastq.gz \
    $(basename "${tab_rev[$SLURM_ARRAY_TASK_ID]}" .fastq.gz)_trim_paired.fastq.gz \
    $(basename "${tab_rev[$SLURM_ARRAY_TASK_ID]}" .fastq.gz)_trim_unpaired.fastq.gz \
    ILLUMINACLIP:"$PRIMER_DIR"/NexteraPE-PE.fa:2:30:10:2:keepBothReads \
    LEADING:3 \
    TRAILING:3 \
    SLIDINGWINDOW:4:15 \
    MINLEN:33

# Move results in one's directory
mv  "$SCRATCHDIR" "$OUTPUT"

# Cleaning in case something went wrong
rm -rf  "$SCRATCHDIR"

echo "Stop job : "`date` >&2

unset IFS



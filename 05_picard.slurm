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

echo 'picard'

# Handling errors
set -euo pipefail

IFS=$'\n\t'

# Upload whatever required packages
module purge
module load java/oracle-1.7.0_79 picard/2.18.25

echo "Set up directories ..." >&2
# Set up data and result directories
# Run QC on trimmed data

PICARD=/home/users/shared/tools/picard/picard.jar

EXPERIMENT=RNAseq 

DATA_DIR="$HOME"/03-results/"$EXPERIMENT"/align

echo "select file for analyse..." >&2
sscontrol_0h_B1_R1_1_trim_paired.fastq.gz
tab_acpt_bam=($(ls "$DATA_DIR"/*/*accepted_hits.bam))
echo "tab file bam = " >&2
printf '%s\n' "${tab_acpt_bam[@]}" >&2

# file name
filename=( $(basename "${tab_acpt_bam[$SLURM_ARRAY_TASK_ID]}" accepted_hits.bam) )

# temporaire file 
SCRATCHDIR=/storage/scratch/"$USER"/"$filename"/picard
mkdir -p -m 700 "$SCRATCHDIR"

# file for storage
OUTPUT="$HOME"/03-results/"$EXPERIMENT"/align/"$filename"
mkdir -p "$OUTPUT"

cd "$SCRATCHDIR"

echo "Sort reads using Picard tools" >&2
java -jar $PICARD SortSam \
    INPUT="${tab_acpt_bam[$SLURM_ARRAY_TASK_ID]}" \
    OUTPUT="$SCRATCHDIR/${filename}_RO.bam" \
    SORT_ORDER=coordinate \
    VALIDATION_STRINGENCY=LENIENT


echo "select new file for analyse" >&2
tab_R0=($(ls "$SCRATCHDIR"/*_RO.bam))
echo "tab file RO bam = " >&2
printf '%s\n' "${tab_R0[@]}" >&2

echo "Mark Duplicates using Picard tools" >&2
java -jar $PICARD MarkDuplicates \
    INPUT="$SCRATCHDIR"/"${tab_RO[$SLURM_ARRAY_TASK_ID]}" \
    OUTPUT="$SCRATCHDIR"/"$filename"_RO_MP.bam \
    CREATE_INDEX=false \
    VALIDATION_STRINGENCY=LENIENT \
    ASSUME_SORTED=false \
    REMOVE_DUPLICATES=false \
    METRICS_FILE="$SCRATCHDIR"/"$filename"_MP.metrixMP
    
echo "select new file for analyse" >&2
tab_R0_MP=($(ls "$DATA_DIR"/*_RO_MP.bam))
echo "tab file BO MP bam  = " >&2
printf '%s\n' "${tab_R0_MP[@]}" >&2

echo "Quality check: Insert Size Estimation using Picard tools" >&2
java -Xmx2g -jar $PICARD CollectInsertSizeMetrics \
    HISTOGRAM_FILE="$SCRATCHDIR"/"$filename"_insert.size.hist.pdf \
    INPUT="${tab_R0_MP[$SLURM_ARRAY_TASK_ID]}" \
    OUTPUT="$SCRATCHDIR/${filename}_insert.size"
                
mv "$SCRATCHDIR"/* "$OUTPUT"/

# Cleaning in case something went wrong
rm -rf  "$SCRATCHDIR"

echo "Stop job : "`date` >&2

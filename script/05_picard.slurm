#!/bin/bash
#SBATCH --time=0:30:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --mem=16G
#SBATCH --cpus-per-task=1
#SBATCH --array=0-47
#SBATCH -o 04-log/slurmjob-%A-%a.out
#SBATCH -e 04-log/slurmjob-%A-%a.err
#SBATCH --job-name=picard
#SBATCH --partition=normal

echo 'picard'

set -euo pipefail
IFS=$'\n\t'

module purge
module load java/oracle-1.11.0_11 picard/2.18.25
source /home/users/shared/conda_envs/miniconda3/bin/activate

conda activate base
# Environnement must exist at this step
conda activate rnaseq


PICARD=/opt/apps/picard-2.18.25/picard.jar
DATA_DIR="$HOME/03-results/RNAseq/raw/align"

# Selection des fichiers bam
tab_acpt_bam=($(ls "$DATA_DIR"/*/*aligned.sorted.bam))
echo "tab file bam = "
printf '%s\n' "${tab_acpt_bam[@]}"

# Nom du fichier courant
filename=$(basename "${tab_acpt_bam[$SLURM_ARRAY_TASK_ID]}" _aligned.sorted.bam)

# Répertoires temporaires et de sortie
SCRATCHDIR=/storage/scratch/"$USER"/"$filename"/picard
mkdir -p -m 700 "$SCRATCHDIR"

OUTPUT="$HOME/03-results/$EXPERIMENT/picard/$filename"
mkdir -p "$OUTPUT"

cd "$SCRATCHDIR"

# ---- SORT SAM ----
echo "Sort reads using Picard tools" >&2
java -jar $PICARD SortSam \
    INPUT="${tab_acpt_bam[$SLURM_ARRAY_TASK_ID]}" \
    OUTPUT="$SCRATCHDIR"/"${filename}"_RO.bam \
    SORT_ORDER=coordinate \
    VALIDATION_STRINGENCY=LENIENT 

samtools index "${filename}_RO.bam"


# ---- MARK DUPLICATES ----
echo "Mark Duplicates using Picard tools" >&2
RO_FILE="$SCRATCHDIR/${filename}_RO.bam"
java -jar $PICARD MarkDuplicates \
    INPUT="$RO_FILE" \
    OUTPUT="$SCRATCHDIR"/"${filename}"_RO_MP.bam \
    CREATE_INDEX=false \
    VALIDATION_STRINGENCY=LENIENT \
    ASSUME_SORTED=false \
    REMOVE_DUPLICATES=false \
    METRICS_FILE="$SCRATCHDIR"/"${filename}"_MP.metrixMP 

samtools index "${filename}_RO_MP.bam"

# ---- MOVE RESULTS ----

mv "$SCRATCHDIR"/* "$OUTPUT"/

echo "Stop job : $(date)" >&2


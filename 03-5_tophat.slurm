#!/bin/bash
#SBATCH --time=4:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --mem=30G
#SBATCH --cpus-per-task=14
#SBATCH -o 04-log/slurmjob-%j.log
#SBATCH --job-name=bowtie2_index
#SBATCH --partition=normal

set -euo pipefail
IFS=$'\n\t'

echo ">>> Initialisation du job sur $SLURMD_NODENAME" 
module purge
source /home/users/shared/conda_envs/miniconda3/bin/activate
conda activate rnaseq

FASTA=/home/users/shared/databanks/Mus_musculus_GRCm39/fasta/all.fasta
OUTPUT=$HOME/tophat_transcriptome_index/all

SCRATCHDIR=/storage/scratch/$USER/bowtie2_index
mkdir -p -m 700 "$SCRATCHDIR"
mkdir -p "$OUTPUT"

echo ">>> Construction de l'index Bowtie2 ..."
cd "$SCRATCHDIR"

bowtie2-build $FASTA $SCRATCHDIR/all

echo ">>> Déplacement de l'index vers le dossier final ..."
mv "$SCRATCHDIR"/* "$OUTPUT"/

rm -rf "$SCRATCHDIR"
echo ">>> Terminé à $(date)"


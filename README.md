## 1. Overview

This repository contains a complete RNA-seq preprocessing and quantification pipeline designed for execution on an HPC cluster using SLURM and a conda environment.

It runs the full workflow:

- FastQC on raw FASTQ
- Adapter trimming (Cutadapt – paired-end)
- FastQC post-trimming
- STAR genome index generation
- STAR paired-end alignment
- BAM processing (fixmate, sort, dedup) — samtools + Picard
- Filtering + featureCounts
- DESeq2 normalization 

**All scripts are SLURM jobs (*.slurm) and use a shared conda environment (rnaseq).**

Output folders are created automatically inside : $HOME

You can download the full pipeline by cloning this repository:

```code
git clone https://github.com/robirritteri/uca_m2bi_hpc.git
```

## 2. Pipeline structure
```text
uca_m2bi_hpc/
│
├── script/
│   ├── 01_fastqc.slurm
│   ├── 02_cutadapt.slurm
│   ├── 03_fastqc.slurm
│   ├── 04_index.slurm
│   ├── 05_STAR.slurm
│   ├── 06_cleaning.slurm
│   ├── 07_counts.slurm
│   ├── 08_R.slurm
│   └── 00_pipeline2.sh   
│
├── rnaseq.yaml
│
├── log/
│   └── slurmjob-*.out   (SLURM outputs)
│
└── results/
    └── RNAseq/
        ├── raw/
        │   └── qc-init/
        ├── trimmed/
        │   ├── paired/
        │   └── qc-post/
        ├── alignment/
        │   └── paired/
        ├── picard/
        │   └── bamTraite/
        ├── samtools/
        ├── counts/
        └── deseq2/
```

## 3. Conda environment

Create the required environment:
```code
conda env create -f rnaseq.yaml
conda activate rnaseq
```

This environment includes:
**Cutadapt, samtools, STAR, picard, subread (featureCounts), R + DESeq2, tidyverse.**

It is fully compatible with all scripts.

## 4. Running the full pipeline

Launch:
```code
bash 00_pipeline.sh
```

This will automatically submit all steps to SLURM in sequence.

Each script takes care of its own directories, scratch space, logging, and outputs.

## 5. Pipeline
### 01 — FastQC on raw reads

Runs FastQC on all raw FASTQ files using an sbatch array.
Also generates a MultiQC report.

### 02 — Adapter trimming (paired-end, Cutadapt)

Trims adapters and low-quality bases with Cutadapt using the adapters you provided.

Output:
results/RNAseq/trimmed/paired/*.trim.fastq.gz

### 03 — FastQC after trimming

FastQC + MultiQC on trimmed FASTQ.

### 04 — STAR genome index generation

Uses the Mus musculus GRCm39 FASTA + GTF:
```code
/home/users/shared/databanks/Mus_musculus_GRCm39/fasta/all.fasta
/home/users/shared/databanks/Mus_musculus_GRCm39/flat/genomic.gtf
```
Index is created in:
```code
$HOME
```

### 05 — STAR alignment (paired-end)

Aligns trimmed paired-end reads.

Produces:
```text
$HOME/results/RNAseq/alignment/paired/<sample>/
   ├── <sample>_Aligned.sortedByCoord.out.bam
   ├── <sample>_Log.final.out
   └── <sample>_ReadsPerGene.out.tab
```

### 06 — Picard + Samtools cleaning

Operations for paired-end BAMs:
```text
- fixmate
- sort
- filter quality
- remove duplicates
- write metrics
```
Output:
```code
results/RNAseq/picard/bamTraite/paired/dedup_<sample>.bam
```

### 07 — featureCounts quantification

Counts reads with:
```
-s 2 (reverse stranded)
-p (paired-end)
-a (GTF="/home/users/shared/databanks/Mus_musculus_GRCm39/flat/genomic.gtf")
```

Output:

results/RNAseq/samtools/<sample>/<sample>.featureCounts.txt

### 08 — R analysis

- imports merged featureCounts table
- computes normalization factors
- outputs VST and normalized counts

Outputs:
```code
$HOME/results/RNAseq/counts/deseq2_normalized_counts.csv
$HOME/results/RNAseq/counts/deseq2_vst.csv
$HOME/results/RNAseq/counts/dds.rds
```

## 6. Testing an alternative pipeline 

In addition to the primary STATegra-based pipeline, this work also explored a second, independent RNA-seq pipeline using different tools, in order to compare performance, metrics, and workflow behavior.

For example:

- cutadapt instead of trimmomatic
- STAR instead of HISAT2


## 7. Pre-run checklist

Before running:

- Check that your environment is loaded
```code
conda activate rnaseq
```
- Check that you are inside your $HOME

- Check that input FASTQ exist

```code
ls /home/users/shared/data/stategra/RNAseq/raw
```

- Test a single step
```code
sbatch script/01_fastqc_raw.slurm
```

## 8. License

MIT License — feel free to reuse and adapt.

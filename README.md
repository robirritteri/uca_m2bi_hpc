# RNA-seq Processing Pipeline

This repository contains a small SLURM-based RNA-seq processing pipeline used to run FastQC, trimming, alignment (HISAT2), BAM/QC (Picard), counting (featureCounts), and downstream analysis in R.

Overview
--------
- `00_pipeline.sh` - launcher that submits pipeline steps to SLURM with dependencies.
- `01_fastqc.slurm` - initial FastQC on raw FASTQ files.
- `02_trimming.slurm` - Trimmomatic read trimming (paired-end mode).
- `03_fastqc.slurm` - FastQC after trimming.
- `04_hisat.slurm` - HISAT2 alignment (paired-end).
- `05_picard.slurm` - Picard processing: SortSam, MarkDuplicates.
- `06_counts.slurm` - SAMtools filtering + `featureCounts` quantification.
- `07_R.slurm` - launches R scripts: `all_counts.R` then `Analyse.R`.
- `all_counts.R` - R scripts for merge different file `featureCounts`
- `Analyse.R` - R analysis scripts (DESeq2, plots, heatmaps).
- `results/` — example outputs and analysis results.

Design principles
-----------------
- Each computational step runs as an independent SLURM job (.slurm file).
- The launcher `00_pipeline.sh` submits steps and wires dependencies using `sbatch --dependency=afterok:JOBID` so steps run sequentially.
- Each step writes temporary files to a scratch directory (e.g. `/storage/scratch/$USER/...`) and moves final outputs to `results/` 
- R scripts save figures (PDF) and result tables in `results/analysis`.

Quick start
-----------
1. From the pipeline directory, inspect and optionally adjust configurations at the top of the `.slurm` scripts (paths, modules, array sizes).

2. Submit the pipeline launcher (recommended):

```bash
cd /uca_m2bi_hpc/script/
# dry-run to preview sbatch commands
DRYRUN=1 ./00_pipeline.sh

# actual submission
./00_pipeline.sh
```

`00_pipeline.sh` will create `log/pipeline.jobs` containing the mapping `step:jobid`.

Notes on `DRYRUN`:
- When `DRYRUN=1`, submission commands are printed but no jobs are sent to SLURM.

Running steps manually
----------------------
You can submit individual steps with `sbatch` if you prefer to control them manually (use absolute paths):

```bash
sbatch /uca_m2bi_hpc/script/01_fastqc.slurm
sbatch /uca_m2bi_hpc/script/02_trimming.slurm
```

Files and outputs
-----------------
- FASTQ inputs are expected in the directories configured in the `.slurm` scripts (e.g. `RAW_DIR`, `DATA_DIR`, `TRIM_DIR`). Edit those variables if your data live elsewhere.
- Trimmed FASTQ, alignment BAMs, featureCounts outputs and analysis PDFs are written to `results/` subfolders. R analysis writes into `results/analysis`.
- `log/` contains Slurm job output files and `pipeline.jobs` created by the launcher.

Pre-run checks (recommended)
----------------------------
- Confirm required modules and conda envs are available on your cluster (see `module load` and `conda activate` lines in `.slurm` files).
- Ensure `/storage/scratch` is available and writable on compute nodes.
- Check `SBATCH --array` sizes; arrays must match the number of files to process.

Key safety checks added
-----------------------
- The launcher verifies each script exists before submission and logs job IDs.
- Several `.slurm` scripts change to the scratch directory (`cd "$SCRATCHDIR"`) before running tools so I/O happens on scratch.
- `07_R.slurm` now validates that `all_featureCounts_counts.txt` exists, is non-empty and (if `all_counts.R` is present) that the counts file has modification time >= the `all_counts.R` script. If validation fails the job exits with a clear error.

R analysis
----------
The R analysis pipeline consists of three interconnected scripts:

### all_counts.R
- **Purpose**: Merges individual featureCounts output files (one per sample) into a single count matrix.
- **Inputs**: Individual `*.featureCounts.txt` files from `results/` (produced by `06_samtools.slurm`).
- **Output**: `all_featureCounts_counts.txt` (tab-separated, Geneid × samples).
- **Key steps**: 
  - Locates all featureCounts files
  - Reads each file and extracts counts
  - Merges by gene ID into unified count matrix
  - Writes to `all_featureCounts_counts.txt` for downstream analysis
- **Note**: Must complete successfully before running `Analyse.R` or `Deseq2.R` (validated by `07_R.slurm`).

### Analyse.R
- **Purpose**: Main differential expression analysis comparing project data (own samples) vs. published dataset.
- **Inputs**: `all_featureCounts_counts.txt`, `STATegra.RNAseq.allSamples.counts.csv` (paper data).
- **Outputs** (saved to `results/analysis`):
  - `PCA_mydata.pdf`, `PCA_paperdata.pdf`, `PCA_my_vs_paper.pdf` — PCA visualizations
  - `heatmap_mydata_top20.pdf`, `heatmap_paper_top20.pdf` — Heatmaps of top DE genes
  - `DE_results_mydata.tsv`, `DE_results_paper.tsv` — DE tables (TSV format)
- **Key analyses**:
  - Builds sample metadata from column names (condition, time, batch, replicate)
  - Runs DESeq2 with design `~ batch + time + condition`
  - Applies VST for visualization
  - Compares Ikaros vs Control in both datasets
  - Generates publication-ready PCA and heatmap plots

**Workflow order** (in `07_R.slurm`):
1. `all_counts.R` — merge featureCounts (required)
2. `Analyse.R` — main analysis and comparison (automatic, validated)

Troubleshooting tips
--------------------
- If a Slurm job fails, inspect the job's `log/<SCRIPT>-<JOBID>-<ARRAY>.out` file and the `sbatch` returned job ID in `log/pipeline.jobs`.
- If a step produces no output, verify scratch directory usage and that the tool can write to scratch.
- If R scripts fail at `biomaRt::useMart`, ensure the node has internet access or pre-download annotation tables.

Suggested improvements (future)
------------------------------
- Add `sacct`-based post-run reporting in the launcher to print job statuses and runtime.
- Add automatic re-run or notification on job failure (email or Slack webhook).
- Add a single YAML configuration file to set common paths/parameters for all scripts.
- Use a workflow manager (Snakemake/Nextflow) for clearer dependency management and portability.

Contact / next steps
--------------------
If you want, I can:
- Add `sacct` reporting to `00_pipeline.sh`.
- Add a YAML config and wire scripts to read values from it.
- Add automatic TSV/CSV archival of all final outputs.

---
Generated on: 16 November 2025

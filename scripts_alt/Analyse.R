library(dplyr)
library(DESeq2)
library(patchwork)
library(grid)
library(biomaRt)
library(ggplot2)
library(pheatmap)

PATH <- commandArgs(trailingOnly = TRUE)

# Set working directory to this project folder 
setwd(PATH)

# Create plots/results directory
PLOT_DIR <- file.path(getwd() ,"analysis")
if (!dir.exists(PLOT_DIR)) dir.create(PLOT_DIR, recursive = TRUE)

###############################################
# Step 1: Load count matrix
###############################################

# Read merged counts file produced by featureCounts merging
counts <- read.table("all_featureCounts_counts.txt",
                     header = TRUE, sep = "\t", row.names = 1)
counts <- as.matrix(counts)

# Build sample metadata from column names
samples <- colnames(counts)
parts <- strsplit(samples, "_")
meta <- data.frame(
  sample = samples,
  condition = sapply(parts, `[`, 1),    # treatment condition
  time = sapply(parts, `[`, 2),         # time point
  batch = sapply(parts, `[`, 3),        # batch
  rep = sapply(parts, `[`, 4),          # replicate
  stringsAsFactors = FALSE
)

# Clean-up and factor conversion
meta$rep <- sub("^R", "", meta$rep)
meta$time <- sub("h$", "", meta$time)
meta$condition <- gsub("^sscontrol$", "control", meta$condition)
meta$condition <- gsub("^ssikaros$", "ikaros", meta$condition)
meta$condition <- factor(meta$condition, levels = c("control", "ikaros"))
meta$time <- factor(meta$time, levels = sort(unique(meta$time)))
meta$batch <- factor(meta$batch)
meta$rep <- factor(meta$rep)

if (!all(meta$sample == colnames(counts))) {
  meta <- meta[match(colnames(counts), meta$sample), ]
}

###############################################
# Step 2: DESeq2 setup and run
###############################################

dds <- DESeqDataSetFromMatrix(countData = counts, colData = meta, design = ~ batch + time + condition)
dds <- dds[rowSums(counts(dds) > 10) >= 3, ]
dds <- DESeq(dds)

# Variance-stabilizing transformation for visualization
vsd <- vst(dds, blind = FALSE)

###############################################
# Step 3: Plots for own data
###############################################

message("[INFO] Creating PCA plot (own data)")
pca_own <- plotPCA(vsd, intgroup = c("condition", "batch", "time")) + ggtitle("PCA – mes données")
ggsave(filename = file.path(PLOT_DIR, "PCA_mydata.pdf"), plot = pca_own, width = 8, height = 6)

message("[INFO] Differential expression (Ikaros vs Control)")
res <- results(dds, contrast = c("condition", "ikaros", "control"))
res_df <- as.data.frame(res)
res_df <- res_df[!is.na(res_df$padj), ]
write.table(res_df, file = file.path(PLOT_DIR, "DE_results_mydata.tsv"), sep = "\t", quote = FALSE)

topgenes <- rownames(res_df[order(res_df$padj, na.last = TRUE), ])[1:20]
message("[INFO] Creating heatmap (top 20 genes) for own data")
pheatmap(assay(vsd)[topgenes, , drop = FALSE],
         scale = "row",
         annotation_col = as.data.frame(colData(dds))[, c("condition", "batch", "time")],
         main = "Top 20 DE genes – nos données",
         filename = file.path(PLOT_DIR, "heatmap_mydata_top20.pdf"))

###############################################
# Step 4: External 'paper' dataset processing and plotting
###############################################

message("[INFO] Loading publication dataset and harmonizing annotations")
paper <- read.csv("STATegra.RNAseq.allSamples.counts.csv", row.names = 1, check.names = FALSE)
sel <- grep("_(0H|24H)$", colnames(paper), value = TRUE)
paper <- paper[, sel]

mart <- useMart("ensembl", dataset = "mmusculus_gene_ensembl")
annot <- getBM(attributes = c("ensembl_gene_id", "mgi_symbol"), filters = "ensembl_gene_id",
               values = rownames(paper), mart = mart)

gene_symbols <- annot$mgi_symbol[match(rownames(paper), annot$ensembl_gene_id)]
paper <- paper[!is.na(gene_symbols), ]
gene_symbols <- gene_symbols[!is.na(gene_symbols)]
rownames(paper) <- make.unique(gene_symbols)

parts_paper <- strsplit(colnames(paper), "_")
meta_paper <- data.frame(
  batch = sapply(parts_paper, `[`, 1),
  batch_number = sapply(parts_paper, `[`, 2),
  condition = sapply(parts_paper, `[`, 3),
  time = sapply(parts_paper, `[`, 4),
  stringsAsFactors = FALSE
)
meta_paper$condition <- gsub("^Ctr$", "control", meta_paper$condition)
meta_paper$condition <- gsub("^Ik$", "ikaros", meta_paper$condition)
meta_paper$condition <- factor(meta_paper$condition, levels = c("control", "ikaros"))
meta_paper$time <- sub("H$", "", meta_paper$time)
meta_paper$time <- factor(meta_paper$time, levels = c("0", "24"))

dds_paper <- DESeqDataSetFromMatrix(countData = paper, colData = meta_paper, design = ~ time + condition)
dds_paper <- dds_paper[rowSums(counts(dds_paper) > 10) >= 3, ]
dds_paper <- DESeq(dds_paper)
vsd_paper <- vst(dds_paper, blind = FALSE)

message("[INFO] Creating PCA for publication data and saving")
pca_paper <- plotPCA(vsd_paper, intgroup = c("condition", "time")) + ggtitle("PCA – Données publication")
ggsave(filename = file.path(PLOT_DIR, "PCA_paperdata.pdf"), plot = pca_paper, width = 8, height = 6)

res_paper <- results(dds_paper, contrast = c("condition", "ikaros", "control"))
res_df_paper <- as.data.frame(res_paper)
res_df_paper <- res_df_paper[!is.na(res_df_paper$padj), ]
write.table(res_df_paper, file = file.path(PLOT_DIR, "DE_results_paper.tsv"), sep = "\t", quote = FALSE)

topgenes_paper <- rownames(res_df_paper[order(res_df_paper$padj, na.last = TRUE), ])[1:20]
message("[INFO] Creating heatmap (top 20 genes) for publication data")
pheatmap(assay(vsd_paper)[topgenes_paper, , drop = FALSE],
         scale = "row",
         annotation_col = as.data.frame(colData(dds_paper))[, c("condition", "time")],
         main = "Top 20 DE genes – Données publication",
         filename = file.path(PLOT_DIR, "heatmap_paper_top20.pdf"))

# Combined comparison plot (own vs paper) and save
message("[INFO] Creating combined PCA comparison and saving")
p_simplified <- plotPCA(vsd, intgroup = c("condition", "time")) + ggtitle("PCA – nos données")
P2 <- plotPCA(vsd_paper, intgroup = c("condition", "time")) + ggtitle("PCA – Données publication")
combined_pca <- p_simplified / P2
ggsave(filename = file.path(PLOT_DIR, "PCA_mine_vs_paper.pdf"), plot = combined_pca, width = 10, height = 8)

message("[INFO] All plots and DE result tables saved to: ", PLOT_DIR)

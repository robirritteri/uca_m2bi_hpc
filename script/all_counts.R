###############################################
# DESeq2 Analysis – RNA-seq differential expression
###############################################

# Load required libraries
library(dplyr)

# list libraries
cran_pkgs <- c("dplyr")

# Installe packages CRAN
install_if_missing <- function(pkgs) {
  to_install <- pkgs[!pkgs %in% installed.packages()[, "Package"]]
  if (length(to_install) > 0) {
    install.packages(to_install)
  } 

install_if_missing(cran_pkgs)


PATH <- commandArgs(trailingOnly = TRUE)

# Set working directory
setwd(PATH)

###############################################
# Step 1: Load and merge featureCounts files
###############################################

# Directory containing featureCounts files
fc_dir <- "/home/users/student05/results/RNAseq/counts"

# List all featureCounts files
files <- list.files(fc_dir, pattern = "featureCounts.txt$", full.names = TRUE)

# Function to read a single featureCounts file
read_fc <- function(path) {
  df <- read.table(path, header = TRUE, sep = "\t", check.names = FALSE)
  
  # Extract sample name from filename
  sample <- basename(path)
  sample <- sub(".featureCounts.txt", "", sample)
  
  # Keep Geneid and count column (7th column)
  df_small <- df[, c("Geneid", colnames(df)[7])]
  
  # Rename count column to sample name
  colnames(df_small)[2] <- sample
  return(df_small)
}

# Read all featureCounts files
list_fc <- lapply(files, read_fc)

# Merge all files by Geneid
merged <- Reduce(function(x, y) merge(x, y, by = "Geneid"), list_fc)

# Display first rows
head(merged)

# Write merged counts to file
write.table(merged, "all_featureCounts_counts.txt",
            sep = "\t", quote = FALSE, row.names = FALSE)

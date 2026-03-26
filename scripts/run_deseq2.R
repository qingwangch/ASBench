args <- commandArgs(trailingOnly=TRUE)
count_file <- args[1]
sample_file <- args[2]
out_file <- args[3]

library(DESeq2)

countData <- read.table(count_file, header=TRUE, row.names=1, sep="\t", check.names=FALSE)
sampleInfo <- read.table(sample_file, header=TRUE, sep="\t", check.names=FALSE)

dds <- DESeqDataSetFromMatrix(
  countData = round(countData),
  colData   = sampleInfo,
  design    = ~ group
)

dds <- DESeq(dds)
res <- results(dds)
res <- as.data.frame(res)
res <- res[!is.na(res$padj), ]

write.table(res, out_file, sep="\t", quote=FALSE, col.names=NA)
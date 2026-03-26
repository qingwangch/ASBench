args <- commandArgs(trailingOnly=TRUE)
count_file <- args[1]
sample_file <- args[2]
out_file <- args[3]

library(limma)
library(edgeR)

countData <- read.table(count_file, header=TRUE, row.names=1, sep="\t", check.names=FALSE)
sampleInfo <- read.table(sample_file, header=TRUE, sep="\t", check.names=FALSE)

group <- factor(sampleInfo$group)
design <- model.matrix(~group)

dge <- DGEList(counts=countData)
keep <- filterByExpr(dge, design)
dge <- dge[keep,,keep.lib.sizes=FALSE]
dge <- calcNormFactors(dge)

logCPM <- cpm(dge, log=TRUE, prior.count=3)
fit <- lmFit(logCPM, design)
fit <- eBayes(fit, trend=TRUE)

res <- topTable(fit, coef=ncol(design), n=Inf)
write.table(res, out_file, sep="\t", quote=FALSE, col.names=NA)
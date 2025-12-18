suppressPackageStartupMessages({
  library(edgeR)
  library(limma)
  library(optparse)
})

opt_list <- list(
  make_option("--counts", type="character"),
  make_option("--meta",   type="character"),
  make_option("--out",    type="character", default="limma_trend_results.tsv")
)
opt <- parse_args(OptionParser(option_list=opt_list))

countData <- read.delim(opt$counts, row.names=1, check.names=FALSE)
meta      <- read.delim(opt$meta)

stopifnot(all(colnames(countData) %in% meta$sample))
meta <- meta[match(colnames(countData), meta$sample), , drop=FALSE]

if (!all(meta$group %in% c("test","control"))) {
  stop("meta$group must be 'test' or 'control'")
}

group <- factor(meta$group, levels=c("control","test"))
design <- model.matrix(~group)

dge <- DGEList(countData)
keep <- filterByExpr(dge, design)
dge <- dge[keep,,keep.lib.sizes=FALSE]
dge <- calcNormFactors(dge)

logCPM <- cpm(dge, log=TRUE, prior.count=3)
fit <- lmFit(logCPM, design)
fit <- eBayes(fit, trend=TRUE)
x <- topTable(fit, coef=ncol(design), n=Inf)

x$gene_id <- rownames(x)
x <- x[, c("gene_id", setdiff(colnames(x), "gene_id"))]
write.table(x, opt$out, sep="\t", quote=FALSE, row.names=FALSE)
sessionInfo()
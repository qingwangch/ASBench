suppressPackageStartupMessages({
  library(edgeR)
  library(optparse)
})

opt_list <- list(
  make_option("--counts", type="character"),
  make_option("--meta",   type="character"),
  make_option("--out",    type="character", default="edger_ql_results.tsv")
)
opt <- parse_args(OptionParser(option_list=opt_list))

rawdata <- read.delim(opt$counts, row.names=1, check.names=FALSE)
meta    <- read.delim(opt$meta)

stopifnot(all(colnames(rawdata) %in% meta$sample))
meta <- meta[match(colnames(rawdata), meta$sample), , drop=FALSE]

# Enforce the exact structure from your provided code: 3 test + 3 control
if (!all(meta$group %in% c("test","control"))) {
  stop("meta$group must be 'test' or 'control'")
}
if (sum(meta$group=="test") != 3 || sum(meta$group=="control") != 3) {
  stop("This script expects exactly 3 test and 3 control samples (as in the provided code).")
}

group <- factor(meta$group, levels=c("control","test"))

y <- DGEList(counts = rawdata, genes = rownames(rawdata), group = group)
keep <- filterByExpr(y)
y <- y[keep,,keep.lib.sizes=FALSE]
y <- normLibSizes(y)
design <- model.matrix(~group)
y <- estimateDisp(y, design)
fit <- glmQLFit(y, design)
et <- glmQLFTest(fit)

# Your provided summary call
DEG_summary <- summary(de <- decideTests(et, adjust.method="BH", p.value=0.05, lfc=1))

# Export full table as well (useful for downstream)
tab <- topTags(et, n=Inf)$table
tab$gene_id <- rownames(tab)
tab <- tab[, c("gene_id", setdiff(colnames(tab), "gene_id"))]

write.table(tab, opt$out, sep="\t", quote=FALSE, row.names=FALSE)
writeLines(capture.output(DEG_summary), sub("\\.tsv$", "_DEG_summary.txt", opt$out))

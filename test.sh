nextflow run main.nf \
  -profile wehi \
  --samplesheet  /vast/projects/quartet_rna_refdata/github/ASBench/assets/samplesheet.template.csv \
  --star_index   /vast/projects/quartet_rna_refdata/ref_genome/star_index \
  --gtf          /vast/projects/quartet_rna_refdata/ref_transcriptome/gencode.v43.chr_patch_hapl_scaff.annotation.gtf \
  --prepde_py    /vast/projects/quartet_rna_refdata/github/ASBench/bin/prepDE.py \
  --outdir       /vast/projects/quartet_rna_refdata/github/ASBench/results_first_run \
  --star_mode    genome_geneCounts \
  -resume
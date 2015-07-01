#!/usr/bin/env Rscript
options(stringsAsFactors = FALSE)
library(modules) # Needed due to bug #44 in modules.
sys = modules::import('scripts/sys')

sys$run({
    codon_usage_files = sys$args

    codon_usage = lapply(codon_usage_files, readRDS)
    names(codon_usage) = sub('results/([^/]+)/.*', '\\1', codon_usage_files)

    library(dplyr)
    rcu = modules::import('./gene_set_rcu')

    correlations = lapply(codon_usage, function (codon_usage) {
        background_rcu = rcu$rcu(codon_usage)
        codons_count = length(unique(codon_usage$Codon))
        genes_count = nrow(codon_usage) / codons_count
        codon_indices = (seq.int(codons_count) - 1) * genes_count
    })


    writeLines(sprintf('%f', correlations), outfile)
    NULL
})

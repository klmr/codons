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

    # # #
    FIXME How to generate random set of genes, identical for each species?
    Orthologous genes again …
    # # #

    correlations = lapply(codon_usage, function (codon_usage) {
        background_rcu = rcu$rcu(codon_usage)
        codons_count = length(unique(codon_usage$Codon))
        genes_count = nrow(codon_usage) / codons_count
        codon_indices = (seq.int(codons_count) - 1) * genes_count
    })


    correlations = replicate(iterations, {
        random_gene_indices = sample.int(genes_count, 10)
        all_codons_of_random_genes = unlist(lapply(random_gene_indices, function (i) codon_indices + i))
        random_rcu = rcu$rcu(codon_usage[all_codons_of_random_genes, ])
        cor(background_rcu$Ratio, random_rcu$Ratio)
    })

    writeLines(sprintf('%f', correlations), outfile)
    NULL
})

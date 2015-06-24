#!/usr/bin/env Rscript
options(stringsAsFactors = FALSE)
library(modules) # Needed due to bug #44 in modules.
sys = modules::import('scripts/sys')

force_arg = function (pos, msg, error_code = 1) {
    arg = sys$args[pos]
    if (is.na(arg))
        sys$exit(error_code, msg)
    arg
}

sys$run({
    codon_usage_file = force_arg(1, 'No codon usage filename provided')
    gene_set_size = as.numeric(force_arg(2, 'No gene set size provided'))
    iterations = as.numeric(force_arg(3, 'No number of iterations provided'))
    outfile = force_arg(4, 'No output filename provided')

    rcu = modules::import('./gene_set_rcu')
    codon_usage = readRDS(codon_usage_file)

    library(dplyr)

    background_rcu = rcu$rcu(codon_usage)

    codons_count = length(unique(codon_usage$Codon))
    genes_count = nrow(codon_usage) / codons_count
    codon_indices = (seq.int(codons_count) - 1) * genes_count

    correlations = replicate(iterations, {
        random_gene_indices = sample.int(genes_count, 10)
        all_codons_of_random_genes = unlist(lapply(random_gene_indices, function (i) codon_indices + i))
        random_rcu = rcu$rcu(codon_usage[all_codons_of_random_genes, ])
        cor(background_rcu$Ratio, random_rcu$Ratio)
    })

    writeLines(sprintf('%f', correlations), outfile)
    NULL
})

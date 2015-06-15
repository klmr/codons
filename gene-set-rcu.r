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

rcu = function (codon_usage)
    codon_usage %>%
    group_by(AA, Codon) %>%
    summarize(Count = sum(Count)) %>%
    mutate(Ratio = Count / sum(Count)) %>%
    ungroup()

sys$run({
    codon_usage_file = force_arg(1, 'No codon usage filename provided')
    gene_set_file = force_arg(2, 'No gene set filename provided')
    outfile = force_arg(3, 'No output filename provided')

    library(dplyr)

    codon_usage = readRDS(codon_usage_file)
    gene_set = readLines(gene_set_file)

    background_rcu = rcu(codon_usage)
    rcu = rcu(filter(codon_usage, Gene %in% gene_set))

    correlation = cor(background_rcu$Ratio, rcu$Ratio)
    writeLines(sprintf('%f', correlation), outfile)
    NULL
})

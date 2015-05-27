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
    gene_set_file = force_arg(2, 'No gene set filename provided')
    outfile = force_arg(3, 'No output filename provided')

    codon_usage = readRDS(codon_usage_file)
    gene_set = readLines(gene_set_file)

    NULL
})

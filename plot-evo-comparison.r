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
    infile = force_arg(1, 'No input filename provided')
    outfile = force_arg(2, 'No output filename provided')
    library(dplyr)
    io = import('ebits/io')

    data = io$read_table(infile, header = TRUE) %>%
        mutate(GO0000087 = -GO0000087) %>%
        reshape2::melt(id.vars = 'Species', variable.name = 'GO', value.name = 'Correlation')

    # Order of time of divergence.

    species = c('mus_musculus',
                'rattus_norvegicus',
                'homo_sapiens',
                'macaca_mulatta',
                'canis_familiaris',
                'monodelphis_domestica')
    data$Species = factor(data$Species, levels = species, ordered = TRUE)

    library(ggplot2)

    on.exit(dev.off())
    pdf(outfile)
    ggplot(data, aes(x = Species, xend = Species, y = 0, yend = Correlation)) +
        geom_segment(size = 5) +
        coord_flip() +
        theme_bw()
    NULL
})

#!/usr/bin/env Rscript

library(modules, warn.conflicts = FALSE, quietly = TRUE)
sys = import('sys')

plot_te = function (data, summary) {
    import_package('ggplot2', attach = TRUE)

    data$Which = factor(data$Which,
                        levels = c('All', 'Upregulated', 'GO', 'Housekeeping', 'Ribosomal', 'Proliferation'),
                        ordered = TRUE)

    plot = ggplot(data, aes(x = Mode, y = TE)) +
        (if (summary)
            geom_boxplot(width = 0.4)
        else
            geom_boxplot(width = 0.2, outlier.size = 0)) +
        scale_y_continuous(limits = c(0.1, 0.85)) +
        facet_wrap(~ Which, nrow = 1) +
        theme_bw()

    if (summary)
        plot
    else {
        import_package('ggbeeswarm', attach = TRUE)
        plot +
            geom_point(aes(color = mRNA, shape = tRNA),
                       position = position_beeswarm()) +
            scale_color_manual(limits = names(config$celltype_colors),
                               values = config$celltype_colors) +
            scale_shape_manual(limits = names(config$celltype_colors),
                               values = c(15, 4, 5, 16))
    }
}

mean_center = function (all_te) {
    import_package('dplyr', attach = TRUE)
    trna_zscores = all_te %>%
        filter(Mode == 'Match') %>%
        group_by(Which) %>%
        mutate(AllMedian = median(TE)) %>%
        group_by(tRNA, add = TRUE) %>%
        mutate(tRNAMedian = median(TE)) %>%
        summarize(Scaling = first(tRNAMedian / AllMedian))

    inner_join(all_te, trna_zscores, by = c('Which', 'tRNA')) %>%
        mutate(TE = TE / Scaling)
}

sys$run({
    valid_te_methods = c('simple-te', 'wobble-te', 'tai')
    args = sys$cmdline$parse(opt('t', 'te',
                                 do.call(sprintf,
                                         c('the method to calculate translation efficiency (%s, %s or %s)',
                                           lapply(valid_te_methods, dQuote))),
                                 valid_te_methods[1],
                                 function (x) x %in% valid_te_methods),
                             opt('c', 'mean-center', 'center tRNA strata before plotting?', FALSE),
                             opt('s', 'summary', 'plot summary rather than detailed points?', FALSE),
                             opt('i', 'ramp-up', 'use codons at start of transcript (“ramp up”) only', FALSE),
                             arg('species', 'the species'),
                             arg('outfile', 'the filename of the PDF output'))

    config = import(sprintf('../config_%s', args$species))
    te = readRDS(sprintf('results/%s%s-%s.rds',
                         if (args$ramp_up) 'init-' else '',
                         args$te, args$species))
    if (args$mean_center)
        te = mean_center(te)

    # Required by ggplot2, see <https://github.com/hadley/ggplot2/issues/1384>
    library(methods)
    on.exit(dev.off())
    pdf(args$outfile)
    plot(plot_te(te, args$summary))
})

# vim: ft=r

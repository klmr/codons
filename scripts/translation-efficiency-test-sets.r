define_contrasts = function (config) {
    all_celltypes = unique(data$mrna_design(config)$Celltype)
    healthy_celltypes = intersect(all_celltypes, c('Liver-Adult', 'E15.5'))
    cancer_celltypes = setdiff(all_celltypes, healthy_celltypes)
    all_contrasts = expand.grid(Codon = unique(all_celltypes),
                                Anti = unique(all_celltypes),
                                stringsAsFactors = FALSE)
    matching_contrasts = filter(all_contrasts, Codon == Anti)
    mismatching_contrasts = all_contrasts %>%
        filter(Codon != Anti,
               Codon %in% healthy_celltypes |
               Anti %in% healthy_celltypes)

    globalenv = parent.env(environment())
    invisible(lapply(ls(), function (n) assign(n, get(n), globalenv)))
}

#' Get all pairwise replicate library identifiers for a given contrast.
expand_contrast = function (contrast) {
    mrna_samples = filter(data$mrna_design(config), Celltype == contrast[1])$DO
    trna_samples = filter(data$trna_design(config), Celltype == contrast[2])$DO
    as.data.frame(t(expand.grid(mrna_samples, trna_samples)))
}

#' Get all pairwise replicate libraries for a set of contrasts.
expand_test_sets = function (contrasts) {
    contrasts = as.data.frame(t(contrasts))
    unname(bind_cols(lapply(contrasts, expand_contrast)))
}

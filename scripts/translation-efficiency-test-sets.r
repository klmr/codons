define_relations = function (config) {
    all_celltypes = unique(data$mrna_design(config)$Celltype)
    healthy_celltypes = intersect(all_celltypes, c('Liver-Adult', 'E15.5'))
    cancer_celltypes = setdiff(all_celltypes, healthy_celltypes)
    all_relations = expand.grid(Codon = unique(all_celltypes),
                                Anti = unique(all_celltypes),
                                stringsAsFactors = FALSE)
    matching_relations = filter(all_relations, Codon == Anti)
    mismatching_relations = all_relations %>%
        filter(Codon != Anti,
               Codon %in% healthy_celltypes |
               Anti %in% healthy_celltypes)

    globalenv = parent.env(environment())
    invisible(lapply(ls(), function (n) assign(n, get(n), globalenv)))
}

#' Get all pairwise replicate library identifiers for a given relation.
expand_relation = function (relation) {
    mrna_samples = filter(data$mrna_design(config), Celltype == relation[1])$DO
    trna_samples = filter(data$trna_design(config), Celltype == relation[2])$DO
    as.data.frame(t(expand.grid(mrna_samples, trna_samples)))
}


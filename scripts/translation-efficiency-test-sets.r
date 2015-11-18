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

#' Create gene sets of a given condition
#'
#' @param condition name of the condition
#' @return Returns a set of sets of gene IDs.
whole_transcriptome = function (condition)
    list(unique(cu$Gene))

#' 
#' \code{upregulated_genes} returns the set of sets of upregulated gene IDs for
#' each contrast involving \code{condition}.
#' @return \code{upregulated_genes} returns the set of sets of upregulated
#' gene IDs for each contrast involving \code{condition}.
#' @rdname whole_transcriptome
upregulated_genes = local({
    # FIXME: This is a mess, do proper filtering. My brain is fried.
    upregulated_genes = readRDS(sprintf('results/de/up-%s.rds', config$species))
    de_contrast_selection = names(upregulated_genes) %>%
        {grep('Liver-Adult|E15\\.5', .)}
    upregulated_genes = upregulated_genes[de_contrast_selection]

    function (condition) {
        # The genes are upregulated in the second condition of the contrast.
        indices = grep(sprintf('/%s', condition), names(upregulated_genes))
        upregulated_genes[indices]
    }
})

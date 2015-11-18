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

#' Calculate the translation efficiency comparison for a given relation
#'
#' @param mrna_condition name of condition from which to take mRNA genes
#' @param trna_condition name of condition from which to take tRNA pool
#' @param which_genes function taking a condition that returns the appropriate
#' gene set
#' @param te function to calculate the TE
#' @return Returns a vector of TEs for all pairwise replicate comparisons of the
#' given gene set and condition.
#' @details
#' \code{which_genes} is a function taking a single argument, the mRNA contrast.
#' \code{te} is a function taking two arguments, the codon and anticodon
#' pool.
gene_set_translation_efficiency = function (mrna_condition, trna_condition, which_genes, te) {
    gene_set_codons = function (gene_set, lib)
        cu %>%
        filter(Gene %in% gene_set) %>%
        select_('Gene', 'Codon', 'CU', 'Length',
                Count = lazyeval::interp(~first(DO), DO = as.name(lib)))

    names_of = function (comparisons)
        lapply(comparisons, relation -> {
            rel_mrna_cond = filter(mrna_design, DO == relation[1])$Celltype
            rel_trna_cond = filter(trna_design, DO == relation[2])$Celltype
            paste(rel_mrna_cond, rel_trna_cond, '', sep = '/')
        })

    gene_sets = which_genes(mrna_condition)
    comparisons = expand_relation(c(mrna_condition, trna_condition))
    unlist(setNames(lapply(comparisons, relation -> {
        unname(lapply(gene_sets, gene_set -> {
            codons = gene_set_codons(gene_set, relation[1])
            anticodons = filter(aa, DO == relation[2])
            te(codons, anticodons)
        }))
    }), names_of(comparisons))) %>%
        # This removes the trailing number that `unlist` added to the name.
        setNames(sub('/\\d*$', '', names(.)))
}

simple_te = function (cu, aa)
    cu_$adaptation_no_wobble(mutate(cu, CU = CU * Count / Length),
                             aa, canonical_cds)

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

#!/usr/bin/env Rscript
options(stringsAsFactors = FALSE)
library(modules) # Needed due to bug #44 in modules.
sys = modules::import('scripts/sys')

ensembl_species = function (species) {
    # Species is Latin name, two words.
    short = tolower(sub('(.).* ', '\\1', species))
    paste0(short, '_gene_ensembl')
}

#' Download a set of ENSEMBL gene identifiers corresponding to a vector of
#' \code{gene_names} for a given \code{species}.
#' @param species the species name
#' @param gene_names vector of gene names
#' @note Filter out filter out haplotype variants (weird chromosome names).
download_gene_ids = function (species, gene_names) {
    biomart = loadNamespace('biomaRt')
    ens_mart = biomart$useMart('ensembl', ensembl_species(species))
    query_attributes = c('ensembl_gene_id', 'external_gene_name', 'chromosome_name')
    biomart$getBM(attributes = query_attributes,
                  filters = 'external_gene_name',
                  values = gene_names,
                  mart = ens_mart) %>%
        dplyr::filter(grepl('^(\\d\\d?|[XYM]|Mt)$', chromosome_name)) %>%
        dplyr::select(-chromosome_name)
}

#' @param gene_sets a named list of \code{data.frame}s with columns
#'  \code{ensembl_gene_id} and \code{external_gene_name}
gene_set_intersection = function (gene_sets) {
    make_gene_names_comparable = function (x)
        dplyr::mutate(x, external_gene_name = toupper(external_gene_name))

    gene_sets = lapply(gene_sets, make_gene_names_comparable)

    join = function (x, y)
        dplyr::inner_join(x, y, by = 'external_gene_name')

    Reduce(join, gene_sets[-1], gene_sets[[1]]) %>%
        dplyr::select(-external_gene_name) %>%
        set_colnames(names(gene_sets))
}

sys$run({
    gene_set_file = sys$args[1]
    if (is.na(gene_set_file))
        sys$exit(1, 'No gene set filename provided')

    species = sys$args[-1]
    if (length(species) == 0)
        sys$exit(1, 'No species name provided')

    library(magrittr)

    gene_names = readLines(gene_set_file)
    gene_sets = lapply(species, download_gene_ids, gene_names)
    joint_set = gene_set_intersection(gene_sets)

    io = import('ebits/io')
    io$write_table(joint_set, stdout())
})

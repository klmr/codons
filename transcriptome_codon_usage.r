#!/usr/bin/env Rscript
options(stringsAsFactors = FALSE)
library(modules) # Needed due to bug #44 in modules.
sys = modules::import('scripts/sys')

#' Efficient \code{rbind} with matching column names
#'
#' Effectively performs \code{do.call(rbind, data)} but more efficiently, and
#' taking care to correctly match column names.
#' @param data list of named vectors
#' @note This is effectively similar to \\code{dplyr::bind_rows} but the
#' argument doesn’t need to consist of \code{data.frame}s.
rbind_matching = function (data) {
    all_colnames = do.call(rbind, lapply(data, names))
    unique_colnames = unique(as.vector(all_colnames))
    col_indices = apply(all_colnames, 1, x -> match(unique_colnames, x))
    reordered = lapply(seq_along(data), i -> data[[i]][col_indices[, i]])
    `colnames<-`(do.call(rbind, reordered), unique_colnames)
}

parse_cds_header = function (data) {
    tokens = strsplit(data, ' ')
    # The format does not specify whether the following columns are always in
    # the same order so we do not make this assumption here.
    ids = unlist(lapply(tokens, x -> x[[1]]))
    result = tokens %>%
        lapply(x -> x[-1]) %>%
        lapply(x -> stringi::stri_split_fixed(x, ':', 2)) %>%
        lapply(x -> unlist(lapply(x, y -> setNames(y[2], y[1])))) %>%
        rbind_matching()

    as.data.frame(cbind(Transcript = ids, result)) %>%
        # Special treatment for the Chromosomes column.
        mutate(Chr = vapply(stringi::stri_split_fixed(chromosome, ':'),
                                   function (x) x[2], character(1))) %>%
        select(Gene = gene,
               Transcript = Transcript,
               Chr = Chr,
               Biotype = transcript_biotype)
}

sys$run({
    infile = sys$args[1]
    if (is.na(infile))
        sys$exit(1, 'No input filename provided')

    outfile = sys$args[2]
    if (is.na(outfile))
        sys$exit(1, 'No output filename provided')

    library(dplyr)
    base = modules::import('ebits/base')

    bios = loadNamespace('Biostrings')
    cds = bios$readDNAStringSet(infile)

    metadata = parse_cds_header(names(cds))

    # Use only protein-coding transcripts on autosomal nuclear chromosomes.
    # Sanity check that transcript is actually a valid CDS
    # Compute the canonical transcript as the longest transcript.

    is_numeric = function (str) suppressWarnings(! is.na(as.numeric(str)))

    is_valid_cds = function (seq)
        nchar(seq) %% 3 == 0 & grepl('^ATG', seq) & grepl('(TAG|TAA|TGA)$', seq)

    canonical_cds = cbind(metadata, Sequence = as.character(cds)) %>%
        tbl_df() %>%
        filter(Biotype == 'protein_coding') %>%
        filter(is_numeric(Chr)) %>%
        filter(is_valid_cds(Sequence)) %>%
        group_by(Gene) %>%
        arrange(desc(nchar(Sequence))) %>%
        slice(1)

    genetic_code = as.data.frame(bios$GENETIC_CODE) %>%
        add_rownames() %>%
        select(Codon = 1, AA = 2) %>%
        filter(AA != '*')

    codon_usage = canonical_cds$Sequence %>%
        bios$DNAStringSet() %>%
        bios$trinucleotideFrequency(3) %>%
        as.data.frame() %>%
        {cbind(Gene = canonical_cds$Gene, .)} %>%
        reshape2::melt(id.vars = 'Gene', variable.name = 'Codon', value.name = 'Count') %>%
        inner_join(genetic_code, by = 'Codon') %>%
        tbl_df()

    saveRDS(codon_usage, outfile)
})

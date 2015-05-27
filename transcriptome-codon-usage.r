#!/usr/bin/env Rscript
library(modules) # Needed due to bug #44 in modules.
sys = modules::import('scripts/sys')
base = modules::import('ebits/base')

#' Efficient \code{rbind} with matching column names
#'
#' Effectively performs \code{do.call(rbind, data)} but more efficiently, and
#' taking care to correctly match column names.
#' @param data list of named vectors
#' @note This is effectively similar to \\code{dplyr::bind_rows} but the
#' argument doesn’t need to consist of \code{data.frame}s.
rbind_matching = function (data) {
    colnames = names(data[[1]])
    rest = data[-1]
    all_colnames = do.call(rbind, lapply(rest, names))
    col_indices = apply(all_colnames, 1, match, colnames)
    reordered = lapply(seq_along(rest), i -> rest[[i]][col_indices[, i]])
    do.call(rbind, c(data[1], reordered))
}

parse_header = function (data) {
    tokens = strsplit(data, ' ')
    # The format does not specify whether the following columns are always in
    # the same order so we do not make this assumption here.
    ids = unlist(lapply(tokens, x -> x[[1]]))
    result = tokens %>%
        lapply(x -> x[-1]) %>%
        lapply(x -> stringi::stri_split_fixed(x, ':', 2)) %>%
        lapply(x -> unlist(lapply(x, y -> setNames(y[2], y[1])))) %>%
        rbind_matching()

    as.data.frame(cbind(ID = ids, result))
}

sys$run({
    filename = sys$args[1]
    if (is.na(filename))
        sys$exit(1)

    bios = loadNamespace('Biostrings')
    cds = bios$readDNAStringSet(filename)

    metadata = parse_header(names(cds))

    # Use only protein-coding transcripts.

    # Sanity check that transcript is actually a valid CDS

    # Compute the canonical transcript as the longest transcript.
})

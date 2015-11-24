deseq = modules::import_package('DESeq2')
piano = modules::import_package('piano')
modules::import_package('dplyr', attach = TRUE)

#' @export
prepare_gene_set = function (gene_set)
    piano$loadGSC(gene_set, 'data.frame')

#' @export
gsa_de = function (data, col_data, contrast, go_genes) {
    stopifnot(inherits(go_genes, 'GSC'))
    data = untidy(select(data, Gene, starts_with('do')))
    col_data = untidy(col_data)

    # Annoyingly, we need to recalculate the DE genes here because we previously
    # only stored genes with evidence of DE, not all genes.
    de = deseq_test(data, col_data, contrast) %>%
        deseq$results() %>%
        as.data.frame() %>%
        {.[! is.na(.$padj), ]}
    stats = de[, 'padj', drop = FALSE]
    directions = de[, 'log2FoldChange', drop = FALSE]
    piano$runGSA(stats, directions, gsc = go_genes, verbose = FALSE)
}

#' @export
enriched_terms = function (data, direction = c('up', 'down'), alpha = 0.01) {
    direction = switch(direction, up = 'up', 'down' = 'dn',
                       stop('Invalid ', sQuote('direction')))
    modules::import_package('lazyeval', attach = TRUE)
    dir_col = as.name(sprintf('p adj (dist.dir.%s)', direction))

    piano$GSAsummaryTable(data) %>%
        filter_(interp(~ p < alpha, p = dir_col)) %>%
        select_('Name', padj = dir_col) %>%
        arrange(padj)
}

untidy = function (tidy_data, rownames = 1)
    `rownames<-`(as.data.frame(tidy_data[-rownames]), tidy_data[[rownames]])

deseq_test = function (data, col_data, contrast) {
    cols = rownames(col_data)[col_data[[1]] %in% contrast]
    col_data = col_data[cols, , drop = FALSE]
    # Ensure that the conditions are in the same order as `contrast`; that is,
    # the reference level corresponds to `contrast[1]`.
    # FIXME: DESeq2 bug causes this not to work, need to use relevel instead.
    #col_data[[1]] = factor(col_data[[1]], unique(col_data[[1]]), ordered = TRUE)
    data = data[, cols]
    design = eval(bquote(~ .(as.name(colnames(col_data)[1]))))
    dds = deseq$DESeqDataSetFromMatrix(data, col_data, design)
    GenomicRanges::colData(dds)[[1]] = relevel(GenomicRanges::colData(dds)[[1]],
                                               contrast[1])
    deseq$DESeq(dds, quiet = TRUE)
}

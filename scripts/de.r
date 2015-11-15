# Differential gene expression analysis

.deseq = modules::import_package('DESeq2')
.base = modules::import('ebits/base')
modules::import_package('dplyr', attach = TRUE)

untidy = function (tidy_data, rownames = 1)
    `rownames<-`(as.data.frame(tidy_data[-rownames]), tidy_data[[rownames]])

.deseq_test = function (data, col_data, contrast) {
    cols = col_data[[1]] %in% contrast
    col_data = col_data[cols, , drop = FALSE]
    data = data[, cols]
    design = eval(bquote(~ .(as.name(colnames(col_data)[1]))))
    dds = .deseq$DESeqDataSetFromMatrix(data, col_data, design)
    .deseq$DESeq(dds, quiet = TRUE)
}

de_genes = function (counts, design, contrasts, alpha = 0.001) {
    dds_data = untidy(select(counts, Gene, starts_with('do')))
    dds_col_data = untidy(design)
    dds_col_data = dds_col_data[colnames(dds_data), , drop = FALSE]
    # Ensure Liver-Adult is condition A in the contrast, or, if not present,
    # then E15.5 is.
    healthy_celltypes = intersect(unique(design$Celltype),
                                  c('Liver-Adult', 'E15.5'))
    dds_col_data$Celltype = Reduce(relevel, rev(healthy_celltypes),
                                   factor(dds_col_data$Celltype))
    parallel = import_package('parallel')
    dds = parallel$mclapply(contrasts, .deseq_test,
                            data = dds_data, col_data = dds_col_data,
                            mc.cores = parallel$detectCores())
    lapply(dds, dds -> as.data.frame(.deseq$results(dds)) %>%
                       subset(! is.na(padj) & padj < alpha) %>%
                       add_rownames('Gene')) %>%
        setNames(vapply(contrasts, paste, character(1), collapse = '/'))
}

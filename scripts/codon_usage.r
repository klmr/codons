# Calculate codon usage and other statistics for gene sets.
# For the terminology used in this module, please see
#
#   Konrad Rudolph, “Investigating the link between tRNA and mRNA abundance in mammals”,
#   2015 (PhD thesis). Chapter 1.6 “Quantifying codon usage and anticodon abundance”
#

.bios = modules::import_package('Biostrings')
modules::import_package('dplyr', attach = TRUE)
modules::import_package('reshape2', attach = TRUE)

genetic_code = data.frame(AA = .bios$GENETIC_CODE) %>%
    add_rownames('Codon')

stop_codons = filter(genetic_code, AA == '*')$Codon

#' Calculate codon usage for gene set
#'
#' @param genes the DNA sequences (see \link{Details})
#' @return Tidy table of per-gene codon usage.
#' @details \code{genes} is either a named character vector or a
#' \code{\link{data.frame}} of \code{Gene}–\code{Sequence} pairs, or a
#' \code{\link[Biostrings]{DNAStringSet}}.
cu = function (genes) UseMethod('cu')

cu.default = function (genes) {
    stopifnot(is.character(genes))
    cu(.bios$DNAStringSet(genes))
}

cu.data.frame = function (genes)
    cu(.bios$DNAStringSet(setNames(genes$Sequence, genes$Gene)))

cu.DNAStringSet = function (genes)
    .bios$trinucleotideFrequency(genes, 3) %>%
    as.data.frame() %>%
    {cbind(Gene = names(genes), .)} %>%
    melt(id.vars = 'Gene', variable.name = 'Codon', value.name = 'CU') %>%
    mutate(Codon = as.character(Codon)) %>%
    filter(! Codon %in% stop_codons) %>%
    tbl_df() %>%
    `class<-`(c('codon_usage$cu', class(.)))

#' Calculate relative codon usage for gene set
#'
#' @param x gene set (see \link{Details})
#' @return Tidy table of per-gene relative codon usage.
#' @details The accepted input corresponds to either the output of
#' \code{\link{cu}}, or any input that function accepts.
rcu = function (x) UseMethod('rcu')

`rcu.codon_usage$cu` = function (x)
    inner_join(x, genetic_code, by = 'Codon') %>%
    group_by(Gene, AA) %>%
    mutate(RCU = CU / sum(CU)) %>%
    ungroup() %>%
    `class<-`(c('codon_usage$rcu', class(.)))

rcu.default = function (x)
    rcu(cu(x))

adaptation = function (rcu, raa, method = adaptation_no_wobble)
    method(rcu, raa)

adaptation_no_wobble = function (rcu, raa)
    inner_join(rcu, raa, by = 'Codon') %>%
    summarize(Adaptation = cor(RCU, RAA, method = 'spearman'))

make_adaptation_tai = function (...) {
    # TODO: Implement
    function (rcu, raa) {}
}

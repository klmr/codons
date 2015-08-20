# Calculate codon usage and other statistics for gene sets.
# For the terminology used in this module, please see
#
#   Konrad Rudolph, “Investigating the link between tRNA and mRNA abundance in mammals”,
#   2015 (PhD thesis). Chapter 1.6 “Quantifying codon usage and anticodon abundance”
#

.bios = modules::import_package('Biostrings')
modules::import_package('dplyr', attach = TRUE)
modules::import_package('reshape2', attach = TRUE)

#' The genetic code
genetic_code = data.frame(AA = .bios$GENETIC_CODE) %>%
    add_rownames('Codon') %>%
    tbl_df()

#' Vector of stop codons
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
rcu = function (x, column = Gene)
    rcu_(x, deparse(substitute(column)))

rcu_ = function (x, column = 'Gene') UseMethod('rcu_')

`rcu_.codon_usage$cu` = function (x, column = 'Gene')
    inner_join(x, genetic_code, by = 'Codon') %>%
    group_by_(.dots = c(column, 'AA')) %>%
    mutate(RCU = CU / sum(CU)) %>%
    ungroup() %>%
    `class<-`(c('codon_usage$rcu', class(.)))

rcu_.default = function (x, column = 'Gene')
    rcu_(cu(x), column)

#' Calculate adaptation between codons and tRNA
#'
#' Calculate the correlation between codon usage and anticodon abundance as a
#' measure of goodness of adaptation of the anticodon supply to the codon
#' demand.
#'
#' @param rcu Relative codon usage as given by \code{rcu}
#' @param raa Relative anticodon abundance, with \code{Codon} column
#' @note \code{raa} is equivalent to \code{rcu} for the abundance of anticodons.
#' The function expects this to be given with reverse complemented anticodons,
#' so that the format of the data is equivalent for \code{rcu} and \code{raa}.
adaptation = function (rcu, raa, method = adaptation_no_wobble)
    method(rcu, raa)

#' Simple codon–anticodon adaptation, ignoring wobble base pairing.
adaptation_no_wobble = function (rcu, raa)
    inner_join(rcu, raa, by = 'Codon') %>%
    summarize(Adaptation = cor(RCU, RAA, method = 'spearman'))

make_adaptation_tai = function (...) {
    # TODO: Implement
    function (rcu, raa) {}
}

#' Normalize codon usage
#'
#' Normalizing codon usage ensures that the codon usage sums to 1, in other
#' words, calculate \code{n[i] = x[i] / sum(x)}.
#' @param x codon usage in tidy data format
#' @return The normalized codon usage in tidy data format.
norm = function (x) UseMethod('norm')

`norm.codon_usage$cu` = function (x)
    mutate(x, CU = CU / sum(CU))

`norm.codon_usage$rcu` = function (x) {
    warning('Normalizing RCU makes no sense, skipped.')
    x
}

#' Reverse complement a set of sequences
#'
#' @param seq a character vector
#' @return A character vector of the reverse complemented sequences.
revcomp = function (seq)
    as.character(.bios$reverseComplement(.bios$DNAStringSet(seq)))

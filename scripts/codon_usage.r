# Calculate codon usage and other statistics for gene sets.
# For the terminology used in this module, please see
#
#   Konrad Rudolph, “Investigating the link between tRNA and mRNA abundance in mammals”,
#   2015 (PhD thesis). Chapter 1.6 “Quantifying codon usage and anticodon abundance”
#

.bios = modules::import_package('Biostrings')
modules::import_package('dplyr', attach = TRUE)
tidyr = modules::import_package('tidyr')

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
    mutate(Gene = names(genes)) %>%
    tidyr$gather(Codon, CU, -Gene) %>%
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
    mutate(RCU = ifelse(is.nan(RCU), 0, RCU)) %>%
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
#' @param cu codon usage as given by \code{cu}
#' @param aa anticodon abundance, with \code{Codon} column
#' @param cds coding sequences
#' @note \code{raa} is equivalent to \code{rcu} for the abundance of anticodons.
#' The function expects this to be given with reverse complemented anticodons,
#' so that the format of the data is equivalent for \code{cu} and \code{aa}.
adaptation = function (cu, aa, cds, method = adaptation_no_wobble)
    method(cu, aa, cds)

#' \code{adaptation_no_wobble} computes a simple codon–anticodon correlation,
#' ignoring wobble base pairing.
#' @rdname adaptation
adaptation_no_wobble = function (cu, aa, cds)
    cu %>%
    group_by(Codon, add = TRUE) %>%
    summarize(CU = sum(CU)) %>%
    inner_join(aa, by = 'Codon') %>%
    mutate(CU = CU / sum(CU),
           AA = AA / sum(AA)) %>%
    summarize(Cor = cor(CU, AA, method = 'spearman')) %>%
    .$Cor

wobble_pairing = import('./wobble_pairing')

#' \code{adaptation_wobble} computes a codon–anticodon correlation while
#' accounting for wobble base pairing.
adaptation_wobble = function (cu, aa, cds)
    cu %>% do(Cor = wobble_pairing$adaptation(., aa)) %>% .$Cor %>% unlist()

# Calculate outside function for speed — `adaptation` is called very frequently.
coding_codons = setdiff(genetic_code$Codon, stop_codons)
tai = import('./tai')

#' \code{adaptation_tai} computes the tRNA adaptation index.
#' @param s tAI s-values
#' @rdname adaptation
adaptation_tai = function (cu, aa, cds, s = tai$naive_s) {
    lengths = setNames(cds$Length, cds$Gene)[unique(cu$Gene)]
    cu = tidyr$spread(cu, Codon, CU) %>% select(one_of(coding_codons))
    aa = setNames(aa$AA, aa$Codon)
    tai$tai(cu, tai$w(aa, s), lengths)
}

#' Normalize codon usage
#'
#' Normalizing codon usage ensures that the codon usage sums to 1, in other
#' words, calculate \code{n[i] = x[i] / sum(x)}.
#' @param x codon usage in tidy data format
#' @return The normalized codon usage in tidy data format.
norm = function (x) UseMethod('norm')

`norm.codon_usage$cu` = function (x)
    mutate(x, CU = CU / sum(CU)) %>%
    `class<-`(c('codon_usage$cu', class(.)))

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

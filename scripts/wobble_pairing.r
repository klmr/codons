tai = import('./tai')

# Rules for wobble pairing
# Codon   Anti        i % 4  wobble_match_index
# TTT --- AAA (1, 2)  1      1
#      X/
# TTC -/- GAA (1, 2)  2     -1
#     /
# TTA --- TAA (1, 3)  3     -2
#      /
# TTG --- CAA (3, 4)  0     -1
rc_anticodons = data.frame(Codon = tai$rc_anticodons) %>%
    mutate(Order = seq_along(Codon))

#' Adaptation between codon and anticodon abundanc
#'
#' Calculate the adaptation as the rank correlation between codon and anticodon
#' abundance. The abundance of non-existent anticodons is replaced by the
#' abundance of the alternative decoding anticodon for the matching codon.
#' When the exactly matching anticodon exists, wobble base pairing anticodons
#' are not considered. This relies on the (inaccurate) assumption that
#' matching anticodons will generally out-compete wobble matching anticodons
#' at the ribosome.
adaptation = function (cu, aa) {
    wobble_match_index = function (i)
        i + c(-1, 1, -1, -2)[i %% 4 + 1]

    data = cu %>%
        group_by(Codon) %>%
        summarize(CU = mean(CU)) %>%
        full_join(aa, by = 'Codon') %>%
        full_join(rc_anticodons, by = 'Codon') %>%
        arrange(Order)
    unmatched_codon_indices = which(is.na(data$AA))
    wobble_codon_indices = unlist(lapply(unmatched_codon_indices,
                                         wobble_match_index))

    data[unmatched_codon_indices, 'AA'] = data[wobble_codon_indices, 'AA']
    data %>%
        filter(! is.na(CU)) %>%
        mutate(CU = CU / sum(CU),
               AA = AA / sum(AA)) %>%
        summarize(Cor = cor(CU, AA, use = 'complete.obs', method = 'spearman')) %>%
        .$Cor
}

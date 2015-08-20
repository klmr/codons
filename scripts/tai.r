# Based on the paper by Dos Reis & al, 2004

s = list(naive = c(0, 0, 0, 0, 0.5, 0.5, 0.75, 0.5, 0.5, 0.5),
         ecoli = c(0, 0, 0, 0, 0.41, 0.28, 0.9999, 0.68, 0.89))

get_s = function (species)
    if (species %in% names(s)) s[[species]] else s$naive

# Reverse complement of the anticodons, in the order of anticodons as given in
# Figure 1 of dos Reis & al.
rc_anticodons = c('TTT', 'TTC', 'TTA', 'TTG',
                  'TCT', 'TCC', 'TCA', 'TCG',
                  'TAT', 'TAC', 'TAA', 'TAG',
                  'TGT', 'TGC', 'TGA', 'TGG',

                  'CTT', 'CTC', 'CTA', 'CTG',
                  'CCT', 'CCC', 'CCA', 'CCG',
                  'CAT', 'CAC', 'CAA', 'CAG',
                  'CGT', 'CGC', 'CGA', 'CGG',

                  'ATT', 'ATC', 'ATA', 'ATG',
                  'ACT', 'ACC', 'ACA', 'ACG',
                  'AAT', 'AAC', 'AAA', 'AAG',
                  'AGT', 'AGC', 'AGA', 'AGG',

                  'GTT', 'GTC', 'GTA', 'GTG',
                  'GCT', 'GCC', 'GCA', 'GCG',
                  'GAT', 'GAC', 'GAA', 'GAG',
                  'GGT', 'GGC', 'GGA', 'GGG')

met_codon = match('ATG', rc_anticodons)
stop_codons = match(c('TAA', 'TAG', 'TGA'), rc_anticodons)

ws = function () {
}

tai = function (codon_counts, w, lengths) {
    codons = rc_anticodons[-stop_codons]
    exp(colSums(apply(codon_counts[, codons], 1, `*`, log(w))) / lengths)
}

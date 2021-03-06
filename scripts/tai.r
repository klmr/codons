# Based on the paper by Dos Reis & al, 2004

naive_s = c(0, 0, 0, 0, 0.5, 0.5, 0.75, 0.5)

find_optimal_s = function (codon_usage, expression, lengths, trna) {
    f = function (s)
        cor(tai(codon_usage, w(trna, c(0, 0, 0, 0, exp(s))), lengths),
            expression,
            method = 'spearman')

    # Fix first four values, optimize rest.
    # Optimize `log(s)` to avoid getting negative values into `s`.
    par = log(naive_s[-(1 : 4)])
    within(optim(par, f, control = list(fnscale = -1)),
           {par = c(0, 0, 0, 0, exp(par))})
}

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

w = function (counts, s = naive_s) {
    counts = counts[rc_anticodons]
    counts[is.na(counts)] = 0
    p = 1 - s
    w = vector('numeric', length(counts))

    for (i in seq(1, length(counts), by = 4)) {
        w[i]     = p[1] * counts[i]     + p[5] * counts[i + 1]
        w[i + 1] = p[2] * counts[i + 1] + p[6] * counts[i]
        w[i + 2] = p[3] * counts[i + 2] + p[7] * counts[i]
        w[i + 3] = p[4] * counts[i + 3] + p[8] * counts[i + 2]
    }

    w[met_codon] = p[4] * counts[met_codon]
    w = w[-stop_codons]
    w_rel = w / max(w)
    nonzero_w = w_rel[w != 0]
    if (length(nonzero_w) != length(w_rel))
        w_rel[w_rel == 0] = exp(sum(log(nonzero_w)) / length(nonzero_w))

    w_rel
}

tai = function (codon_counts, w, lengths) {
    codons = rc_anticodons[-stop_codons]
    exp(colSums(apply(codon_counts[, codons], 1, `*`, log(w))) / lengths)
}

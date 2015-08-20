# Based on the paper by Dos Reis & al, 2004

s = list(naive = c(0, 0, 0, 0, 0.5, 0.5, 0.75, 0.5, 0.5, 0.5),
         human = c(0, 0, 0, 0, 0.41, 0.28, 0.9999, 0.68, 0.89))

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

tai = function () {
}

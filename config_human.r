species = 'human'
trna_counts = './data/trna-counts-hs38.tsv'
trna_annotation = './data/Homo_sapiens.GRCh38.dna.primary_assembly.trna.filtered.out'
trna_design = './data/libraries-trna-chip-hs38.tsv'
norm_counts = './results/trna-norm-counts-hs38.tsv'
contrasts = list(c('Liver-Adult', 'Huh7'),
                 c('Liver-Adult', 'HepG2'),
                 c('Huh7', 'HepG2'))

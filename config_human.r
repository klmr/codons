species = 'human'
counts = './data/trna-counts-hs38.tsv'
annotation = './data/Homo_sapiens.GRCh38.dna.primary_assembly.trna.filtered.out'
design = './data/libraries-trna-chip-hs38.tsv'
norm_counts = './results/trna-norm-counts-hs38.tsv'
contrasts = list(c('liver', 'Huh7'),
                 c('liver', 'HepG2'),
                 c('Huh7', 'HepG2'))

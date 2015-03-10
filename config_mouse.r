species = 'mouse'
counts = './data/trna-counts-mm10.tsv'
annotation = './data/tRNA_Scan_Mus_musculus.GRCm38.69_301014.filtered.out'
design = './data/libraries-trna-chip-mm10.tsv'
norm_counts = './results/trna-norm-counts-mm10.tsv'
contrasts = list(c('liver', 'Hepa1-6'),
                 c('liver', 'Hepa1c1c7'),
                 c('Hepa1-6', 'Hepa1c1c7'))

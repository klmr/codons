species = 'mouse'
trna_counts = './data/trna-counts-mm10.tsv'
mrna_counts = './data/rnaseq-counts-mm10.tsv'
trna_annotation = './data/tRNA_Scan_Mus_musculus.GRCm38.69_301014.filtered.out'
mrna_annotation = './data/Mus_musculus.GRCm38.75.gene_annot.tsv'
cds = './data/Mus_musculus.GRCm38.cds.all.fa.gz'
trna_design = './data/libraries-trna-chip-mm10.tsv'
mrna_design = './data/libraries-rna-seq-mm10.tsv'
norm_counts = './results/trna-norm-counts-mm10.tsv'
contrasts = list(c('Liver-Adult', 'Hepa1-6'),
                 c('Liver-Adult', 'Hepa1c1c7'),
                 c('Hepa1-6', 'Hepa1c1c7'),
                 c('Liver-Adult', 'E15.5'),
                 c('E15.5', 'Hepa1-6'),
                 c('E15.5', 'Hepa1c1c7'))
celltype_colors = c(`Liver-Adult` = 'black',
                    `Hepa1-6` = '#E69F00',
                    Hepa1c1c7 = '#D55E00',
                    E15.5 = '#56B4E9')

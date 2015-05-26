species = 'human'
trna_counts = './data/trna-counts-hs19.tsv'
mrna_counts = './data/rnaseq-counts-hs19.tsv'
trna_annotation = './data/Homo_sapiens.GRCh38.dna.primary_assembly.trna.filtered.out'
mrna_annotation = './data/Homo_sapiens.GRCh38.78.gene_annot.tsv'
cds = './data/Homo_sapiens.GRCh38.cds.all.fa.gz'
trna_design = './data/libraries-trna-chip-hs19.tsv'
mrna_design = './data/libraries-rna-seq-hs19.tsv'
norm_counts = './results/trna-norm-counts-hs19.tsv'
contrasts = list(c('Liver-Adult', 'Huh7'),
                 c('Liver-Adult', 'HepG2'),
                 c('Huh7', 'HepG2'))

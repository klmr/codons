modules::import('cache', attach = TRUE)
modules::import_package('dplyr', attach = TRUE)
tidyr = modules::import_package('tidyr')
io = modules::import('ebits/io')

trna_counts = cache %@% function (config) {
    trna_annotation = io$read_table(config$trna_annotation, header = FALSE) %>%
        select(Chr = 1, Num = 2, AA = 5, Anticodon = 6) %>%
        filter(grepl('(chr)?\\d+', Chr)) %>%
        filter(! Anticodon %in% c('TTA', 'TCA', 'CTA')) %>%
        transmute(Gene = paste(Chr, Num, sep = '.'), AA, Anticodon) %>%
        tbl_df()

    counts = io$read_table(config$trna_counts, header = TRUE) %>%
        `colnames<-`(., c('X', colnames(.)[-1])) %>%
        tbl_df() %>%
        rename(Gene = X) %>%
        inner_join(trna_annotation, ., by = 'Gene') %>%
        select(Gene, AA, Anticodon, one_of(trna_design(config)$DO))

    # Filter out never expressed genes. For tRNA genes, we need to be sensitive
    # to spurious counts from the ChIP-seq data, using an adjusted lower bound.
    # To make this at all comparable across libraries, we use normalised counts.

    norm = modules::import('norm')
    size_factors = counts %>% select(starts_with('do')) %>% norm$size_factors()
    norm_counts = norm$transform_counts(counts, . / size_factors$., starts_with('do'))
    filter_unexpressed(norm_counts, trna_design(config))
}

filter_unexpressed = function (counts, design) {
    threshold = 10 # This value works well.
    expressed = counts %>% tidyr$gather(DO, Count, starts_with('do')) %>%
        inner_join(design, by = 'DO') %>%
        group_by(Gene, Celltype) %>%
        summarize(Expressed = all(Count > threshold)) %>%
        summarize(Expressed = any(Expressed)) %>%
        filter(Expressed) %>% .$Gene

    filter(counts, Gene %in% expressed)
}

mrna_annotation = cache %@% function (config)
    io$read_table(config$mrna_annotation, header = TRUE) %>%
        tbl_df() %>%
        filter(source == 'protein_coding') %>%
        mutate(Chr = sapply(strsplit(locus, ':'), base$item(1)),
               Start = as.integer(base$grep(':(\\d+)', locus)),
               End = as.integer(base$grep('\\.\\.(\\d+)', locus))) %>%
        filter(grepl('^(chr)?(\\d+|X|Y)$', Chr)) %>%
        select(Gene = ID, Name, Chr, Start, End, GO)

mrna_counts = cache %@% function (config) {
    counts = io$read_table(config$mrna_counts, header = TRUE) %>%
        tbl_df() %>%
        inner_join(mrna_annotation(config), ., by = 'Gene')

    # Filter out never expressed genes. For protein-coding genes this is
    # straightforward, we retain all whose count is $>0$.
    zero_rows = rowSums(select(counts, starts_with('do'))) == 0
    counts[! zero_rows, ]
}

trna_design = cache %@% function (config)
    design = io$read_table(config$trna_design) %>%
        tbl_df() %>%
        select(DO = 1, AB = 2, Celltype = 3) %>%
        filter(AB != 'Input') %>%
        select(-AB) %>%
        mutate(Celltype = ifelse(Celltype == 'liver', 'Liver-Adult', Celltype))

mrna_design = cache %@% function (config)
    io$read_table(config$mrna_design) %>%
        tbl_df() %>%
        select(DO = 1, Celltype = 2) %>%
        mutate(Celltype = ifelse(Celltype == 'liver', 'Liver-Adult', Celltype))

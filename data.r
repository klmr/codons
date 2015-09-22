modules::import('cache', attach = TRUE)
modules::import_package('dplyr', attach = TRUE)
tidyr = modules::import_package('tidyr')
base = modules::import('ebits/base')
io = modules::import('ebits/io')

trna_annotation = cache %@% function (config)
    io$read_table(config$trna_annotation, header = FALSE) %>%
        select(Chr = 1, Num = 2, AA = 5, Anticodon = 6, Start = 3, Stop = 4) %>%
        filter(grepl('^(chr)?\\d+$', Chr)) %>%
        filter(! Anticodon %in% c('TTA', 'TCA', 'CTA')) %>%
        transmute(Gene = paste(Chr, Num, sep = '.trna'), AA, Anticodon,
                  Length = abs(Stop - Start) + 1) %>%
        tbl_df()

trna_counts = cache %@% function (config) {
    counts = io$read_table(config$trna_counts, header = TRUE) %>%
        `colnames<-`(., c('X', colnames(.)[-1])) %>%
        tbl_df() %>%
        mutate(Gene = sub('.', '.trna', X, fixed = TRUE)) %>%
        inner_join(trna_annotation(config), ., by = 'Gene') %>%
        select(Gene, AA, Anticodon, one_of(trna_design(config)$DO))

    # Filter out never expressed genes. For tRNA genes, we need to be sensitive
    # to spurious counts from the ChIP-seq data, using an adjusted lower bound.
    # To make this at all comparable across libraries, we use normalised counts.
    filter(counts, Gene %in% filter_expressed(trna_design(config), counts))
}

trna_sf_counts = cache %@% function (config) {
    norm = modules::import('norm')
    counts = trna_counts(config)
    size_factors = counts %>% select(starts_with('do')) %>% norm$size_factors()
    norm$transform_counts(counts, . / size_factors$., starts_with('do'))
}

filter_expressed = function (design, counts) {
    norm = modules::import('norm')
    threshold = 10 # This value works well.

    size_factors = counts %>% select(starts_with('do')) %>% norm$size_factors()
    norm_counts = norm$transform_counts(counts, . / size_factors$., starts_with('do'))

    norm_counts %>% tidyr$gather(DO, Count, starts_with('do')) %>%
        inner_join(design, by = 'DO') %>%
        group_by(Gene, Celltype) %>%
        summarize(Expressed = all(Count > threshold)) %>%
        summarize(Expressed = any(Expressed)) %>%
        filter(Expressed) %>% .$Gene
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
        inner_join(mrna_annotation(config), ., by = 'Gene') %>%
        select(Gene, Name, starts_with('do'))

    # Filter out never expressed genes. For protein-coding genes this is
    # straightforward, we retain all whose count is $>0$.
    zero_rows = rowSums(select(counts, starts_with('do'))) == 0
    counts[! zero_rows, ]
}

trna_tpm_counts = cache %@% function (config) {
    # Required by dplyr::funs: norm$tpm wouldn’t work
    # TODO: Report as bug in dplyr
    modules::import('norm', attach = TRUE)
    annotation = trna_annotation(config) %>%
        select(-AA, -Anticodon)
    counts = inner_join(trna_counts(config), annotation, by = 'Gene')
    transform_counts(counts, tpm(., Length), starts_with('do')) %>%
        select(Gene, AA, Anticodon, starts_with('do'))
}

mrna_tpm_counts = cache %@% function (config) {
    # Required by dplyr::funs: norm$tpm wouldn’t work
    # TODO: Report as bug in dplyr
    modules::import('norm', attach = TRUE)
    counts = inner_join(mrna_counts(config), canonical_cds(config), by = 'Gene')
    transform_counts(counts, tpm(., Length), starts_with('do')) %>%
        select(Gene, Name, starts_with('do'))
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

canonical_cds = cache %@% function (config) {
    bios = modules::import_package('Biostrings')
    cds = bios$readDNAStringSet(config$cds)
    names(cds) = sub('.*gene:(ENS(MUS)?G\\d+).*', '\\1', names(cds))
    cds = data.frame(Gene = names(cds), Sequence = as.character(cds),
                     stringsAsFactors = FALSE)

    # Filter CCDS, only preserve valid coding frames

    is_valid_cds = function (seq)
        base::nchar(seq) %% 3 == 0 & grepl('^ATG', seq) & grepl('(TAG|TAA|TGA)$', seq)

    cds %>%
        filter(is_valid_cds(Sequence)) %>%
        mutate(Length = base::nchar(Sequence)) %>%
        group_by(Gene) %>%
        arrange(desc(Length)) %>%
        slice(1) %>%
        ungroup()
}

go_genes = cache %@% function (config) {
    mrna_annotation = mutate(mrna_annotation(config), Name = toupper(Name))
    io$read_table('data/gene_association.goa_human', header = FALSE,
                         comment.char = '!', quote = '', sep = '\t') %>%
    select(Name = 3, GO = 5, Aspect = 9) %>%
    filter(Aspect == 'P') %>%
    mutate(Name = toupper(Name)) %>%
    inner_join(mrna_annotation, by = 'Name') %>%
    select(Gene, GO = GO.x) %>%
    distinct(GO, Gene) %>%
    group_by(GO) %>%
    mutate(Size = length(Gene)) %>%
    ungroup() %>%
    filter(Size >= 40) %>%
    select(-Size) %>%
    tbl_df()
}

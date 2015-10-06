#!/usr/bin/env Rscript

library(modules, warn.conflicts = FALSE, quietly = TRUE)
sys = import('sys')

sys$run({
    args = sys$cmdline$parse(arg('filename', 'the filename of the RDS output'))

    import_package('dplyr', attach = TRUE)
    base = import('ebits/base')

    config = modules::import('../config_human')
    data = import('../data')
    mrna_annotation = data$mrna_annotation(config) %>% select(-GO)
    go_genes = inner_join(data$go_genes(config), mrna_annotation, by = 'Gene')
    canonical_cds = data$canonical_cds(config)

    go_genes = go_genes %>%
        filter(Gene %in% canonical_cds$Gene) %>%
        group_by(GO) %>%
        distinct(Gene) %>%
        mutate(Size = n()) %>%
        filter(Size >= 40) %>%
        ungroup()

    distinct_go_sizes = go_genes$Size %>% unique() %>% sort()

    cu_ = import('codon_usage')
    codon_usage = cu_$cu(canonical_cds) %>%
        inner_join(cu_$genetic_code, by = 'Codon')

    background_cu = codon_usage %>%
        group_by(AA, Codon) %>%
        summarize(CU = sum(CU)) %>%
        ungroup() %>%
        mutate(Prop = CU / sum(CU)) %>%
        arrange(Codon)

    # Optimised to allow indexed access for gene names, since selection by gene name
    # turned out to be a major bottleneck.
    # This change provides a > 1000% speedup.
    stride = length(unique(codon_usage$Gene))
    stopifnot(stride * 61 == nrow(codon_usage))
    stopifnot(all(codon_usage[1 : stride, ]$Codon == codon_usage$Codon[1]))

    cu_fit = function (gene_index_set) {
        translated_index = unlist(lapply(gene_index_set, i -> 0 : 60 * stride + i))
        codon_usage[translated_index, ] %>%
            group_by(AA, Codon) %>%
            summarize(CU = sum(CU)) %>%
            ungroup() %>%
            mutate(Prop = CU / sum(CU)) %>%
            arrange(Codon) %>%
            {cor(.$Prop, background_cu$Prop)}
    }

    rng_seed = 1428079834

    sample_cu_fit = function (size)
        cu_fit(sample.int(nrow(canonical_cds), size))

    sample_cu_fit_rep = function (size, repetitions = 2) {
        # Ensure that all simulations are using different seed, as otherwise the
        # parallel jobs will start off with the same sequence of random samples.
        set.seed(rng_seed + size)
        on.exit(cat('.', file = stderr()))
        replicate(repetitions, sample_cu_fit(size))
    }

    cores = parallel::detectCores()
    sampled_cu_fit = parallel::mclapply(distinct_go_sizes, sample_cu_fit_rep,
                                        repetitions = 10000,
                                        mc.cores = cores, mc.set.seed = FALSE) %>%
        setNames(distinct_go_sizes) %>%
        {do.call(rbind, .)} %>%
        as.data.frame() %>%
        add_rownames('Size') %>%
        mutate(Size = as.integer(Size))

    cat('\n', file = stderr())
    saveRDS(sampled_cu_fit, file = args$filename)
})

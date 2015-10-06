#!/usr/bin/env Rscript

library(modules, warn.conflicts = FALSE, quietly = TRUE)
sys = import('sys')
import_package('dplyr', attach = TRUE)
base = import('ebits/base')

data = new.env()

make_global = function (variable, global_env = parent.env(parent.frame())) {
    variable = substitute(variable)
    assign(deparse(variable), eval.parent(variable), global_env)
}

load_codon_usage_data = function () {
    config = modules::import('../config_human')
    data_ = import('../data')
    mrna_annotation = data_$mrna_annotation(config) %>% select(-GO)
    canonical_cds = data_$canonical_cds(config)

    go_genes = data_$go_genes(config) %>%
        inner_join(mrna_annotation, by = 'Gene') %>%
        filter(Gene %in% canonical_cds$Gene) %>%
        group_by(GO) %>%
        distinct(Gene) %>%
        mutate(Size = n()) %>%
        filter(Size >= 40) %>%
        ungroup()

    cu_ = import('codon_usage')
    codon_usage = cu_$cu(canonical_cds) %>%
        inner_join(cu_$genetic_code, by = 'Codon')

    background = codon_usage %>%
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

    make_global(go_genes, data)
    make_global(canonical_cds, data)
    make_global(codon_usage, data)
    make_global(background, data)
    make_global(stride, data)
}

cu_fit = function (gene_index_set) {
    translated_index = unlist(lapply(gene_index_set, i -> 0 : 60 * data$stride + i))
    data$codon_usage[translated_index, ] %>%
        group_by(AA, Codon) %>%
        summarize(CU = sum(CU)) %>%
        ungroup() %>%
        mutate(Prop = CU / sum(CU)) %>%
        arrange(Codon) %>%
        {cor(.$Prop, data$background$Prop)}
}

sample_cu_fit = function (size)
    cu_fit(sample.int(nrow(data$canonical_cds), size))

sample_cu_fit_rep = function (size, repetitions = 2) {
    # Ensure that all simulations are using different seed, as otherwise the
    # parallel jobs will start off with the same sequence of random samples.
    set.seed(rng_seed + size)
    on.exit(cat('.', file = stderr()))
    replicate(repetitions, sample_cu_fit(size))
}

sys$run({
    args = sys$cmdline$parse(arg('filename', 'the filename of the RDS output'))

    load_codon_usage_data()
    distinct_go_sizes = data$go_genes$Size %>% unique() %>% sort()
    rng_seed = 1428079834
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

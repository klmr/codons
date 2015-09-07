raw_cu = cu$cu(canonical_cds)
trna_gene_counts = data$trna_annotation(config) %>%
    filter(Anticodon != '???') %>%
    mutate(Codon = revcomp(Anticodon)) %>%
    group_by(Codon) %>%
    summarize(AA = n())
tai = cu$adaptation_tai(raw_cu, trna_gene_counts, canonical_cds)
hist(tai, breaks = 20)

# Use one replicate of healthy tissue.
#healthy_cu = codon_usage %>% filter(DO == 'do4152')
healthy_aa = aa %>% filter(DO == 'do388') %>% select(-AA) %>% rename(AA = Count)
#healthy_tai = cu$adaptation_tai(healthy_cu, healthy_aa, canonical_cds)
#hist(healthy_tai)

# Find optimal s-values
# Sample 1000 genes from across the range of expression
optim_mrna = inner_join(canonical_cds %>% select(Gene, Length),
                        mrna_counts %>% select(Gene, Expression = do4152),
                        by = 'Gene') %>%
    inner_join(raw_cu %>% tidyr::spread(Codon, CU), by = 'Gene') %>%
    arrange(Expression) %>%
    slice(seq(1, n(), length.out = 1000))
optim_trnas = setNames(healthy_aa$AA, healthy_aa$Codon)
set.seed(1440421485)
optim_s = cu$tai$find_optimal_s(select(optim_mrna, -Gene, -Length, -Expression),
                                optim_mrna$Expression,
                                optim_mrna$Length,
                                optim_trnas)
s = optim_s$par
optim_tai = cu$adaptation_tai(raw_cu, trna_gene_counts, canonical_cds, s)
hist(optim_tai, breaks = 20)
plot(optim_tai ~ tai)
cor(tai, optim_tai, method = 'spearman')
as.data.frame(optim_tai) %>% add_rownames('Gene') %>% inner_join(mrna_counts) %>%
    ggplot(aes(x = do4152 + 1, y = optim_tai)) +
    geom_point() +
    scale_x_log10() +
    geom_smooth(method = lm)
##########

healthy_tai = inner_join(mrna_counts,
                         data.frame(Gene = names(tai), raw_tAI = tai),
                         by = 'Gene') %>%
    mutate(tAI = raw_tAI * do4152) %>%
    mutate(tAI = tAI / max(tAI))

hist(healthy_tai$tAI, breaks = 20)

#hepg2_aa = aa %>% filter(DO == 'do1093') %>% select(-AA) %>% rename(AA = Count)

# Compare tAI with simple correlation
healthy_rcu = healthy_cu %>% `class<-`(c('codon_usage$cu', class(.))) %>% cu$rcu()
healthy_raa = raa %>% filter(DO == 'do388')
healthy_fit = cu$adaptation_no_wobble(healthy_rcu, healthy_raa) %>%
    mutate(Adaptation = ifelse(is.na(Adaptation), 0, Adaptation))
hist(healthy_fit$Adaptation)

healthy_compare = inner_join(healthy_tai, healthy_fit, by = 'Gene')
ggplot(healthy_compare, aes(x = Adaptation, y = tAI)) +
    geom_point()
with(healthy_compare, cor(Adaptation, tAI, method = 'spearman'))

ggplot(healthy_compare, aes(x = do4152, y = Adaptation)) +
    geom_point() +
    scale_x_log10()

ggplot(healthy_compare, aes(x = do4152, y = tAI)) +
    geom_point() +
    scale_x_log10()

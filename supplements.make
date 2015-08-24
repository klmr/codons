include structure.make
supp_dir := results/supplements
combinations := human-mrna mouse-mrna human-trna mouse-trna
de_genes_combinations := $(addprefix de-genes-,${combinations})

.PHONY: all
all: ${combinations}

${supp_dir}/gene-expression-%.tsv:
	mkdir -p $(@D)
	./scripts/write-supp-table $(call split-args,$*) > $@

.PHONY: de-genes
de-genes: ${de_genes_combinations}

.PHONY: ${de_genes_combinations}
${de_genes_combinations}:
	mkdir -p ${supp_dir}
	./scripts/write-de-table $(call split-args-de,$@) ${supp_dir}/

define split-args
	$(subst -, ,$1)
endef

define split-args-de
	$(call split-args,$(subst de-genes-,,$1))
endef

.PHONY: ${combinations}

.SECONDEXPANSION:
${combinations}: \
	${supp_dir}/gene-expression-$$@.tsv \
	de-genes-$$@

# vim: ft=make

include structure.make
supp_dir := results/supplements
combinations := human-mrna mouse-mrna human-trna mouse-trna

.PHONY: all
all: gene-expression

.PHONY: gene-expression
gene-expression: ${combinations}

${supp_dir}/gene-expression-%.tsv:
	mkdir -p $(@D)
	./scripts/write-expression-table $(call split-args,$*) > $@

define split-args
	$(subst -, ,$1)
endef

define split-args-de
	$(call split-args,$(subst de-genes-,,$1))
endef

.PHONY: ${combinations}

.SECONDEXPANSION:
${combinations}: ${supp_dir}/gene-expression-$$@.tsv

# vim: ft=make

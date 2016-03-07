include structure.make
supp_dir := results/supplements
species := human mouse
datatype := mrna trna
combinations := $(foreach i,${species},$(foreach j,${datatype},$j-$i))
upregulated-all := $(foreach i,${species},upregulated-$i)
enriched-go-all := $(foreach i,${species},enriched-go-$i)
enriched-go-genes-all := $(foreach i,${species},enriched-go-genes-$i)

.PHONY: all
all: gene-expression \
	upregulated-all \
	enriched-go-all \
	enriched-go-genes-all \
	ribosomal-genes \
	housekeeping-genes \
	proliferation-genes \
	trna-mod-genes \
	flowcharts

# Helper to reverse a list. <http://stackoverflow.com/a/786530/1968>
reverse = $(if $1,$(call reverse,$(wordlist 2,$(words $1),$1))) $(firstword $1)

.PHONY: gene-expression
gene-expression: ${combinations}

${supp_dir}/gene-expression/gene-expression-%.tsv:
	mkdir -p $(@D)
	${BIN}/write-expression-table $(call reverse,$(subst -, ,$*)) $@

.PHONY: upregulated-all ${upregulated-all}
upregulated-all: ${upregulated-all}

upregulated-human: results/de/up-human.rds
upregulated-mouse: results/de/up-human.rds

${upregulated-all}:
	mkdir -p ${supp_dir}/upregulated
	${BIN}/write-upregulated-genes-tables \
		$(lastword $(subst -, ,$@)) ${supp_dir}/upregulated/

.PHONY: enriched-go-all ${enriched-go-all}
enriched-go-all: ${enriched-go-all}

enriched-go-human: results/gsa/go-human.rds
enriched-go-mouse: results/gsa/go-mouse.rds

${enriched-go-all}:
	mkdir -p ${supp_dir}/enriched-go
	${BIN}/write-enriched-go-tables \
		$(lastword $(subst -, ,$@)) ${supp_dir}/enriched-go/

.PHONY: enriched-go-genes-all ${enriched-go-genes-all}
enriched-go-genes-all: ${enriched-go-genes-all}

enriched-go-genes-human: results/gsa/go-human.rds
enriched-go-genes-mouse: results/gsa/go-mouse.rds

${enriched-go-genes-all}:
	mkdir -p ${supp_dir}/enriched-go-genes
	${BIN}/write-enriched-go-gene-tables \
		$(lastword $(subst -, ,$@)) ${supp_dir}/enriched-go-genes/

.PHONY: ribosomal-genes
ribosomal-genes: $(foreach i,${species},${supp_dir}/ribosomal/rp-genes-$i.txt)

${supp_dir}/ribosomal/rp-genes-%.txt: data/rp-genes-%.txt
	mkdir -p $(@D)
	${BIN}/write-ribosomal-genes-table $* $@

.PHONY: housekeeping-genes
housekeeping-genes: $(foreach i,${species},${supp_dir}/housekeeping/hk-genes-$i.txt)

${supp_dir}/housekeeping/hk-genes-%.txt: data/hk408.txt
	mkdir -p $(@D)
	${BIN}/write-housekeeping-genes-table $* $@

.PHONY: proliferation-genes
proliferation-genes: $(foreach i,${species},${supp_dir}/proliferation/pro-genes-$i.txt)

${supp_dir}/proliferation/pro-genes-%.txt: data/proliferation-genes.tsv
	mkdir -p $(@D)
	${BIN}/write-proliferation-genes-table $* $@

.PHONY: trna-mod-genes
trna-mod-genes: \
	$(foreach i,${species},${supp_dir}/trna-mod-genes/fold-change-heatmap-$i.pdf) \
	$(foreach i,${species},${supp_dir}/trna-mod-genes/de-genes-$i.tsv)

${supp_dir}/trna-mod-genes/fold-change-heatmap-%.pdf: data/trna-modifier-genes.txt
	mkdir -p $(@D)
	${BIN}/plot-trna-mod-genes $* $@

${supp_dir}/trna-mod-genes/de-genes-%.tsv: data/trna-modifier-genes.txt \
	results/de/de-%.rds
	mkdir -p $(@D)
	${BIN}/write-de-trna-mod-genes-table $* $@

.PHONY: flowcharts
flowcharts: rna-seq-flowchart.pdf chip-seq-flowchart.pdf

%-flowchart.png: %-flowchart.dot flowchart.gvpr
	gvpr -c -f flowchart.gvpr $< | dot -Tpng -o $@

%-flowchart.pdf: %-flowchart.dot flowchart.gvpr
	gvpr -c -f flowchart.gvpr $< | dot -Tpdf -o $@

.PHONY: ${combinations}

.SECONDEXPANSION:
${combinations}: ${supp_dir}/gene-expression/gene-expression-$$@.tsv

# vim: ft=make

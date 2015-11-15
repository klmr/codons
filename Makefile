BIN := ./scripts

species := mouse human

load-contrasts = \
	$(shell Rscript -e 'modules::import("./config_$1", attach = TRUE); cat(sapply(contrasts, function (x) sprintf("%s-vs-%s", x[1], x[2])))')

contrasts/mouse := $(call load-contrasts,mouse)
contrasts/human := $(call load-contrasts,human)

.PHONY: all
all: go te
	@echo >&2 No default rule. Please run \`make rule\`
	exit 1

.PHONY: go
go: data/go-descriptions.tsv go-enrichment

.PHONY: go-enrichment
go-enrichment: \
		results/gsa/mouse-$(firstword ${contrasts/mouse}).tsv \
		results/gsa/human-$(firstword ${contrasts/human}).tsv

.PHONY: te
te: \
		$(foreach i,${species},results/te-$i-boxplot.pdf) \
		$(foreach i,${species},results/te-$i-adaptation-test-p.tsv) \
		results/te-human-liver-matching-scatter.pdf

results/de/mouse-%:
	mkdir -p results/de
	${BIN}/differential-expression $* mrna $@

results/de/human-%:
	mkdir -p results/de
	${BIN}/overexpressed-genes $* $< $@

results/gsa/mouse-%:
	mkdir -p results/gsa
	${BIN}/go-enrichment mouse results/gsa/

results/gsa/human-%:
	mkdir -p results/gsa
	${BIN}/go-enrichment human results/gsa/

data/go-descriptions.tsv: data/go-basic.obo
	${BIN}/write-go-descriptions $< $@

data/go-basic.obo:
	wget 'http://purl.obolibrary.org/obo/go/go-basic.obo' \
		--output-document data/go-basic.obo

data/rp-genes-%.txt:
	${BIN}/download-rp-genes $* > $@

results/te-boxplot-human.pdf: results/te-human.rds
	${BIN}/plot-te-boxplot human $@

results/te-boxplot-mouse.pdf: results/te-mouse.rds
	${BIN}/plot-te-boxplot mouse $@

results/te-human.rds: codon-anticodon-correlation-human.html

results/te-mouse.rds: codon-anticodon-correlation-mouse.html

results/te-liver-matching-scatter-human.pdf:
	${BIN}/plot-te-scatter human Liver-Adult $@

.PHONY: go-enrichment
go-enrichment: ${go-enrichment}

$(foreach i,${species},pca-versus-adaptation-$i.html): go

codon-anticodon-correlation-human.html: go de data/rp-genes-human.txt

codon-anticodon-correlation-mouse.html: go de data/rp-genes-mouse.txt

sample-size-effect.html: sample-size-effect.rmd results/sampled-cu-fit.rds

results/sampled-cu-fit.rds: scripts/sample-codon-usage
	${BIN}/sample-codon-usage $@

.PHONY: supplements
supplements:
	make -f supplements.make

%-mouse.rmd: %.rmd.brew
	${BIN}/brew $< $@ 'species="mouse"'

%-human.rmd: %.rmd.brew
	${BIN}/brew $< $@ 'species="human"'

%.md: %.rmd
	${BIN}/knit $< $@

%.html: %.rmd
	${BIN}/knit $< $@

%.rmd: %.rmd.brew
	${BIN}/brew $< $@

# Assume that .md files with corresponding .html files are intermediates.
.PHONY: clean
clean:
	${RM} $(patsubst %.html,%.md,$(wildcard *.html))
	${RM} $(patsubst %.brew,%,$(wildcard *.brew))
	${RM} $(foreach s,${species},$(patsubst %.rmd.brew,%-$s.rmd,$(wildcard *.brew)))
	${RM} cache/*

.PHONY: cleanall
cleanall: clean
	${RM} *.html
	${RM} *.pdf
	${RM} -r figure
	${RM} -r results

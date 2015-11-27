include structure.make
species := mouse human
te-methods := simple-te wobble-te tai

.PHONY: all
all: go te
	@echo >&2 No default rule. Please run \`make rule\`
	exit 1

.PHONY: go
go: data/go-descriptions.tsv $(foreach i,${species},results/gsa/go-$i.rds)

.PHONY: te
te: \
		$(foreach i,${species},results/te-$i-boxplot.pdf) \
		$(foreach i,${species},results/te-$i-adaptation-test-p.tsv) \
		results/te-human-liver-matching-scatter.pdf

.PRECIOUS: $(foreach i,${species},results/de/de-$i.rds)
results/de/de-%.rds:
	mkdir -p results/de
	${BIN}/differential-expression $* mrna $@

.PRECIOUS: $(foreach i,${species},results/de/up-$i.rds)
results/de/up-%.rds: results/de/de-%.rds
	mkdir -p results/de
	${BIN}/overexpressed-genes $* $< $@

.PRECIOUS: $(foreach i,${species},results/gsa/go-$i.rds)
results/gsa/go-%.rds: data/gene_association.goa_human
	mkdir -p results/gsa
	${BIN}/go-enrichment $* $@

.PRECIOUS: $(foreach i,${species},$(foreach j,${te-methods},results/$j-$i.rds))
results/simple-te-%.rds: results/de/up-%.rds results/gsa/go-%.rds \
		data/rp-genes-%.txt
	mkdir -p results
	${BIN}/translation-efficiency-test-sets $* $@

results/wobble-te-%.rds: results/de/up-%.rds results/gsa/go-%.rds \
		data/rp-genes-%.txt
	mkdir -p results
	${BIN}/translation-efficiency-test-sets --te=wobble-te $* $@

results/tai-%.rds: results/de/up-%.rds results/gsa/go-%.rds \
		data/rp-genes-%.txt
	mkdir -p results
	${BIN}/translation-efficiency-test-sets --te=tai $* $@

results/figure-3/boxplot-simple-te-summary-%.pdf: results/simple-te-%.rds
	mkdir -p $(@D)
	${BIN}/plot-te-boxplot --summary $* $@

results/figure-3/test-p-values-simple-te-compare-which-%.tsv: results/simple-te-%.rds
	mkdir -p $(@D)
	${BIN}/write-adaptation-test-table --axis=which $* $@

.PHONY: all-te-plots
all-te-plots: $(foreach i,${species},$(foreach j,${te-methods},results/$j-$i.rds))
	mkdir -p results/figure-3
	for te in ${te-methods}; do \
		for s in --summary ''; do \
			for c in --mean-center ''; do \
				for species in ${species}; do \
					${BIN}/plot-te-boxplot --te=$$te $$s $$c $$species \
						results/figure-3/boxplot-$$te$${s/-/}$${c/-/}-$$species.pdf; \
				done; \
			done; \
		done; \
	done

.PHONY: all-te-tests
all-te-tests: $(foreach i,${species},$(foreach j,${te-methods},results/$j-$i.rds))
	mkdir -p results/figure-3
	for te in ${te-methods}; do \
		for a in which match; do \
			for c in --mean-center ''; do \
				for species in ${species}; do \
					${BIN}/plot-te-boxplot --axis=$$a --te=$$te $$s $$c $$species \
						results/figure-3/test-p-values-$$te-compare-$$a-$${c/-/}-$$species.tsv; \
				done; \
			done; \
		done; \
	done

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

results/te-adaptation-test-p-human.tsv: results/te-human.rds
	${BIN}/write-adaptation-test-table human $@

results/te-adaptation-test-p-mouse.tsv: results/te-mouse.rds
	${BIN}/write-adaptation-test-table mouse $@

results/te-liver-matching-scatter-human.pdf:
	${BIN}/plot-te-scatter human Liver-Adult $@

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

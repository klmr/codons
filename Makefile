BIN := ./scripts

species := mouse human

.PHONY: all
all: go
	@echo >&2 No default rule. Please run \`make rule\`
	exit 1

.PHONY: go
go: data/go-descriptions.tsv

data/go-descriptions.tsv: data/go-basic.obo
	./scripts/write-go-descriptions $< $@

data/go-basic.obo:
	wget 'http://purl.obolibrary.org/obo/go/go-basic.obo' \
		--output-document data/go-basic.obo

$(foreach i,${species},pca-versus-adaptation-$i.html): go

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

# FIRST generate a list of temporary md files, *then* of temporary rmd files
.PHONY: clean
clean:
	${RM} $(patsubst %.rmd,%.md,$(wildcard *.rmd))
	${RM} $(patsubst %.brew,%,$(wildcard *.brew))
	${RM} $(foreach s,${species},$(patsubst %.rmd.brew,%-$s.rmd,$(wildcard *.brew)))
	${RM} cache/*

.PHONY: cleanall
cleanall: clean
	${RM} *.html
	${RM} *.pdf
	${RM} figure/*

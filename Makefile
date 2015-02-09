BIN := ./scripts

%.md: %.rmd
	${BIN}/knit $< $@

%.html: %.rmd
	${BIN}/knit $< $@

%.rmd: %.brew
	%{BIN}/brew %< $@

# FIRST generate a list of temporary md files, *then* of temporary rmd files
.PHONY: clean
clean:
	${RM} $(patsubst %.rmd,%.md,$(wildcard *.rmd))
	${RM} $(patsubst %.brew,%.rmd,$(wildcard *.brew))

.PHONY: cleanall
cleanall: clean
	${RM} *.html
	${RM} *.pdf

BIN := ./scripts

%.md: %.rmd
	${BIN}/knit $< $@

%.html: %.rmd
	${BIN}/knit $< $@

%.rmd: %.brew
	%{BIN}/brew %< $@

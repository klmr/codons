.PHONY: all
all: human mouse

.PHONY: human
human: human-mrna human-trna

.PHONY: mouse
mouse: mouse-mrna mouse-trna

results/supplements/%.tsv:
	mkdir -p $(@D)
	./scripts/write-supp-table $(call split-args,$*) > $@

define split-args
	$(subst -, ,$1)
endef

.PHONY: human-mrna mouse-mrna human-trna mouse-trna

.SECONDEXPANSION:
human-mrna mouse-mrna human-trna mouse-trna: results/supplements/$$@.tsv

# vim: ft=make

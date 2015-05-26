include structure.make

hs := homo_sapiens
ref_dir_hs = ${ref_dir}/${hs}
lib_dir_hs := ${lib_dir}/${hs}
quant_dir_hs := ${quant_dir}/${hs}
version_hs := GRCh38
ref_hs := ${ref_dir_hs}/Homo_sapiens.${version_hs}.cdna.all.fa.gz
index_hs := ${ref_hs:%.fa.gz=%.kidx}

dirs := $(sort \
	${ref_dir_hs} \
	${quant_dir_hs} \
)

.PHONY: reference
reference: ${ref_hs}

${ref_hs}: ${ref_dir_hs}
	wget 'ftp://ftp.ensembl.org/pub/release-80/fasta/homo_sapiens/cdna/Homo_sapiens.GRCh38.cdna.all.fa.gz' \
		-O '$@'

.PHONY: index
index: ${index_hs}

${index_hs}: ${ref_hs}
	${bsub} kallisto index --index '$@' '$<'

.PHONY: quant
quant: quant_hs

lib_files_hs := $(notdir $(shell find ${lib_dir_hs} -name '*p1.fq.gz'))
quant_files_hs := $(addprefix ${quant_dir_hs}/,$(patsubst %p1.fq.gz,%/abundance.h5,${lib_files_hs}))

.PHONY: quant_hs
quant_hs: ${quant_files_hs}

${quant_dir_hs}/%/abundance.h5: ${lib_dir_hs}/%.fq.gz ${index_hs} ${quant_dir_hs}
	${bsub} kallisto quant --index '${index_hs}' \
		--output-dir '$@' \
		--bootstrap-samples 100 \
		'$<' '${<:%.p1=%.p2}'

.PHONY: dirs
dirs: ${dirs}

${dirs}:
	mkdir -p $@

# vim: ft=make

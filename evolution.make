include structure.make

all_species := hsa mmu rnor cfa mmul mdo

species/hsa := homo_sapiens
species/mmu := mus_musculus
species/rnor := rattus_norvegicus
species/cfa := canis_familiaris
species/mmul := macaca_mulatta
species/mdo := monodelphis_domestica

all_species_names := $(foreach i,${all_species},${species/$i})

cds/hsa := Homo_sapiens.GRCh38.cds.all.fa.gz
cds/mmu := Mus_musculus.GRCm38.cds.all.fa.gz
cds/rnor := Rattus_norvegicus.Rnor_6.0.cds.all.fa.gz
cds/cfa := Canis_familiaris.CanFam3.1.cds.all.fa.gz
cds/mmul := Macaca_mulatta.MMUL_1.cds.all.fa.gz
cds/mdo := Monodelphis_domestica.BROADO5.cds.all.fa.gz

cds_base_uri := ftp://ftp.ensembl.org/pub/release-80/fasta

all_cds := $(foreach i,${all_species},${cds/$i})
all_full_cds := $(foreach i,${all_species},${ref_dir}/${species/$i}/${cds/$i})

.PHONY: download-cds
download-cds: ${all_full_cds}

${ref_dir}/%.cds.all.fa.gz:
	mkdir -p "${ref_dir}/$(*D)"
	wget -O "$@" "${cds_base_uri}/$(*D)/cds/$(*F).cds.all.fa.gz"

# vim: ft=make

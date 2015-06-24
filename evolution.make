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
	mkdir -p "${ref_dir}/${*D}"
	wget -O "$@" "${cds_base_uri}/${*D}/cds/${*F}.cds.all.fa.gz"

all_codon_usage := $(foreach i,${all_species},${result_dir}/${species/$i}/$(patsubst %.cds.all.fa.gz,%-codon_usage.rds,${cds/$i}))

.PHONY: codon-usage
codon-usage: ${all_codon_usage}

${result_dir}/%-codon_usage.rds: ${ref_dir}/%.cds.all.fa.gz
	mkdir -p "${result_dir}/${*D}"
	${bsub} "./transcriptome_codon_usage.r $< $@"

# Correlation with genomic background only:

${result_dir}/%-rcu-GO0000087.txt: ${result_dir}/%-codon_usage.rds
	./gene_set_rcu.r $< ${data_dir}/reference/$(notdir ${*D})/${*F}-GO0000087.txt $@

${result_dir}/%-rcu-GO0007389.txt: ${result_dir}/%-codon_usage.rds
	./gene_set_rcu.r $< ${data_dir}/reference/$(notdir ${*D})/${*F}-GO0007389.txt $@

all_rcu_GO0000087 := $(foreach i,${all_species},${result_dir}/${species/$i}/$(patsubst %.cds.all.fa.gz,%-rcu-GO0000087.txt,${cds/$i}))
all_rcu_GO0007389 := $(foreach i,${all_species},${result_dir}/${species/$i}/$(patsubst %.cds.all.fa.gz,%-rcu-GO0007389.txt,${cds/$i}))

${result_dir}/correlations.tsv: ${all_rcu_GO0000087} ${all_rcu_GO0007389}
	./scripts/merge-go-rcu-bias.sh '$(foreach i,${all_species},${species/$i})' \
		'${all_rcu_GO0000087}' '${all_rcu_GO0007389}' > '$@'

# Random gene set correlations with genomic background

${result_dir}/%-rcu-random.txt: ${result_dir}/%-codon_usage.rds
	./random_gene_set_rcu.r '$<' 100 100 '$@'

all_rcu_random := $(foreach i,${all_species},${result_dir}/${species/$i}/$(patsubst %.cds.all.fa.gz,%-rcu-random.txt,${cds/$i}))

${result_dir}/random-correlations.tsv: ${all_rcu_random}
	./scripts/merge-random-rcu-bias.sh '$(foreach i,${all_species},${species/$i})' ${all_rcu_random} > '$@'

# Plot the results

${result_dir}/correlations.pdf: ${result_dir}/correlations.tsv
	./plot_evo_comparison.r '$<' '$@'

# vim: ft=make

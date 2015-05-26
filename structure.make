data_dir := data
ref_dir := ${data_dir}/reference
lib_dir := ${data_dir}/raw_data
quant_dir := results/quant
bsub := bsub -K

# For debugging

print-%:
	@echo '$*=$($*)'

# vim: ft=make

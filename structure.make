data_dir := data
ref_dir := ${data_dir}/reference
lib_dir := ${data_dir}/raw_data
result_dir := results
quant_dir := ${result_dir}/quant
bsub := bsub -K

# For debugging

print-%:
	@echo '$*=$($*)'

# vim: ft=make

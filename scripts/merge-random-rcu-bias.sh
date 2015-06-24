species=$1
shift

echo "${species/ /	}"
paste $@

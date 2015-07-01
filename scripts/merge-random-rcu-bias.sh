species=$1
shift

echo 'FIXME Needs to replace ALL spaces, not just first.'
BREAK TERRIBLY
exit 42
echo "${species/ /	}"
paste $@

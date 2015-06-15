#!/usr/bin/env bash
species=$1
in1=$2
in2=$3

echo 'Species	GO0000087	GO0007389'
paste <(sed 's/ /\n/g' <<< "$1") <(cat $2) <(cat $3)

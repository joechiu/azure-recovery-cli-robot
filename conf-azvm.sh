#!/bin/sh

# file='/root/.ssh/config'
# conf='azcliVM'
file=$1
conf=$2

[ -z $file ] && { echo "Error: file not found"; exit 3; }
[ -z $conf ] && { echo "Error: configuration not found"; exit 3; }

cd $path
perl -p -i.bak -e "s/$conf//o" $file



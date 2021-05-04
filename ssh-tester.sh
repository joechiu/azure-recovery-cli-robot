#!/bin/sh

VM=$1
LOG=$2
a=1
n=0
max=120
while [ $a -gt 0 ]
do
  a=$(ssh -o ConnectTimeout=3 -q $VM exit; echo $?)
  ((n=n+1))
  echo "$n. ssh -o ConnectTimeout=3 -q $VM - result: $a" >> $LOG
  [ $n -ge $max ] && { echo "$max tries reached, exit!" >> $LOG; exit 3; }
  sleep 0.3;
done
echo "SSH connectivity test - DONE!" >> $LOG


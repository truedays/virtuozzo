#!/bin/bash
#
# Stop all containers
#
# Example: ./stopAll.sh "-s -ctid"
echo "Don't bother. still resuls in unclean shutdown checks. Reboot without wasting time stopping CTs."
exit 0
for n in `vzlist $1 -HSo ctid`
do 
 echo "+++ Stopping $n"
 vzctl stop $n
 echo
done

#!/bin/bash
#
# Start all stopped containers
#
# Example: ./startAll.sh "-s -ctid"
for n in `vzlist $1 -HSo ctid`
do 
 echo "Starting $n"
 vzctl start $n
done

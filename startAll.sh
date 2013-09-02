#!/bin/bash
#
# Start all stopped containers
#
for n in `vzlist -HSo ctid`
do 
 vzctl start $n
done

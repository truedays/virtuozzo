#!/bin/bash
#
# find old 256M and 512M containers and upgrade them to 1G UBC
#


for each in $(grep -lE 'PHYSPAGES="131072:131072"|PHYSPAGES="65536:65536"' /etc/vz/conf/*.conf | sed 's/.*\///' | cut -d. -f1 )
 do
 echo $each
done



#!/bin/bash
#
# find old 256M and 512M containers and upgrade them to 1G UBC
#

[ -d /root/ubc_fix_backups ] || mkdir /root/ubc_fix_backups

BACKUPDIR="/root/ubc_fix_backups"

for each in $(grep -lE 'PHYSPAGES="131072:131072"|PHYSPAGES="65536:65536"' /etc/vz/conf/*.conf | sed 's/.*\///' | cut -d. -f1 )
 do
 echo $each
 [ -f ${BACKUPDIR}/${each}.conf ] || ( echo "Backing up ${each}.."; cp -v /etc/vz/conf/${each}.conf ${BACKUPDIR}/ )

done



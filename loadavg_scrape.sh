#!/bin/bash
#
# ray Oct 09, 2013
#
# get some data
/bin/date --rfc-3339=seconds;echo -ne "$(hostname -s)\t"; /usr/bin/uptime | /bin/sed 's/.*: //' | /bin/cut -d" " -f2 | /bin/sed 's/,//';/usr/sbin/vzlist -Ho ctid,laverage |column -t | /bin/grep -vE "^1 "| /bin/cut -d/ -f1-2 | /bin/sed 's/[0-9]\.[0-9][0-9]\///' >> /root/loadavg_scrape.log

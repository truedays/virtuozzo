#!/bin/bash
#
# quotainit_all.sh
# Ray@eBh 01/23/2014
# V.01
#
# Purpose: vzctl quotainit all containers that need it (ie. due to unclean shutdown)
#
# Run via cron or manually
# ToDo: Fix logic for verbosity. maybe use exec > trick
#       Fix stderr output (ie. dots not found) 
#       add safe abort.. right now exit 1 is a quick hack


# Was this script called from an interactive terminal if so lets be more verbose
/usr/bin/tty > /dev/null 2>&1
[ $? -eq 0 ] && VERBOSE="true" || VERBOSE="false"

# find list of 0 sized CTs
# vzlist -Ho ctid,diskspace -s diskspace | grep " 0$"| awk '{print $1}'

# iterate through that list

for each in `vzlist -Ho ctid,diskspace -s diskspace | grep " 0$"| awk '{print $1}'`
 do
 echo "+++ Fixing quota for $each.."
 dots 5
 pidofdots=$!
 time /usr/sbin/vzctl quotainit $each || exit 1; kill $pidofdots; date
 /usr/sbin/vzctl stop $each && sleep .5 && /usr/sbin/vzctl start $each || /usr/sbin/vzctl start $each
 echo
done


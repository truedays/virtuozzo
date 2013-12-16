#! /bin/bash
#
#
# Check for mounted state containers and start them
# A Chris and Ray production 01/26/2011
#

## Our original command:
#/usr/sbin/vzlist -a | /bin/grep mounted | /bin/awk '{print $1}' | xargs -i% /usr/sbin/vzctl --verbose start %

for i in `/usr/sbin/vzlist -a | /bin/grep mounted | /bin/awk '{print $1}'`
do
/usr/sbin/vzctl --verbose start $i | /bin/mail -s "vps$i was found mounted and automatically started" alerts@eboundhost.com 
done

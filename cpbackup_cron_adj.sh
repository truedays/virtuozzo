#!/bin/bash
#
# Stagger cpbackup start times.
# V .01  May 6, 2013  Ray@ebh

hour=0     # Init variable, first backup @ midnight (0)
maxhour=8  # max cpbackup start time 

#iterate through all containers minus serviceCT
for each in `vzlist -Ho ctid| column -t |egrep -v ^1$`
 do

# if 'cpbackup' line in crontab exist do:
if [[ `vzctl exec $each crontab -l | grep cpbackup`  ]]
 then
  # rotate back to zero if > maxhour
  if [ $hour -gt ${maxhour} ]; then hour=0; fi
  #update cron
  echo "++ updating vps$each cron..."
  vzctl exec $each "crontab -l | sed \"s/.*\ \/usr\/local\/cpanel\/scripts\/cpbackup/0 ${hour} \* \* \* \/usr\/local\/cpanel\/scripts\/cpbackup/g\" | crontab - "
  vzctl exec $each "crontab -l | grep cpbackup"
  echo
  ((hour++))
fi

 done

##Stagger cPanel backups
#10 23 * * * /root/cpbackup_cron_adj.sh > /dev/null 2>&1

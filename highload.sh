#/bin/bash
#
# Reboot VPSs with high load 
# v.01 Ray@ebh June 18,2013
#

#### User Variables ####
# Max one minute load:
max1=7

# Max five minute load:
max5=6

# Penalty time (time in second before CT will be eligible to restart)
pentime=300

# Exclude list (single space delimitation)
# example exclude_vps="1 123 999 12345"
exclude_vps="1 998 999"

# Minimum uptime before affected by highload reboot (seconds)
safeuptime=120

mailto="alerts@eboundhost.com"
tmpfile="/tmp/rayhighload.tmp"
logfile="/var/log/vzhighload.log"
lockfile="/tmp/rayhighload.lock"
thisscript=${0}
#ShowTopProcess="/bin/ps axo pcpu,size,user,start_time,cmd | sort -r| sed 's/ SZ/MEM/'"


#### Functions
function SuspendOffender {
#RETURN if VPS is in exclude list (match ^ctid, " ctid ", or ctid$)
echo $exclude_vps | egrep -q "^$1\ |\ $1\ |\ $1$" && return

#RETURN if lock file exists (migrating/backup)
if [[ -f /vz/lock/${1}.lck ]]; then echo "Lock file detected, CT stop aborted"; cat /vz/lock/${1}.lck; return; fi

#RETURN if uptime too low
if [[ `/usr/sbin/vzctl exec $1 'cat /proc/uptime | cut -d. -f1'` -lt $safeuptime ]]; then echo "uptime is too low to reboot"; return; fi

# delete previous alert email/$tmpfile
rm -f $tmpfile

#log high load offender ctid and top processes to central log
cur_date=`date`
cur_epoch=`date +%s`
echo "$1 $cur_epoch $cur_date" >> $lockfile
echo -en "$cur_date CTID: $1 LOAD: $(/usr/sbin/vzlist -Ho laverage $1)\n" | tee -a $logfile | tee $tmpfile
#/usr/sbin/vzctl exec $1 "(echo -e \"$HOSTNAME $(cat /proc/vz/veinfo_redir)\n\n\n\"; $ShowTopProcess; echo END ${thisscript})" >> $tmpfile
/usr/sbin/vzctl exec $1 '(echo -e "$HOSTNAME $(cat /proc/vz/veinfo_redir)\n\n\n")'>> $tmpfile

echo "<pre>" >> $tmpfile
echo -e "\nbegin ShowTopProcess\n"  >> $tmpfile
/usr/bin/vztop -E ${1} -bic -n1  >> $tmpfile
echo -e "\nend ShowTopProcess\n"  >> $tmpfile

echo -e "\n\nEND ${thisscript})" >> $tmpfile
cat $tmpfile | mail -s "HIGHLOAD: vps ${1} restarted on $HOSTNAME per ${thisscript}" $mailto
/usr/sbin/vzctl stop $1
}

####  Main forloop to check for high load
# vzlist without header (-H) with columns ctid and load average. tr to simplify parsing. awk script to print CTIDs when load > max allowed.
for each in `/usr/sbin/vzlist -Ho ctid,laverage | tr / " " | awk -v max1=$max1 -v max5=$max5 '{if ($2>max1||$3>max5)print $1}'`
do
 SuspendOffender $each
done

[ ! -e $lockfile ] && exit 11 # exit early if no lock file exists
#### Cleanup and restart any past due stopped containers
for each in `/usr/sbin/vzlist -S -Ho ctid`
do
if (grep $each $lockfile)
 then
 echo stopped container matches entry in lock file
 # grep out only matching ctid (start of line, with space)
 lockfileoutput="`grep \"^$each \" $lockfile`"
 # get epoch suspend time from file (column 2)
 lockfileepoch=`echo $lockfileoutput| awk '{print $2}'`

 if [ `echo "$(date +%s)-$lockfileepoch"|bc` -gt $pentime ]
  then
   # high load penalty time exceeded.. lets start them back up
echo starting container now
   /usr/sbin/vzctl start $each
   # remove ctid from stopped lockfile entry
echo removing $each from $lockfile
   sed -i /^$each\ /d $lockfile
 fi
fi
done

# check if lockfile is so small (empty) to just remove it
[ `cat $lockfile| wc -c` -lt 2 ] && rm -v $lockfile 

## mytest code:
##  vzlist -Ho ctid,laverage | tr / " " | awk -v max1=$max1 -v max5=$max5 '{if ($2>max1||$3>max5)print $1" "$2" "$3" max1:"max1" max5:"max5}'
##  echo 12345 10.01 5.55 5.55 | awk -v max1=$max1 -v max5=$max5 '{if ($2>max1||$3>max5)print $1}'




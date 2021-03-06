#/bin/bash
#
# repair all containers mysql tables
#

# mysqlcheck -uroot --auto-repair --check --all-databases | grep -v OK


for each in `vzlist -Ho ctid,diskspace -s diskspace | grep " 0$"| awk '{print $1}'`
 do
 echo "+++ Requesting mysql repair on $each.."
 /usr/sbin/vzctl exec $each 'su -c "mysqlcheck -uroot --auto-repair --check --all-databases | tee -a /root/.mysql_repair.log"'
 PIDS+="$! "
 echo
done

# echo dots while these $PIDS still exist (not well tested)
echo "Tracking PIDs: $PIDS"
echo
while /bin/ps $PIDS >/dev/null 2>&1
 do 
 echo -n ".";
 sleep 1
done


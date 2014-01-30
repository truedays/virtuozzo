#/bin/bash
#
# repair all containers mysql tables
#

# mysqlcheck -uroot --auto-repair --check --all-databases | grep -v OK


for each in `vzlist -Ho ctid,diskspace -s diskspace | grep " 0$"| awk '{print $1}'`
 do
 echo "+++ Requesting mysql repair on $each.."
 /usr/sbin/vzctl exec $each 'mysqlcheck -uroot --auto-repair --check --all-databases | grep -v OK'&
 PIDS+="$! "
 echo
done

# echo dots while these $PIDS still exist (not well tested)
while /bin/ps $PIDS
 do 
 echo -n ".";
 sleep 1
done


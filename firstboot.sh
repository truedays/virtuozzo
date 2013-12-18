#!/bin/bash
#
# firstboot.sh useful when needing to continue script action(s) after
#  a reboot (or two)
#
# 07/28/2013 v.01 Ray@eBh
#

lockfile=/root/.firstboot.lck
initer=/etc/rc.local
logfile=/root/firstboot.sh.log

## Steps separated by BASH functions for easier reading

# First boot
firstboot () {
exec >> $logfile 2>&1
echo -e "\n\n ---\n $FUNCNAME\n ---\n\n"

# Create /vz partition
parted /dev/sdb mklabel GPT y
parted /dev/sdb unit MB mkpart primary ext4 1 100%
mkfs -t ext4 /dev/sdb1
tune2fs -i0 -c0 /dev/sdb1
mkdir /vz
echo -e "UUID=`ls -l /dev/disk/by-uuid/ | grep sdb1 | awk '{print $9}'` /vz\t\t\t  ext4\t  defaults\t  0 0" >> /etc/fstab
mount /vz

# Install Virtuozzo  ~4-5 minutes
cd /root
wget http://download.parallels.com/pvc/47/lin/vzinstall-linux-x86_64.bin
chmod 700 vzinstall-linux-x86_64.bin
#./vzinstall-linux-x86_64.bin install --templates='full' --vzinstall-opts "--pva-agent --skip-reboot"
./vzinstall-linux-x86_64.bin install --templates='full' --vzinstall-opts "--skip-reboot"
reboot

}

# Second
secondboot () {
exec >> $logfile 2>&1
echo -e "\n\n ---\n $FUNCNAME\n ---\n\n"

# Install PVA ~1 minute (expects VZ to be running)
cd /root
wget http://download.pa.parallels.com/pva/pva-setup-deploy.x86_64
chmod +x pva-setup-deploy.x86_64
mkdir pva-setup
./pva-setup-deploy.x86_64 -d pva-setup/ --extract
cd pva-setup
yum remove samba-winbind-clients -y
./pva-setup --install

# Add Tun support
if /bin/egrep -q " 6\.[0-9]" /etc/redhat-release  # if release matches 6.x
 then # Add TUN support for Centos 6
cat << EOF > /etc/sysconfig/modules/vztun.modules
#!/bin/sh
/sbin/modprobe tun
EOF
chmod +x /etc/sysconfig/modules/vztun.modules

 else # Add TUN support for Centos 4/5
cat << EOF > /etc/init.d/addtun
#!/bin/bash
/sbin/modprobe tun
EOF
chmod +x /etc/init.d/addtun
ln -s /etc/init.d/addtun /etc/rc3.d/S10addtun
fi

# Add full CSF support
cp -v /etc/sysconfig/vz{,_ORIG}
sed -i 's/IPTABLES=.*"/IPTABLES="ipt_REJECT ipt_tos ipt_TOS ipt_limit ip_conntrack ip_conntrack_ftp ip_conntrack_netbios_ns ip_conntrack_pptp ip_nat_ftp ip_nat_pptp iptable_filter iptable_mangle iptable_nat ip_tables ipt_conntrack ipt_length ipt_LOG ipt_multiport ipt_owner ipt_recent ipt_state ipt_TCPMSS ipt_tcpmss ipt_ttl xt_connlimit ipt_REDIRECT"/' /etc/sysconfig/vz
cp -v /etc/sysconfig/iptables-config{,_ORIG}
sed -i 's/IPTABLES_MODULES=".*/IPTABLES_MODULES="ip_conntrack_netbios_ns"/' /etc/sysconfig/iptables-config

#disable Customers Experience Program
sed -i 's/CEP=yes/CEP=no/' /etc/vz/vz.conf

# Update everything
yum update -y

# get custom scripts
cd /root
mv /root/virtuozzo{,_safe} -v
git clone https://github.com/truedays/virtuozzo.git
# chmod +x all bash script
grep "bin/bash" /root/virtuozzo/* -l | xargs chmod -c +x

cd /root/virtuozzo/lsi
wget http://bare.i2host.net/lsi/raidstatus.tgz
tar zxf raidstatus.tgz
mv opt/MegaRAID/MegaCli/ldanalysis.awk /opt/MegaRAID/MegaCli/ldanalysis.awk
mv opt/MegaRAID/MegaCli/pdanalysis.awk /opt/MegaRAID/MegaCli/pdanalysis.awk
mv usr/local/sbin/raidstatus /usr/local/sbin/raidstatus
chmod +x /usr/local/sbin/raidstatus

chmod +x /root/virtuozzo/lsi/raidstatus /root/virtuozzo/rayfixslm /root/virtuozzo/highload.sh /root/virtuozzo/vzw /root/virtuozzo/mountedchk.sh

cat << EOF >> /var/spool/cron/root
15      */6     *       *       *       /usr/local/sbin/raidstatus > /dev/null 2>&1
*/15    *       *       *       *       /root/virtuozzo/lsi/raidstatus > /dev/null 2>&1
*/5     *       *       *       *       /root/virtuozzo/highload.sh
# ray's vz license warning email 30 minutes before midnight 12/06/2012
30      23      *       *       *       vzlicview|egrep -q "No licenses installed|ACTIVE" || vzlicview | mail -s "$HOSTNAME VZ license status warning (not ACTIVE)" support@eboundhost.com
#reset priority of all tar/gzip/rsync
*/5     *       *       *       *       /bin/ps aux | /bin/grep -v rsync.backup| /bin/grep -E "rsync|tar|gzip|updatedb|cpbackup|scheduled_backup" | /bin/grep -v -E "start|grep" | /bin/awk -F: '{print $1}' | /bin/sed 's/^[a-z0-9]* *//; s/ [0-9].*$//;' | /usr/bin/xargs -IZ /usr/bin/ionice -c2 -n6 -pZ > /dev/null 2>&1
#New overloaders get restarted -kmh18JUL2012
*/5     *       *       *       *       for i in `/usr/sbin/vzlist -o veid -H|grep -v -E "999|102"`; do LOAD=`/usr/sbin/vzctl exec $i /usr/bin/uptime | sed 's/^.*average: //; s/,.*//; s/\.[0-9]\{2\}$//;'`;if [ $LOAD -gt 10 ]; then TOPPROCS=`/usr/sbin/vzctl exec $i "export COLUMNS=300;/usr/bin/top -bcMn 1 | sed -e 's/ *$//g'"`;/usr/sbin/vzctl stop $i;sleep 300;/usr/sbin/vzctl start $i; echo -e "VE: $i LOAD: $LOAD\n\n$TOPPROCS" | /bin/mail -s"`hostname -a` restarted: $i" level2@eboundhost.com alerts@eboundhost.com ; fi; unset LOAD;unset TOPPROCS;done > /dev/null 2>&1
#Stagger cPanel backups
10      23      *       *       *       /root/cpbackup_cron_adj.sh > /dev/null 2>&1
*/21    *       *       *       *       /root/virtuozzo/mountedchk.sh
EOF

# Undo VZ install's motd update
mv -v /etc/motd{,.vz}
cp -v /etc/motd.orig /etc/motd
## update /etc/issue
# add BIG banner for ipmi thumbnail
lynx --dump http://bare.i2host.net/cgi-bin/raysay?$(hostname -s) >> /etc/issue
sed -i 's/\\/\\\\/g' /etc/issue
# Added VZ release info to /etc/issue (assumes "Final)" in /etc/redhat-release)
sed -i "s/^Kernel.*/`cat /etc/virtuozzo-release`\nKernel/" /etc/issue
sed -i 's/Kernel.*/Kernel \\r/' /etc/issue
# prevent console screen blanking
echo -ne "\033[9;0]" >> /etc/issue

reboot

}

# Third
thirdboot () {
exec >> $logfile 2>&1
echo -e "\n\n ---\n $FUNCNAME\n ---\n\n"

# report any subsequent reboots
echo '(uptime; echo; last -ai|head) | mail -s "$(hostname -s) Rebooted" level2@eboundhost.com' >> /etc/rc.local

# updatedb before removing it from cron.daily
echo "Updating mlocate database and disabling daily cron update"
nodevs=$(< /proc/filesystems awk '$1 == "nodev" { print $2 }')
/usr/bin/updatedb -f "$nodevs"
rm -vf /etc/cron.daily/mlocate.cron

}

### Begin code


if [ -f $lockfile ]
 then
echo "$lockfile file detected continueing to step $(cat $lockfile)"
 else
echo "no $lockfile detected"
echo 1 > $lockfile
firstboot
exit
 fi

case "`cat $lockfile`" in

1) 
   echo 2 > $lockfile
   secondboot
;;
2) 
   echo 3 > $lockfile
   thirdboot
;;
3) # clean up
   echo "Virtuozzo installed."
   echo 4 > $lockfile
   #sed -i 's/.*firstboot.sh.*/#firstboot.sh # disabled automagically/g' $initer
   ## rc.local seems to have been copied to other runlevels investigate this..
   ## Fix: Comment out *all* occurrences of firstboot.sh in /etc/rc*
   for each in `grep -Rl firstboot.sh /etc/*`; do sed -i 's/.*firstboot.sh.*/#firstboot.sh # disabled automagically/g' $each ; done
;;
4) # prevent manual attempts of running this script
   echo "Virtuozzo already installed.  $0 can safely be deleted"
   rm -iv $0
   rm -iv $lockfile
   exit
;;
esac

# reboot put in explicity wihtin functions
#(echo "rebooting in 10 seconds. Hit ctrl-c to abort"; sleep 11 && reboot)

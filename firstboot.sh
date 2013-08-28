#!/bin/bash
#
# firstboot.sh useful when needing to continue script action(s) after
#  a reboot (or two)
#
# 07/28/2013 v.01 Ray@eBh
#

lockfile=/root/.firstboot.lck
initer=/tmp/rc.local


## Steps separated by BASH functions for easier reading

# First boot
firstboot () {

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

}

# Second
secondboot () {

# Install PVA ~1 minute (expects VZ to be running)
cd /root
wget http://download.pa.parallels.com/pva/pva-setup-deploy.x86_64
chmod +x pva-setup-deploy.x86_64
mkdir pva-setup
./pva-setup-deploy.x86_64 -d pva-setup/ --extract
cd pva-setup
yum remove samba-winbind-clients -y
./pva-setup --install

}

# Third
thirdboot () {

# Add Tun support
cat << EOF > /etc/init.d/addtun
#!/bin/bash
/sbin/modprobe tun
EOF
ln -s /etc/init.d/addtun /etc/rc3.d/S10addtun

# Add full CSF support
cp -v /etc/sysconfig/vz{,_ORIG}
sed -i 's/IPTABLES=.*"/IPTABLES="ipt_REJECT ipt_tos ipt_TOS ipt_limit ip_conntrack ip_conntrack_ftp ip_conntrack_netbios_ns ip_conntrack_pptp ip_nat_ftp ip_nat_pptp iptable_filter iptable_mangle iptable_nat ip_tables ipt_conntrack ipt_length ipt_LOG ipt_multiport ipt_owner ipt_recent ipt_state ipt_TCPMSS ipt_tcpmss ipt_ttl xt_connlimit ipt_REDIRECT"/' /etc/sysconfig/vz

cp -v /etc/sysconfig/iptables-config{,_ORIG}
sed -i 's/IPTABLES_MODULES=".*/IPTABLES_MODULES="ip_conntrack_netbios_ns"/' /etc/sysconfig/iptables-config

#disable Customers Experience Program
sed -i 's/CEP=yes/CEP=no/' /etc/vz/vz.conf

yum update -y

}

### Begin code


if [ -f $lockfile ]
 then
echo "$lockfile file detected continueing to step $(cat $lockfile)"
 else
echo "no $lockfile detected"
firstboot
echo 1 > $lockfile
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
   sed -i 's/.*firstboot.sh.*/#firstboot.sh # disabled automagically/g' $initer
;;
4) # prevent manual attempts of running this script
   echo "Virtuozzo already installed.  $0 can safely be deleted"
   rm -iv $0
   rm -iv $lockfile
   exit
;;
esac

(echo "rebooting in 10 seconds. Hit ctrl-c to abort"; sleep 11 && reboot)

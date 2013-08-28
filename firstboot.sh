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


}

# Second
secondboot () {


}

# Third
thirdboot () {


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

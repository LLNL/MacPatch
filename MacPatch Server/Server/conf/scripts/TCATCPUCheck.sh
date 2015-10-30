#!/bin/bash

if [ "`whoami`" != "root" ] ; then   # If not root user,
   # Run this script again as root
   echo
   echo "You must be an admin user to run this script."
   echo "Please re-run the script using sudo."
   echo
   exit 1;
fi

XOSTYPE=`uname -s`
USELINUX=false
USEMACOS=false
NEEDSRESTART=false
CPUMAX=350
SAMPLES=15
HIMARKS=0
MAXHIMARKS=10

# Check and set os type
if [ $XOSTYPE == "Linux" ]; then
    USELINUX=true
elif [ $XOSTYPE == "Darwin" ]; then
    USEMACOS=true
else
    echo "OS Type $XOSTYPE is not supported. Now exiting."
    exit 1; 
fi

# Get Tomcat PID
TCATPID=`ps -aef | grep java | grep tomcat-mpws | awk '{print $2}'`
if [ -z $TCATPID ]; then
    echo "No PID found for MacP{atch tomcat process"
    exit 1;
fi

# Get a sample of high CPU for 15 min, every 60 seconds
COUNTER=0
while [  $COUNTER -lt $SAMPLES ]; do
    # Get CPU %, then strip the floating point
    TCATCPU=`ps -p $TCATPID -o %cpu | sed -n 2p`
    TCCPU=`echo "$TCATCPU/1" | bc`
    if (( $TCCPU >= $CPUMAX )); then
        let HIMARKS=HIMARKS+1 
    fi
    
    sleep 60

    let COUNTER=COUNTER+1 
done


if (( $HIMARKS >= $MAXHIMARKS )); then
    echo "Needs to be rebooted, CPU $TCATCPU%"
    if $USEMACOS; then
        TCATPLIST="gov.llnl.mp.wsl.plist"
        launchctl unload /Library/LaunchDaemons/$TCATPLIST
        
        while ps -p $TCATPID &>/dev/null; do sleep 1; done

        launchctl load /Library/LaunchDaemons/$TCATPLIST
        # Let the new java process start up, since the CPU is high to start
        sleep 5
    fi
    if $USELINUX; then
        /etc/init.d/MPApache stop
        kill -9 $TCATPID

        while ps -p $TCATPID &>/dev/null; do sleep 1; done

        /etc/init.d/MPTomcatWS start
        sleep 5
        /etc/init.d/MPApache start
        sleep 5
    fi

    echo "`date` CPU at $TCATCPU, Tomcat restarted on $HOSTNAME." | /usr/bin/mail -s "Tomcat restarted on $HOSTNAME" escobar6@llnl.gov heizer1@llnl.gov

    # Get the new CPU value        
    TCATPID=`ps -aef | grep java | grep tomcat-mpws | awk '{print $2}'`
    TCATCPU=`ps -p $TCATPID -o %cpu | sed -n 2p`
    echo "$TCATPLIST restarted, CPU is now $TCATCPU"
else
    echo "Tomcat cpu($TCATCPU) is not at threshold for a process restart."
fi
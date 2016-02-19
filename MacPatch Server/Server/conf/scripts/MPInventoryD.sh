#!/bin/bash
#
# MPInventoryD Startup and shutdown script
#

RETVAL=$?
INV_HOME="/Library/MacPatch/Server/conf/scripts"

case "$1" in
 start)
	if [ -f $INV_HOME/MPInventoryD.py ]; then
	    echo $"Starting MacPatch Inventory"
		$INV_HOME/MPInventoryD.py --siteJSON /Library/MacPatch/Server/conf/etc/siteconfig.json --files /Library/MacPatch/Server/apache-tomcat/InvData/Files/ &
    fi
	;;
 stop)
	if [ -f $INV_HOME/MPInventoryD.py ]; then
		echo $"Stopping MacPatch Inventory"
		mpPID=`ps -ef | grep MPInventoryD.py | grep -v grep | awk '{ print $2 }'`
		kill -9 $mpPID
    fi
 	;;
 *)
 	echo $"Usage: $0 {start|stop}"
	exit 1
	;;
esac

exit $RETVAL

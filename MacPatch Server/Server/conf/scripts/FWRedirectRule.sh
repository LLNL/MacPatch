#!/bin/bash
#
# -------------------------------------------------------------
# Script: FWRedirectRule.sh
# Version: 1.0.0
#
# Description: Add PF port redirect rules for MacPatch tomcat
#              server.
#              80 -> 8080, 443 -> 8443
#
# History:
#
# -------------------------------------------------------------

if [ "`whoami`" != "root" ] ; then   # If not root user,
   # Run this script again as root
   echo
   echo "You must be an admin user to run this script."
   echo "Please re-run the script using sudo."
   echo
   exit 1;
fi

XOSTYPE=`uname -s`
if [ $XOSTYPE != "Darwin" ]; then
    echo
    echo "This script is for Mac OS X only."
    echo "Adding port forwarding rules for other hosts is not"
    echo "supported yet."
    echo
    exit 1;
fi

MP_BASE="/Library/MacPatch"
MP_SRV_BASE="/Library/MacPatch/Server"
MP_SRV_CONF="${MP_SRV_BASE}/conf"
REPLACE=false
PFHASH_DEFAULT="f70d68d8dd964656b0f6aaabcebc9212"
PFHASH_MP="ef69fccd9ca9cf0b93781a9d1379f00b"
PFHASH_SYSTEM=`md5 /private/etc/pf.conf | awk -F= '{ print $2}' | xargs`
PFConf="${MP_SRV_CONF}/fw/osx/pf/pf.conf"
PFAnchor="${MP_SRV_CONF}/fw/osx/pf/gov.llnl.mp.anchor"

if [ "$PFHASH_MP" -eq "$PFHASH_SYSTEM" ]; then
    echo 
    echo "This host appreas to have port redirect already set"
    echo "for MacPatch."
    echo "If you feel this is in error, please review the pf.conf"
    echo "file in /private/etc"
    echo
    exit 0;
else
    if [ "$PFHASH_DEFAULT" -eq "$PFHASH_SYSTEM" ]; then
        REPLACE=true
    else
        echo
        echo "The pf.conf on this file system has been modified."
        echo "It is recommended that you review the file before overwiting it."
        echo
        read -p "Overwrite pf.conf [N]: " PFOVERWRT
        PFOVERWRT=${PFOVERWRT:-n}
        if [ "$PFOVERWRT" == "y" ] || [ "$PFOVERWRT" == "Y" ]; then
            REPLACE=true
            echo
            echo "Overwriting pf.conf ..."
            echo
        else
            echo
            echo "The following text need to be added to the /private/etc/pf.comf file"
            echo 
            echo "After the line 'rdr-anchor \"com.apple/*\"'"
            echo "add"
            echo "load anchor \"forwarding\" from \"/etc/pf.anchors/gov.llnl.mp\""
            echo "rdr-anchor \"forwarding\""
            echo 
            echo "Now copy the anchors file"
            echo
            echo "cp $PFAnchor /private/etc/pf.anchors/gov.llnl.mp"
            echo
            exit 0;
        fi
    fi

    # Replace the current pf.conf
    if $REPLACE; then
        cp "$PFConf" /private/etc/pf.conf
        cp "$PFAnchor" /private/etc/pf.anchors/gov.llnl.mp
        # Load New Rules
        pfctl -ef /private/etc/pf.conf
    fi
fi

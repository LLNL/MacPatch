#!/bin/bash

# Flush existing rules
/sbin/ipfw -q flush
# Run IPFW and load custom rules
/sbin/ipfw -q /Library/MacPatch/Server/conf/etc/fw/ipfw.conf
# Enable detailed logging to syslog
# /usr/sbin/sysctl -w net.inet.ip.fw.verbose=1
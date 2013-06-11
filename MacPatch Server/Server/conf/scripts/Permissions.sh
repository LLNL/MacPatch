#!/bin/bash

#
# Set permissions
#

chown -R root:admin /Library/MacPatch/Server
chown -R 79:70 /Library/MacPatch/Server/jetty-mpwsl
chown -R 79:70 /Library/MacPatch/Server/jetty-mpsite
chown -R 79:70 /Library/MacPatch/Server/Logs
chown -R 79:70 /Library/MacPatch/Content/Web
chmod 0775 /Library/MacPatch/Server
chmod -R 0775 /Library/MacPatch/Content/Web

chown root:wheel /Library/MacPatch/Server/conf/LaunchDaemons/*
chmod 644 /Library/MacPatch/Server/conf/LaunchDaemons/*
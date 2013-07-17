#!/bin/bash

#
# Set/Fix permissions
#

# Add _appserver to _www group and vice versa
dseditgroup -o edit -a _appserver -t user _www
dseditgroup -o edit -a _www -t user _appserverusr

chown -R root:admin /Library/MacPatch/Server
chown -R 79:70 /Library/MacPatch/Server/jetty-mpwsl
chown -R 79:70 /Library/MacPatch/Server/jetty-mpsite
chown -R 79:70 /Library/MacPatch/Server/Logs
chown -R 79:70 /Library/MacPatch/Content/Web
chmod 0775 /Library/MacPatch/Server
chmod 0775 /Library/MacPatch/Server/Logs
chmod -R 0775 /Library/MacPatch/Content/Web

chown root:wheel /Library/MacPatch/Server/conf/LaunchDaemons/*
chmod 644 /Library/MacPatch/Server/conf/LaunchDaemons/*
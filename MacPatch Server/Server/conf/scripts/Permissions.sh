#!/bin/bash

#
# Set/Fix permissions
#

# Add _appserver to _www group and vice versa
dseditgroup -o edit -a _appserver -t user _www
dseditgroup -o edit -a _www -t user _appserverusr

chown -R root:admin /Library/MacPatch/Server
if [ -d /Library/MacPatch/Server/jetty-mpwsl ]; then
	chown -R 79:70 /Library/MacPatch/Server/jetty-mpwsl
fi
if [ -d /Library/MacPatch/Server/jetty-mpwsl ]; then
	chown -R 79:70 /Library/MacPatch/Server/jetty-mpsite
fi
if [ -d /Library/MacPatch/Server/tomcat-mpsite ]; then
	chown -R 79:70 /Library/MacPatch/Server/tomcat-mpsite
fi
if [ -d /Library/MacPatch/Server/tomcat-mpws ]; then
	chown -R 79:70 /Library/MacPatch/Server/tomcat-mpws
fi

chown -R 79:70 /Library/MacPatch/Server
chown -R 79:70 /Library/MacPatch/Content
chmod 0775 /Library/MacPatch/Server
chmod 0775 /Library/MacPatch/Server/Logs
chmod -R 0775 /Library/MacPatch/Content/Web

chown root:wheel /Library/MacPatch/Server/conf/LaunchDaemons/*
chmod 644 /Library/MacPatch/Server/conf/LaunchDaemons/*
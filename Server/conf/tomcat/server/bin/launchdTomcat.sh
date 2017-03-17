#!/bin/bash
 
# NOTE: this is an OSX launchd wrapper shell script for Tomcat (to be placed in $CATALINA_HOME/bin)
 
CATALINA_HOME=/opt/MacPatch/Server/apache-tomcat
 
function shutdown() {
    date
    echo "Shutting down Tomcat"
    $CATALINA_HOME/bin/catalina.sh stop
}
 
date
echo "Starting Tomcat"
export CATALINA_PID=/tmp/$$
 
# Uncomment to increase Tomcat's maximum heap allocation
# export JAVA_OPTS=-Xmx512M $JAVA_OPTS
 
. $CATALINA_HOME/bin/catalina.sh start
 
# Allow any signal which would kill a process to stop Tomcat
trap shutdown HUP INT QUIT ABRT KILL ALRM TERM TSTP
 
echo "Waiting for `cat $CATALINA_PID`"
wait `cat $CATALINA_PID`
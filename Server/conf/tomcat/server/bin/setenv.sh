#!/bin/sh

export CATALINA_OPTS="$CATALINA_OPTS -server -d64 -Djava.awt.headless=true"
export CATALINA_OPTS="$CATALINA_OPTS -Xms1g"
export CATALINA_OPTS="$CATALINA_OPTS -Xmx1g"
export CATALINA_OPTS="$CATALINA_OPTS -XX:PermSize=128m"
export CATALINA_OPTS="$CATALINA_OPTS -XX:MaxPermSize=256m"
export CATALINA_OPTS="$CATALINA_OPTS -XX:NewSize=128m"
export CATALINA_OPTS="$CATALINA_OPTS -XX:MaxNewSize=256m"
export CATALINA_OPTS="$CATALINA_OPTS -XX:+UseParallelGC"
export CATALINA_OPTS="$CATALINA_OPTS -Djavax.net.ssl.trustStore=/opt/MacPatch/Server/etc/jsseCerts/jssecacerts"
export JAVA_OPTS="$JAVA_OPTS -Djavax.net.ssl.trustStore=/opt/MacPatch/Server/etc/jsseCerts/jssecacerts"	
 
echo "Using CATALINA_OPTS:"
for arg in $CATALINA_OPTS
do
    echo ">> " $arg
done
echo ""
 
echo "Using JAVA_OPTS:"
for arg in $JAVA_OPTS
do
    echo ">> " $arg
done
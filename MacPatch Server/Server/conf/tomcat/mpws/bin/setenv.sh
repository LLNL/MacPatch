#!/bin/sh
 
export JAVA_OPTS="$JAVA_OPTS -Djavax.net.ssl.trustStore=/Library/MacPatch/Server/conf/jsseCerts/jssecacerts"

export CATALINA_OPTS="$CATALINA_OPTS -server -d64 -Djava.awt.headless=true"
export CATALINA_OPTS="$CATALINA_OPTS -Dsun.io.useCanonCaches=false"
export CATALINA_OPTS="$CATALINA_OPTS -Xms4096m"
export CATALINA_OPTS="$CATALINA_OPTS -Xmx4096m"
export CATALINA_OPTS="$CATALINA_OPTS -XX:PermSize=512M"
export CATALINA_OPTS="$CATALINA_OPTS -XX:MaxPermSize=512M"
export CATALINA_OPTS="$CATALINA_OPTS -XX:NewSize=512M"
export CATALINA_OPTS="$CATALINA_OPTS -XX:MaxNewSize=512M"
export CATALINA_OPTS="$CATALINA_OPTS -XX:GCTimeRatio=5"
export CATALINA_OPTS="$CATALINA_OPTS -XX:ThreadPriorityPolicy=42"
export CATALINA_OPTS="$CATALINA_OPTS -XX:ParallelGCThreads=4"
export CATALINA_OPTS="$CATALINA_OPTS -XX:+UseParNewGC"
export CATALINA_OPTS="$CATALINA_OPTS -XX:MaxGCPauseMillis=50"
export CATALINA_OPTS="$CATALINA_OPTS -XX:+DisableExplicitGC"
export CATALINA_OPTS="$CATALINA_OPTS -XX:MaxHeapFreeRatio=70"
export CATALINA_OPTS="$CATALINA_OPTS -XX:MinHeapFreeRatio=40"
export CATALINA_OPTS="$CATALINA_OPTS -XX:+UseStringCache"
export CATALINA_OPTS="$CATALINA_OPTS -XX:+OptimizeStringConcat"
export CATALINA_OPTS="$CATALINA_OPTS -XX:+UseTLAB"
export CATALINA_OPTS="$CATALINA_OPTS -XX:+ScavengeBeforeFullGC"
export CATALINA_OPTS="$CATALINA_OPTS -XX:CompileThreshold=1500"
export CATALINA_OPTS="$CATALINA_OPTS -XX:+TieredCompilation"
export CATALINA_OPTS="$CATALINA_OPTS -XX:+UseBiasedLocking"
export CATALINA_OPTS="$CATALINA_OPTS -Xverify:none"
export CATALINA_OPTS="$CATALINA_OPTS -XX:+UseThreadPriorities"
export CATALINA_OPTS="$CATALINA_OPTS -XX:+UseFastAccessorMethods"
export CATALINA_OPTS="$CATALINA_OPTS -XX:+UseCompressedOops"
export CATALINA_OPTS="$CATALINA_OPTS -Djavax.net.ssl.trustStore=/Library/MacPatch/Server/conf/jsseCerts/jssecacerts"

 
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
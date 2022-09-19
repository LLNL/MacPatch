#!/bin/bash

sStart="no"
sStop="no"
sRestart="no"
sPID="no"
PIDFile="/tmp/mp_api.pid"

function _usage() 
{
###### U S A G E : Help and ERROR ######
cat <<EOF
$*
Usage: console.sh <[options]>
Options:
        -s   --start          Start API Server
        -z   --stop           Stop API Server
        -r   --restart        Restart API Server
        -p   --getPID         Get Server PID
        -h   --help           Show this message
EOF
}

while getopts ':szrph' OPTION ; do
  case "$OPTION" in
    s  ) sStart=yes                     ;;
    z  ) sStop=yes                      ;;
    r  ) sRestart=yes                   ;;
    p  ) sPID=yes                       ;;
    h  ) _usage                         ;;   
    -  ) [ $OPTIND -ge 1 ] && optind=$(expr $OPTIND - 1 ) || optind=$OPTIND
         eval OPTION="\$$optind"
         OPTARG=$(echo $OPTION | cut -d'=' -f2)
         OPTION=$(echo $OPTION | cut -d'=' -f1)
         case $OPTION in
             --start     ) sStart=yes                     ;;
             --stop      ) sStop=yes                      ;;
             --restart   ) sRestart=yes                   ;;
             --getPID    ) sPID=yes                       ;;
             --help      ) _usage                         ;; 
             * )  _usage "Invalid option $OPTION " ;;
         esac
       OPTIND=1
       shift
      ;;
    ? )  _usage "Invalid option $OPTION "  ;;
  esac
done

function startServer() 
{
    source /opt/MacPatch/Server/env/api/bin/activate

    if [ ! -d "/opt/MacPatch/Server/logs" ]; then
        mkdir -p /opt/MacPatch/Server/logs
    fi

    gunicorn --config /opt/MacPatch/Server/apps/api/gunicorn_api_config.py \
    --chdir /opt/MacPatch/Server/apps/api "app:create_app()" --pid $PIDFile
}

if [ $sStart == "yes" ] || [ $sRestart == "yes" ]; then
    if [ -f $PIDFile ]; then
        if [ $sRestart == "yes" ]; then
            echo "Stopping API Server"
        fi
        CurPID=$(<"$PIDFile")
        kill -9 $(<"$PIDFile")
    fi
    echo "Starting API Server"
    startServer
fi

if [ $sStop == "yes" ]; then
    echo "Stoping API Server"
    if [ -f $PIDFile ]; then
        CurPID=$(<"$PIDFile")
        kill -9 $(<"$PIDFile")
    fi
fi

if [ $sPID == "yes" ]; then
    CurPID=$(<"$PIDFile")
    echo "Current Server PID $CurPID"
fi

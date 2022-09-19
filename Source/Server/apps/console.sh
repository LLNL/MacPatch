#!/bin/bash

sStart="no"
sStop="no"
sRestart="no"
sPID="no"
PIDFile="/tmp/mp_console.pid"

function _usage() 
{
###### U S A G E : Help and ERROR ######
cat <<EOF
$*
Usage: console.sh <[options]>
Options:
        -s   --start          Start console
        -z   --stop           Stop console
        -r   --restart        Restart console
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
    source /opt/MacPatch/Server/env/console/bin/activate

    if [ ! -d "/opt/MacPatch/Server/logs" ]; then
        mkdir -p /opt/MacPatch/Server/logs
    fi

    gunicorn --config /opt/MacPatch/Server/apps/console/gunicorn_console_config.py \
    --chdir /opt/MacPatch/Server/apps/console "app:create_app()" --pid $PIDFile
}

if [ $sStart == "yes" ] || [ $sRestart == "yes" ]; then
    if [ -f $PIDFile ]; then
        if [ $sRestart == "yes" ]; then
            echo "Stopping Server"
        fi
        CurPID=$(<"$PIDFile")
        kill -9 $(<"$PIDFile")
    fi
    echo "Starting Server"
    startServer
fi

if [ $sStop == "yes" ]; then
    echo "Stoping Server"
    if [ -f $PIDFile ]; then
        CurPID=$(<"$PIDFile")
        kill -9 $(<"$PIDFile")
    fi
fi

if [ $sPID == "yes" ]; then
    CurPID=$(<"$PIDFile")
    echo "Current Server PID $CurPID"
fi
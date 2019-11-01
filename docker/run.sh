#!/bin/bash

cd "$MPSERVERBASE"/apps || exit 1

while ! ("$MPSERVERBASE"/env/api/bin/python "$MPSERVERBASE"/apps/mpapi.py db upgrade head); do
  echo "The database doesn't appear to be up yet, giving it a few more seconds."
  sleep 15
done


if [ "$1" == "api" ]; then
  sed -i "s/host='127.0.0.1'/host='0.0.0.0'/" /opt/MacPatch/Server/apps/mpapi.py
  "$MPSERVERBASE"/env/api/bin/python "$MPSERVERBASE"/apps/mpapi.py gunicorn
elif [ "$1" == "console" ]; then
  sed -i "s/host='127.0.0.1'/host='0.0.0.0'/" /opt/MacPatch/Server/apps/mpconsole.py
  "$MPSERVERBASE"/env/console/bin/python "$MPSERVERBASE"/apps/mpconsole.py gunicorn
else
  supervisord --nodaemon -c "$MPSERVERBASE"/supervisord/supervisord.conf
fi

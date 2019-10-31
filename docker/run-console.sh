#!/bin/bash

cd $MPSERVERBASE/apps
while ! ("$MPSERVERBASE"/env/api/bin/python "$MPSERVERBASE"/apps/mpapi.py db upgrade head); do
  echo "The database doesn't appear to be up yet, giving it a few more seconds."
  sleep 15
done
"$MPSERVERBASE"/env/api/bin/python "$MPSERVERBASE"/apps/mpapi.py populate_db

sed -i "s/host='127.0.0.1'/host='0.0.0.0'/" /opt/MacPatch/Server/apps/mpconsole.py
"$MPSERVERBASE"/env/console/bin/python "$MPSERVERBASE"/apps/mpconsole.py gunicorn

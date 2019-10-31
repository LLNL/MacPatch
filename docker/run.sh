#!/bin/bash

source $MPSERVERBASE/env/api/bin/activate

cd $MPSERVERBASE/apps
while ! (./mpapi.py db upgrade head); do
  echo "The database doesn't appear to be up yet, giving it a few more seconds."
  sleep 15
done
./mpapi.py populate_db

deactivate

supervisord --nodaemon -c $MPSERVERBASE/supervisord/supervisord.conf

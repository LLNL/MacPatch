#!/bin/bash

  cd $MPSERVERBASE/apps
  source env/api/bin/activate

  while ! (./mpapi.py db upgrade head); do
    echo "The database doesn't appear to be up yet, giving it a few more seconds."
    sleep 15
  done
  # ./mpapi.py db upgrade head
  ./mpapi.py populate_db

  deactivate

supervisord --nodaemon -c $MPSERVERBASE/supervisord/supervisord.conf

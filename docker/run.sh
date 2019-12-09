#!/bin/bash

cd "$MPSERVERBASE/apps" || exit 1


function wait_for_db () {
  while ! ("$MPSERVERBASE/env/api/bin/python" "$MPSERVERBASE/apps/mpapi.py" db upgrade head 2> /dev/null); do
    echo "The database doesn't appear to be up yet, giving it a few more seconds."
    sleep 15
  done
  "$MPSERVERBASE/env/api/bin/python" "$MPSERVERBASE/apps/mpapi.py" populate_db
  echo "The database is up, moving on."
}


if [ "$1" == "api" ]; then
  # run only the api service
  echo "Starting MacPatch API service..."
  wait_for_db
  "$MPSERVERBASE/env/api/bin/python" "$MPSERVERBASE/apps/mpapi.py" gunicorn
elif [ "$1" == "console" ]; then
  # run only the console service
  echo "Starting MacPatch Console service..."
  wait_for_db
  "$MPSERVERBASE/env/console/bin/python" "$MPSERVERBASE/apps/mpconsole.py" gunicorn
elif [ "$1" == "inventory" ]; then
  # run only the inventory service
  echo "Starting MacPatch Inventory service..."
  "$MPSERVERBASE/conf/scripts/MPInventoryD.py" --config "$MPSERVERBASE/etc/siteconfig.json" --files "$MPSERVERBASE/InvData/files"
elif [ "$1" == "asus" ]; then
  # run only the asus sync script then exit. 
  # can be called via cron from host OS
  #   ex: 0 * * * *   docker exec macpatch_api_1 /run.sh asus
  echo "Running MacPatch ASUS sync script..."
  "$MPSERVERBASE/conf/scripts/MPSUSPatchSync.py" --config "$MPSERVERBASE/etc/patchloader.json"
else
  # run all services in one container, includs nginx but not the db
  wait_for_db
  supervisord --nodaemon -c "$MPSERVERBASE"/supervisord/supervisord.conf
fi

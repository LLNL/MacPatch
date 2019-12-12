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
  # Run the api service
  echo "Starting MacPatch API service..."
  wait_for_db
  "$MPSERVERBASE/env/api/bin/python" "$MPSERVERBASE/apps/mpapi.py" gunicorn
elif [ "$1" == "inventory" ]; then
  # Run the inventory service
  wait_for_db
  echo "Starting MacPatch Inventory service..."
  "$MPSERVERBASE/conf/scripts/MPInventoryD.py" --config "$MPSERVERBASE/etc/siteconfig.json" --files "$MPSERVERBASE/InvData/files" --echo
elif [ "$1" == "asus" ]; then
  # Run the asus sync script then exit. 
  # can be called via cron from host OS
  #   ex: 0 * * * *   docker exec macpatch_api_1 /run.sh asus
  echo "Running MacPatch ASUS sync script..."
  "$MPSERVERBASE/conf/scripts/MPSUSPatchSync.py" --config "$MPSERVERBASE/etc/patchloader.json"
else
  # Run the console service
  echo "Starting MacPatch Console service..."
  wait_for_db
  "$MPSERVERBASE/env/console/bin/python" "$MPSERVERBASE/apps/mpconsole.py" gunicorn
fi

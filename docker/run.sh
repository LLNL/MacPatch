#!/bin/bash

cd "$MPSERVERBASE/apps" || exit 1

while ! ("$MPSERVERBASE/env/api/bin/python" "$MPSERVERBASE/apps/mpapi.py" db upgrade head); do
  echo "The database doesn't appear to be up yet, giving it a few more seconds."
  sleep 15
done


if [ "$1" == "api" ]; then
  "$MPSERVERBASE/env/api/bin/python" "$MPSERVERBASE/apps/mpapi.py" gunicorn -h "0.0.0.0"
elif [ "$1" == "console" ]; then
  "$MPSERVERBASE/env/console/bin/python" "$MPSERVERBASE/apps/mpconsole.py" gunicorn -h "0.0.0.0"
elif [ "$1" == "inventory" ]; then
  "$MPSERVERBASE/conf/scripts/MPInventoryD.py" --config "$MPSERVERBASE/etc/siteconfig.json" --files "$MPSERVERBASE/InvData/files"
elif [ "$1" == "asus" ]; then
  "$MPSERVERBASE/conf/scripts/MPSUSPatchSync.py" --config "$MPSERVERBASE/etc/patchloader.json"
else
  supervisord --nodaemon -c "$MPSERVERBASE"/supervisord/supervisord.conf
fi

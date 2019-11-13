#!/bin/bash

cd "$MPSERVERBASE/apps" || exit 1

sed -i "s/host='127.0.0.1'/host='0.0.0.0'/" /opt/MacPatch/Server/apps/mpapi.py
sed -i "s/host='127.0.0.1'/host='0.0.0.0'/" /opt/MacPatch/Server/apps/mpconsole.py

  echo "The database doesn't appear to be up yet, giving it a few more seconds."
  sleep 15
done
"$MPSERVERBASE/env/api/bin/python" "$MPSERVERBASE/apps/mpapi.py" populate_db


if [ "$1" == "api" ]; then
  # run only the api service
  "$MPSERVERBASE/env/api/bin/python" "$MPSERVERBASE/apps/mpapi.py" gunicorn
elif [ "$1" == "console" ]; then
  # run only the console service
  "$MPSERVERBASE/env/console/bin/python" "$MPSERVERBASE/apps/mpconsole.py" gunicorn
elif [ "$1" == "inventory" ]; then
  # run only the inventory service
  "$MPSERVERBASE/conf/scripts/MPInventoryD.py" --config "$MPSERVERBASE/etc/siteconfig.json" --files "$MPSERVERBASE/InvData/files"
elif [ "$1" == "asus" ]; then
  # run only the asus sync service
  "$MPSERVERBASE/conf/scripts/MPSUSPatchSync.py" --config "$MPSERVERBASE/etc/patchloader.json"
else
  # run all services in one container, including nginx but not the db
  supervisord --nodaemon -c "$MPSERVERBASE"/supervisord/supervisord.conf
fi

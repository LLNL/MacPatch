#!/bin/bash
#
# -------------------------------------------------------------
# Script: InstallPyMods.sh
# Version: 1.0.0
#
# Description:
# This script will test and install any missing python modules
#
# History:
#
# -------------------------------------------------------------

if [ "`whoami`" != "root" ] ; then   # If not root user,
   # Run this script again as root
   echo
   echo "You must be an admin user to run this script."
   echo "Please re-run the script using sudo."
   echo
   exit 1;
fi

PY_MODS="/Library/MacPatch/Server/conf/src/python"
MODS=('pip-7.1.0' 'argparse-1.3.0' 'mysql-connector-python-2.0.4' 'requests-2.7.0' 'biplist-0.9' 'wheel-0.24.0');

install_module () {

    MODNAME=`echo $1 | awk -F- '{print $1}'`
    python -c "import $MODNAME" > /dev/null 2>&1
    if [ $? == 1 ]; then
        if [ -d "${PY_MODS}/$1" ]; then
            easy_install "${PY_MODS}/$1"
        fi
    else
        echo "Python Module $MODNAME is installed."
    fi
}

for mod in "${MODS[@]}"; do
    install_module $mod
done

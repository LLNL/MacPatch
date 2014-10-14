#!/bin/sh
#
# This Script Will Install All Necessary packages for MacPatch on Ubuntu
#

# APT Installs
LIST_OF_APPS="git build-essential openjdk-7-jdk zip libssl-dev libxml2-dev python-pip python-mysql.connector"

aptitude update
aptitude install -y $LIST_OF_APPS

# Python Modules
pip install plistlib
pip install biplist
pip install requests
pip install python-crontab
pip install argparse
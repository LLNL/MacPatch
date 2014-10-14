#!/bin/sh
#
# This Script Will Install All Necessary packages for MacPatch on RedHat
#

# YUM Installs
LIST_OF_APPS="gcc-c++ openssl-devel java-1.7.0-openjdk-devel libxml2-devel bzip2 bzip2-libs bzip2-devel python-pip mysql-connector-python"

yum -y install $LIST_OF_APPS

# Python Modules
pip install plistlib
pip install biplist
pip install requests
pip install python-crontab
pip install argparse
#!/bin/bash
#
# -------------------------------------------------------------
# Script: MPDBSetup.sh
# Version: 1.0.1
#
# Description:
# This script will setup and configure a MySQL server for
# MacPatch
#
# History:
# Added a continue on error, if the error is more of a warning
# then the user may continue and add the schema to the db.
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

DBNAME="MacPatchDB"
MPUSER="mpdbadm"
MPROUSR="mpdbro"
MPUSRPAS="Password"
MPUSRROPAS="Password"
HOST=`hostname`

BTICK='`'
export PATH=$PATH:/usr/local/mysql/bin
MYSQL=`which mysql`

if [ -z "$MYSQL" ] ; then
	clear
	echo
	echo "Could not find mysql. Please make sure that"
	echo "mysql is installed and in your path."
	exit 1;
fi

CHECKFORMY=`ps -aef | grep mysqld | grep -v grep | head -n1`
if [ -z "$CHECKFORMY" ] ; then
	clear
	echo
	echo "Could not find mysqld running. Please make sure that"
	echo "mysql is running before continuing."
	exit 1;
fi

clear
echo
echo "Notice:"
echo "Please remeber the following user names and passwords"
echo "They will be needed later."
echo
read -p "MacPatch User Account [mpdbadm]: " MPUSER
MPUSER=${MPUSER:-mpdbadm}
read -p "MacPatch User Account Password: " MPUSRPAS
MPUSRPAS=${MPUSRPAS:-Password}
echo
read -p "MacPatch Read Only User Account [mpdbro]: " MPROUSR
MPROUSR=${MPROUSR:-mpdbro}
read -p "MacPatch User Account Password: " MPUSRROPAS
MPUSRROPAS=${MPUSRROPAS:-Password}
echo

Q1="CREATE DATABASE IF NOT EXISTS ${BTICK}$DBNAME${BTICK};"
Q2="CREATE USER '${MPUSER}'@'%' IDENTIFIED BY '${MPUSRPAS}';"
Q3="GRANT ALL ON $DBNAME.* TO '${MPUSER}'@'%' IDENTIFIED BY '${MPUSRPAS}';"
Q4="GRANT ALL PRIVILEGES ON $DBNAME.* TO '${MPUSER}'@'localhost' IDENTIFIED BY '${MPUSRPAS}';"
Q5="CREATE USER '${MPROUSR}'@'%' IDENTIFIED BY '${MPUSRROPAS}';"
Q6="GRANT SELECT ON $DBNAME.* TO '${MPROUSR}'@'%';"
Q7="SET GLOBAL log_bin_trust_function_creators = 1;"
Q8="FLUSH PRIVILEGES;"
Q9="DROP USER ''@'localhost';"
Q10="DROP USER ''@'$HOST';"

SQL="${Q1}${Q2}${Q3}${Q4}${Q5}${Q6}${Q7}${Q8}${Q9}${Q10}"

clear
echo
echo "MySQL Database is about to be configured."
echo "You will be prompted for the MySQL root user password"
echo

$MYSQL -uroot -p -e "$SQL"
if [ $? -ne 0 ]; then
	echo
	read -p "An error was detected, would you like to continue (Y/N)? [N]: " CONTONERR
	CONTONERR=${CONTONERR:-N}
	if [ "$CONTONERR" == "N" ] || [ "$CONTONERR" == "N" ]; then
		exit 1;
	fi
fi

clear
echo
read -p "Would you like to add the tables and views to the database (Y/N)? [Y]: " ADDSCHEMA
ADDSCHEMA=${ADDSCHEMA:-Y}

if [ "$ADDSCHEMA" == "y" ] || [ "$ADDSCHEMA" == "Y" ]; then

	if [ ! -f "/Library/MacPatch/Server/conf/Database/MacPatchDB_Tables.sql" ] || [ ! -f "/Library/MacPatch/Server/conf/Database/MacPatchDB_Views.sql" ] ; then
		echo
		echo "MacPatch Schema files are missing, can not setup MacPatch schema"
		echo
		exit 1;
	fi

	echo
	echo "MacPatch Schema is about to be configured."
	echo

	$MYSQL $DBNAME -u $MPUSER --password="$MPUSRPAS" < /Library/MacPatch/Server/conf/Database/MacPatchDB_Tables.sql 2>/dev/null
	$MYSQL $DBNAME -u $MPUSER --password="$MPUSRPAS" < /Library/MacPatch/Server/conf/Database/MacPatchDB_Views.sql 2>/dev/null

	echo
	echo "MySQL & MacPatch are now configured."
	echo
	
else
	echo 
	echo "The MacPatch schema will still need to be imported."
	echo
fi



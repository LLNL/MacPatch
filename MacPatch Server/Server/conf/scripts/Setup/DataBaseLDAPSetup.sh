#!/bin/bash

#-----------------------------------------
# MacPatch DataBase and LDAP Setup Script
# MacPatch Version 2.1.x
#
# Script Ver. 1.0.0
#
#-----------------------------------------
clear

# Variables
MP_SRV_BASE="/Library/MacPatch/Server"
MP_SRV_CONF="${MP_SRV_BASE}/conf"

function checkHostConfig () {
	if [ "`whoami`" != "root" ] ; then   # If not root user,
	   # Run this script again as root
	   echo
	   echo "You must be an admin user to run this script."
	   echo "Please re-run the script using sudo."
	   echo
	   exit 1;
	fi
	
	osVer=`sw_vers -productVersion | cut -d . -f 2`
	if [ "$osVer" -le "6" ]; then
		echo "System is not running Mac OS X (Server) 10.7 or higher. Setup can not continue."
		exit 1
	fi
}


# -----------------------------------
# Main
# -----------------------------------

checkHostConfig

# -----------------------------------
# Config DB Settings
# -----------------------------------
clear
echo "Configure MacPatch Database Info..."
echo " "
read -p "MacPatch Database Server Hostname: " mp_db_hostname
read -p "MacPatch Database Server Port Number [3306]: " mp_db_port
mp_db_port=${mp_db_port:-3306}
read -p "MacPatch Database Name [MacPatchDB]: " mp_db_name
mp_db_name=${mp_db_name:-MacPatchDB}
read -p "MacPatch Database Server User Name [mpdbadm]: " mp_db_usr
mp_db_usr=${mp_db_usr:-mpdbadm}
read -s -p "MacPatch Database Server User Password: " mp_db_pas
clear
echo "Configure MacPatch Login Source..."
echo " "
read -p "Would you like to use Active Directory/LDAP for login? [Y]: " use_ldap
use_ldap=${use_ldap:-Y}
if [ "$use_ldap" == "y" ] || [ "$use_ldap" == "Y" ]; then

	read -p "Active Directory/LDAP server hostname: " ldap_hostname
	read -p "Active Directory/LDAP server port number: " ldap_port
	
	read -p "Active Directory/LDAP use ssl? [Y]: " use_ldap_ssl
	use_ldap_ssl=${use_ldap_ssl:-Y}
	if [ "$use_ldap_ssl" == "y" ] || [ "$use_ldap_ssl" == "Y" ]; then
		echo "Please note, you will need to run the \"addRemoteCert.sh\" script prior to starting the MacPatch Web Admin Console."
		ldap_ssl="CFSSL_BASIC"
	else
		ldap_ssl="NONE"
	fi
	
	read -p "Active Directory/LDAP Search Base: " ldap_searchbase
	read -p "Active Directory/LDAP Login Attribute [userPrincipalName]: " ldap_lgnattr
	ldap_lgnattr=${ldap_lgnattr:-userPrincipalName}
	read -p "Active Directory/LDAP Login User Name Prefix [None]: " ldap_lgnpre
	ldap_lgnpre=${ldap_lgnpre:-""}
	read -p "Active Directory/LDAP Login User Name Suffix [None]: " ldap_lgnsuf
	ldap_lgnsuf=${ldap_lgnsuf:-""}
fi
clear
echo ""
echo "Writing configuration data to file ..."
sed -i '' "s/\[DB-HOST\]/$mp_db_hostname/g" "${MP_SRV_BASE}/conf/etc/siteconfig.xml"
sed -i '' "s/\[DB-NAME\]/$mp_db_name/g" "${MP_SRV_BASE}/conf/etc/siteconfig.xml"
sed -i '' "s/\[DB-PORT\]/$mp_db_port/g" "${MP_SRV_BASE}/conf/etc/siteconfig.xml"
sed -i '' "s/\[DB-USER\]/$mp_db_usr/g" "${MP_SRV_BASE}/conf/etc/siteconfig.xml"
sed -i '' "s/\[DB-PASS\]/$mp_db_pas/g" "${MP_SRV_BASE}/conf/etc/siteconfig.xml"
if [ "$use_ldap" == "y" ] || [ "$use_ldap" == "Y" ]; then
	sed -i '' "s/\[AD-DOMAIN-FQDN\]/$ldap_hostname/g" "${MP_SRV_BASE}/conf/etc/siteconfig.xml"
	sed -i '' "s/\[AD-DOMAIN-PORT\]/$ldap_port/g" "${MP_SRV_BASE}/conf/etc/siteconfig.xml"
	sed -i '' "s/\[AD-SEARCH-BASE\]/$ldap_searchbase/g" "${MP_SRV_BASE}/conf/etc/siteconfig.xml"
	sed -i '' "s/\[AD-DOMAIN-SSL\]/$ldap_ssl/g" "${MP_SRV_BASE}/conf/etc/siteconfig.xml"
	sed -i '' "s/\[AD-LOGIN-ATTR\]/$ldap_lgnattr/g" "${MP_SRV_BASE}/conf/etc/siteconfig.xml"
	sed -i '' "s/\[AD-LOGIN-PRE\]/$ldap_lgnpre/g" "${MP_SRV_BASE}/conf/etc/siteconfig.xml"
	sed -i '' "s/\[AD-LOGIN-SUF\]/$ldap_lgnsuf/g" "${MP_SRV_BASE}/conf/etc/siteconfig.xml"
fi

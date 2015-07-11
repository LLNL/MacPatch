#!/bin/bash

#-----------------------------------------
# MacPatch Proxy Server Setup Script
# MacPatch Version 2.1.x
#
# Script Ver. 1.0.0
#
#-----------------------------------------
clear

# Variables
MP_SRV_BASE="/Library/MacPatch/Server"
MP_SRV_CONF="${MP_SRV_BASE}/conf"
HTTPD_CONF="${MP_SRV_BASE}/Apache2/conf/extra/httpd-vhosts.conf"
MP_DEFAULT_PORT="2601"

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
        echo "System is not running Mac OS X 10.7 or higher. Setup can not continue."
        exit 1
    fi
}

# -----------------------------------
# Main
# -----------------------------------

checkHostConfig

# -----------------------------------
# Config HTTP Services
# -----------------------------------

server_name=`hostname -f`
read -p "MacPatch Proxy Server Hostname [$server_name]: " server_name
server_name=${server_name:-`hostname -f`}
read -p "MacPatch Proxy Server Port [$MP_DEFAULT_PORT]: " server_port
server_port=${server_port:-$MP_DEFAULT_PORT}

server_route=`echo $server_name | awk -F . '{print $1}'` 
server_route="$server_route-site1"

BalancerMember_STR="BalancerMember http://$server_name:$server_port route=$server_route loadfactor=50"

echo "Writing config to httpd.conf..."
ServerHstString=`echo $BalancerMember_STR | sed 's#\/#\\\/#g'`
sed -i '' '/\t*#WslBalanceStart/,/\t*#WslBalanceStop/{;/\t*#/!s/.*/'"$ServerHstString"'/;}' "${HTTPD_CONF}"
perl -i -p -e 's/@@/\n/g' "${HTTPD_CONF}"

echo "Writing configuration data to jetty file ..."
sed -i '' "s/\[MP_PORT\]/$server_port/g" "${MP_SRV_BASE}/jetty-mpproxy/etc/jetty.xml"

if [ -f /Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mp.proxy.plist ]; then
    ln -s /Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mp.proxy.plist /Library/LaunchDaemons/gov.llnl.mp.proxy.plist
fi
chown root:wheel /Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mp.proxy.plist
chmod 644 /Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mp.proxy.plist

if [ -f /Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mp.ProxySync.plist ]; then
    ln -s /Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mp.ProxySync.plist /Library/LaunchDaemons/gov.llnl.mp.ProxySync.plist
fi
chown root:wheel /Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mp.ProxySync.plist
chmod 644 /Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mp.ProxySync.plist


# Add Certs To KeyStore
clear
echo "Get Certificate from master MacPatch Server..."
read -p "MacPatch Master Server Hostname: " mp_hostname
read -p "MacPatch Master Server Port Number [2600]: " mp_port
mp_port=${mp_port:-2600}
mp_server=$mp_hostname:$mp_port

if [ ! -d "${MP_SRV_CONF}/jsseCerts" ]; then
    mkdir -p "${MP_SRV_CONF}/jsseCerts"
fi

echo "Getting cert for $mp_hostname..."
ShortName=`echo $mp_server | awk -F . '{ print $1 }'`
echo | openssl s_client -connect "$mp_server" 2>/dev/null | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > "${MP_SRV_CONF}/jsseCerts/${ShortName}.cer"

echo "Add $ShortName.cer to keystore..."
keytool -import -file "${MP_SRV_CONF}/jsseCerts/${ShortName}.cer" -alias $ShortName -keystore "${MP_SRV_CONF}/jsseCerts/jssecacerts" -storepass changeit -trustcacerts -noprompt

#Add Master Server Key
read -p "MacPatch Proxy Server ID Key: " mp_key

clear
echo "Writing configuration data to file ..."
sed -i '' "s/\[MP_SERVER\]/$mp_hostname/g" "${MP_SRV_BASE}/conf/etc/siteconfig.xml"
sed -i '' "s/\[MP_SERVER_PORT\]/$mp_port/g" "${MP_SRV_BASE}/conf/etc/siteconfig.xml"
sed -i '' "s/\[SEED_KEY\]/$mp_key/g" "${MP_SRV_BASE}/conf/etc/siteconfig.xml"

# Write MPProxySync info to file
defaults write ${MP_SRV_CONF}/etc/gov.llnl.MPProxySync MPServerAddress $mp_hostname
defaults write ${MP_SRV_CONF}/etc/gov.llnl.MPProxySync MPServerPort $mp_port

clear
echo "MacPatch Proxy Server is now installed and mostly configured."
echo " "
echo "Please make sure the siteconfig.xml is fully configured before launching the server."
echo " "
echo "To launch the Proxy Server Service run the StartServices.sh script."
echo " "
#!/bin/sh

Version="1.1"
MP_SRV_BASE="/Library/MacPatch/Server"
MP_SRV_CONF="${MP_SRV_BASE}/conf"


#IF NO ARGUMENTS WERE PROVIDED
function USAGE ()
{
    echo ""
    echo "USAGE: "
    echo "    getRemoteCerts.sh [-?] [-c]"
    echo ""
    echo "OPTIONS:"
    echo "    -c  List Of Domain Controller(s) to get the cert from."
    echo "    -?  this usage information"
    echo ""
    echo "EXAMPLE:"
    echo "    getRemoteCerts.sh -c \"dc1.example.com:3269 dc2.example.com:3269\""
    echo ""
    exit $E_OPTERROR    # Exit and explain usage, if no argument(s) given.
}

function ADDCERT () {

	if [ -f "${MP_SRV_CONF}/jsseCerts/$1.cer" ]; then
		rm "${MP_SRV_CONF}/jsseCerts/$1.cer"
	fi
	# Download the new cert
	echo | openssl s_client -connect ${i} 2>/dev/null | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > "${MP_SRV_CONF}/jsseCerts/$1.cer"
	echo "Import $cerName to jssecacerts"
	keytool -delete -alias "$1" -keystore "${MP_SRV_CONF}/jsseCerts/jssecacerts" -storepass changeit -trustcacerts -noprompt
	keytool -import -file "${MP_SRV_CONF}/jsseCerts/$1.cer" -alias "$1" -keystore "${MP_SRV_CONF}/jsseCerts/jssecacerts" -storepass changeit -trustcacerts -noprompt

}

bflag=
cVal=
#PROCESS ARGS
while getopts ":c:?" Option
do
    case $Option in
        c    )	cflag=1
        			cVal="$OPTARG"
        			;;
        h    ) USAGE
        	   	exit 0;;
        ?    ) USAGE
               	exit 0;;
        *    ) echo ""
               echo "Unimplemented option chosen."
               USAGE   # DEFAULT
    esac
done

shift $(($OPTIND - 1))


echo "Cerificate Installer $Version"
      
if [ "`whoami`" != "root" ] ; then   # If not root user,
   # Run this script again as root
   echo
   echo "You must be an admin user to run this program."
   echo "Please re-run the script using sudo."
   echo
   exit 0;
fi

if [ "$cflag" ]; then
	if [ ! -d "#{MP_SRV_CONF}/jsseCerts" ]; then
		mkdir -p "${MP_SRV_CONF}/jsseCerts"	
	fi
	IFS=' ' read -ra ADDR <<< "$cVal"
	for i in "${ADDR[@]}"; do
		cerName=`echo ${i} | awk -F. '{print $1}'`
		ADDCERT $cerName
	done
fi

echo
echo "Certificates have been download, and a jssecacerts file has been created."
echo 
echo "****************** NOTE ******************"
echo "A reboot of the J2EE services will be requirerd for the application server to recognize the new cert(s)."
echo
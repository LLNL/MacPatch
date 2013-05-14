#!/bin/bash
#
# Used to create the master server Certificate
#

HOSTNAME=`hostname`
BASEDIR="/Library/MacPatch/Server/conf/ssl"
# Feel free to change C, ST, L
CERTSUB="/C=US/ST=California/L=Livermore/O=MacPatch/OU=Master/CN=$HOSTNAME"
NOSIGN=0

# ------------------------------------------
# usage 
# ------------------------------------------
usage()
{
	echo "Usage: `basename $0` options (-n \"No Sign\") -? for help";
}

# ------------------------------------------
# process opts
# ------------------------------------------
while getopts "n" opt; do
  case $opt in
    n)
      NOSIGN=1
      ;;
    \?)
      usage
      exit $E_OPTERROR;
      ;;
  esac
done

# ------------------------------------------
# Create Certificate Signing Request & Sign
# ------------------------------------------
if [ $NOSIGN -eq 0 ]; then
	if [ ! -d "$BASEDIR/ca/ca.key" ]; then
		echo "Must create the CA before you can create the server cert."
		echo
		echo "Please run the \"ca.sh\" script."
		echo
		exit 1
	fi
fi

if [ ! -d "$BASEDIR/server" ]; then
	mkdir -p "$BASEDIR/server"
fi

# Create a key
openssl genrsa -out $BASEDIR/server/server.key 2048

# Take our key and create a Certificate Signing Request for it.
openssl req -config $BASEDIR/openssl.cnf -new \
-subj $CERTSUB \
-key $BASEDIR/server/server.key -out $BASEDIR/server/server.csr

if [ $NOSIGN -eq 0 ]; then
	# Sign this key with the MacPatch CA key.
	openssl ca -batch -config $BASEDIR/openssl.cnf -in $BASEDIR/server/server.csr \
	-cert $BASEDIR/ca/ca.crt -keyfile $BASEDIR/ca/ca.key -out $BASEDIR/server/server.crt
else
	echo "Certificate Signing Request"
	echo
	echo
	echo `cat $BASEDIR/server/server.csr`
	echo
	echo
fi
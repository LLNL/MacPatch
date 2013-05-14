#!/bin/bash

BASEDIR="/Library/MacPatch/Server/conf/ssl"
AHOSTNAME=""
ACSRFILE=""

# ------------------------------------------
# usage 
# ------------------------------------------
usage()
{
	echo "Usage: `basename $0` options (-n \"HostName\") (-c \"CSR\") -? for help";
}

# ------------------------------------------
# validate opts
# ------------------------------------------
if ( ! getopts ":n:c:" opt); then
	usage
	exit $E_OPTERROR;
fi

# ------------------------------------------
# process opts
# ------------------------------------------
while getopts ":n:c:" opt; do
  case $opt in
    n)
      AHOSTNAME="$OPTARG"
      ;;
    c)
      ACSRFILE="$OPTARG"
      ;;    
    \?)
      usage
      exit $E_OPTERROR;
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

# ------------------------------------------
# validate required opts
# ------------------------------------------
if [[ -z $AHOSTNAME ]] || [[ -z $ACSRFILE ]]; then
     usage
     exit $E_OPTERROR;
fi

# Make sure server dir exists
if [ ! -d "$BASEDIR/server/$AHOSTNAME" ]; then
	mkdir -p "$BASEDIR/server/$AHOSTNAME
fi
              
# ------------------------------------------
# create and sign client cert
# ------------------------------------------

# Have the RootCA sign the CSR and create a signed certificate
openssl ca -batch -config $BASEDIR/openssl.cnf -extensions client_cert \
-in $ACSRFILE \
-out $BASEDIR/server/$AHOSTNAME/$ADEVCUUID.pem